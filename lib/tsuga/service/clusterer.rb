require 'tsuga/model/tile'
require 'tsuga/service/aggregator'

require 'ruby-progressbar'

module Tsuga::Service
  class Clusterer
    PROXIMITY_RATIO  = 0.15
    RUN_SANITY_CHECK = false
    VERBOSE          = ENV['VERBOSE']
    Tile = Tsuga::Model::Tile

    attr_reader :_adapter, :_source, :_queue

    def initialize(source: nil, adapter: nil)
      @_source  = source
      @_adapter = adapter
      @_queue   = WriteQueue.new(adapter: adapter)
    end

    def run
      # delete all clusters
      _adapter.delete_all

      # create lowest-level clusters
      _source.find_each do |record|
        _queue.push _adapter.build_from(Tsuga::MAX_DEPTH, record)
      end
      _queue.flush

      # for all depths N from 18 to 3
      (Tsuga::MAX_DEPTH-1).downto(Tsuga::MIN_DEPTH) do |depth|
        progress.log "depth #{depth}"                                       if VERBOSE
        progress.title = "#{depth}.0"                                       if VERBOSE

        # create clusters at this level from children
        # TODO: use a save queue, only run saves if > 100 clusters to write
        cluster_ids = Set.new
        _adapter.at_depth(depth+1).find_each do |child|
          _queue.push _adapter.build_from(depth, child)
        end
        _queue.flush
        cluster_ids = MutableSet.new(_adapter.at_depth(depth).collect_ids)

        if cluster_ids.empty?
          progress.log "nothing to cluster"                                 if VERBOSE
          break
        end

        # TODO: group points to cluster by tile, and run on tiles in parallel.

        progress.title = "#{depth}.1"                                       if VERBOSE
        progress.log "started with #{cluster_ids.length} clusters"          if VERBOSE
        progress.set_phase(depth, 1, cluster_ids.length)                    if VERBOSE
        while cluster_ids.any?
          progress.set_progress(cluster_ids.length)                         if VERBOSE

          cluster = _adapter.find_by_id(cluster_ids.first)
          raise 'internal error: cluster was already removed' if cluster.nil?
          tile = Tile.including(cluster, depth: depth)

          clusters = _adapter.in_tile(*tile.neighbours).to_a
          processed_cluster_ids = clusters.collect(&:id)

          # clusters we aggregate in this loop iteration
          # they are _not_ the same as what we pass to the aggregator,
          # just those inside the fence
          fenced_cluster_ids = _adapter.in_tile(tile).collect_ids
          raise RuntimeError, 'no cluster in fence' if fenced_cluster_ids.empty?

          Aggregator.new(clusters:clusters, ratio:PROXIMITY_RATIO, fence:tile).tap do |aggregator|
            aggregator.run

            if VERBOSE
              progress.log("aggregator: %4d left, %2d processed, %2d in fence, %2d updated, %2d dropped" % [
                cluster_ids.length,
                processed_cluster_ids.length,
                fenced_cluster_ids.length,
                aggregator.updated_clusters.length,
                aggregator.dropped_clusters.length]) 
              if aggregator.updated_clusters.any?
                progress.log("updated: #{aggregator.updated_clusters.collect(&:id).join(', ')}")
              end
              if aggregator.dropped_clusters.any?
                progress.log("dropped: #{aggregator.dropped_clusters.collect(&:id).join(', ')}")
              end
            end

            cluster_ids.remove! fenced_cluster_ids
            # updated clusters may need to be reprocessed (they might have fallen close enough to tile edges)
            # TODO: as further optimisation, do not mark for reprocessing clusters that are still inside the fence
            cluster_ids.merge! aggregator.updated_clusters.collect(&:id)
            # destroyed clusters may include some on the outer fringe of the fence tile
            cluster_ids.remove! aggregator.dropped_clusters.collect(&:id)

            aggregator.dropped_clusters.each(&:destroy)
            _adapter.mass_update(aggregator.updated_clusters)
          end

          if RUN_SANITY_CHECK
            # sanity check: all <cluster_ids> should exist
            not_removed = cluster_ids - _adapter.at_depth(depth).collect_ids
            if not_removed.any?
              raise "cluster_ids contains IDs of deleted clusters: #{not_removed.to_a.join(', ')}"
            end

            # sanity check: sum of weights should match that of lower level
            deeper_weight = _adapter.at_depth(depth+1).sum(:weight)
            this_weight   = _adapter.at_depth(depth).sum(:weight)
            if deeper_weight != this_weight
              raise "mismatch between weight at this depth (#{this_weight}) and deeper level (#{deeper_weight})"
            end
          end
        end

        # set parent_id in the whole tree
        # this is made slightly more complicated by #find_each's scoping
        progress.title = "#{depth}.2"                                       if VERBOSE
        child_mappings = {}
        _adapter.at_depth(depth).find_each do |cluster|
          cluster.children_ids.each do |child_id|
            child_mappings[child_id] = cluster.id
          end
        end
        child_mappings.each_pair do |child_id, parent_id|
          cluster = _adapter.find_by_id(child_id)
          cluster.parent_id = parent_id
          _queue.push cluster
        end
        _queue.flush
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
          depth_weight = FACTOR ** (MAX-depth)
          [1,1,1].each_with_index do |phase_weight, phase_index|
            phase_subtotal = depth_weight * phase_weight
            sum += phase_subtotal
            @phase_total[[depth,phase_index]]    = sum
            @phase_subtotal[[depth,phase_index]] = phase_subtotal
          end
        end
        self.total = sum
      end
    end

    # A Set-like structure, with in-place merging with, and removing of, another enumerable.
    class MutableSet
      include Enumerable
      extend Forwardable

      def initialize(enum = nil)
        @_data = {}
        merge!(enum) if enum
      end

      def -(enum)
        self.class.new.tap do |result|
          result.instance_variable_set(:@_data, @_data.dup)
          result.remove!(enum)
        end
      end

      def each
        @_data.each_key { |k| yield k }
      end

      def merge!(enum)
        enum.each { |key| @_data[key] = true }
      end

      def remove!(enum)
        enum.each { |key| @_data.delete(key) }
      end

      def_delegators :@_data, :size, :length, :empty?
    end


    # TODO: extract to a separate file
    class WriteQueue
      QUEUE_SIZE = 250

      def initialize(adapter:nil)
        @_adapter = adapter
        @_queue    = []
      end

      def push(value)
        @_queue.push(value)
        flush if @_queue.size > QUEUE_SIZE
        nil
      end

      def flush
        # separate inserts from updates
        inserts = _queue.map { |c| c.new_record? ? c : nil }.compact
        updates = _queue.map { |c| c.new_record? ? nil : c }.compact

        _adapter.mass_create(inserts) if inserts.any?
        _adapter.mass_update(updates) if updates.any?
        _queue.clear
      end

      private

      attr_reader :_queue, :_adapter
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
