require 'tsuga/model/tile'
require 'tsuga/service/aggregator'

require 'ruby-progressbar'

module Tsuga::Service
  class Clusterer
    FIRST_PASS_RATIO  = 0.05
    SECOND_PASS_RATIO = 0.2
    Tile = Tsuga::Model::Tile
    VERBOSE = ENV['VERBOSE']

    attr_reader :_adapter, :_source

    def initialize(source: nil, adapter: nil)
      @_source  = source
      @_adapter = adapter
    end

    def run
      # delete all clusters
      _adapter.delete_all

      # create lowest-level clusters
      _source.find_each do |record|
        _adapter.build_from(Tsuga::MAX_DEPTH, record).persist!
      end

      # for all depths N from 18 to 3
      (Tsuga::MAX_DEPTH-1).downto(Tsuga::MIN_DEPTH) do |depth|
        # progress.log "depth #{depth}"                                       if VERBOSE
        progress.title = "#{depth}.0"                                       if VERBOSE

        # find children (clusters or records) from deeper level, N+!
        points_ids = _adapter.at_depth(depth+1).collect_ids

        if points_ids.empty?
          progress.log "nothing to cluster"                                 if VERBOSE
          progress.finish                                                   if VERBOSE
          return
        end

        # TODO: group points to cluster by tile, and run on tiles in parallel.

        # assuming the data set is sparse, we walk the set instead of walking
        # all possible tiles:
        # 
        # as long as there are unprocessed children at depth N+1 (records if deepest level)
        # find the tile for the first remaining child;
        # in this tile,
        #   build a cluster of level N pointing to each child (_build_clusters)
        #   then run aggregation (_assemble_clusters)
        # 
        # 1 tile is processed at each iteration.
        # 
        progress.title = "#{depth}.1"                                       if VERBOSE
        progress.log "started with #{points_ids.length} points"             if VERBOSE
        progress.set_phase(depth, 1, points_ids.length)                     if VERBOSE
        while points_ids.any?
          progress.set_progress(points_ids.length)                          if VERBOSE

          point = _adapter.find_by_id(points_ids.first)
          tile = Tile.including(point, depth: depth)
          used_ids, clusters = _build_clusters(tile)
          if used_ids.empty?
            raise 'invariant broken'
          end
          points_ids -= used_ids
          Aggregator.new(clusters:clusters, ratio:FIRST_PASS_RATIO).run

          # TODO: use a save queue, only run saves if > 100 clusters to write
          _adapter.mass_create(clusters)
        end
        progress.reset

        # find recently-built clusters and run another pass of aggreggation
        # between neighbouring tiles
        # TODO: add tests for second pass
        cluster_ids = _adapter.at_depth(depth).collect_ids
        drop_count = 0

        progress.title = "#{depth}.2"                                       if VERBOSE
        progress.log "created #{cluster_ids.length} clusters on first pass" if VERBOSE
        progress.set_phase(depth, 2, cluster_ids.length)                    if VERBOSE
        loop do
          progress.set_progress(cluster_ids.length)                         if VERBOSE

          while cluster_ids.any?
            cluster = _adapter.where(id: cluster_ids.pop).first
            break if cluster
          end
          break if cluster.nil?
          
          tile = Tile.including(cluster, depth: depth)
          neighbours = tile.neighbours

          used_ids = _adapter.in_tile(tile).collect_ids
          raise 'invariant broken' if used_ids.empty?
          cluster_ids -= used_ids

          clusters = _adapter.in_tile(*neighbours).to_a
          Aggregator.new(clusters:clusters, ratio:SECOND_PASS_RATIO).tap do |aggregator|
            aggregator.run
            drop_count += aggregator.dropped_clusters.length
            aggregator.dropped_clusters.each(&:delete)
            aggregator.updated_clusters.each(&:persist!)
          end
        end if true
        progress.log "dropped #{drop_count} clusters on second pass"        if VERBOSE && drop_count > 0

        # set parent_id in the whole tree
        # TODO: fix parent_id in tree
        progress.title = "#{depth}.3"                                       if VERBOSE
        # progress.set_phase(depth, 3, _adapter.at_depth(depth).count)        if VERBOSE
        _adapter.at_depth(depth).find_each do |cluster|
          cluster.children_ids.each do |child_id|
            _adapter.find_by_id(child_id).tap do |child|
              child.parent_id = cluster.id
              child.persist!
            end
          end
        end
      end
      progress.finish                                                       if VERBOSE
    end

    private

    def progress
      @_progressbar ||= ProgressBar.create.extend(SteppedProgressBar)
    end

    module SteppedProgressBar
      def set_phase(depth, phase, count)
        _compute_totals
        @current_phase = phase
        @current_depth = depth
        @current_count = count
      end

      def set_progress(count)
        key = [@current_depth,@current_phase]
        self.progress = @phase_total[key] - 
          @phase_subtotal[key] * count / @current_count
      rescue Exception => e
        require 'pry' ; require 'pry-nav' ; binding.pry
      end

      private

      MAX = Tsuga::MAX_DEPTH-1
      MIN = Tsuga::MIN_DEPTH
      FACTOR = 0.5

      def _compute_totals
        return if @phase_total
        sum = 0
        @phase_total = {}
        @phase_subtotal = {}
        MAX.downto(MIN) do |depth|
          [1,2].each do |phase|
            weight = FACTOR ** (MAX-depth)
            sum += weight
            @phase_total[[depth,phase]] = sum
            @phase_subtotal[[depth,phase]] = weight
          end
        end
        self.total = sum
      end
    end


    # return the record IDs used
    def _build_clusters(tile)
      used_ids = []
      clusters = []

      _adapter.in_tile(*tile.children).find_each do |child|
        cluster = _adapter.build_from(tile.depth, child)
        clusters << cluster
        used_ids << child.id
      end

      return [used_ids, clusters]
    end


  end
end
