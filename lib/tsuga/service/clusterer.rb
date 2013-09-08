require 'tsuga/model/tile'
require 'tsuga/service/aggregator'

module Tsuga::Service
  class Clusterer
    MAX_DEPTH = 19
    MIN_DEPTH = 3
    Tile = Tsuga::Model::Tile

    attr_reader :_adapter

    def initialize(adapter)
      @_adapter = adapter
    end

    def run
      # delete all clusters
      _adapter.clusters.delete_all

      # for all depths N from 20 to 3
      MAX_DEPTH.downto(MIN_DEPTH) do |depth|
        log "at depth #{depth}"

        # find children (clusters or records) from deeper level, N+!
        if depth == MAX_DEPTH
          points_ids = _adapter.records.collect_ids
          find_from = _adapter.records
        else
          points_ids = _adapter.clusters.at_depth(depth+1).collect_ids
          find_from = _adapter.clusters
        end

        if points_ids.empty?
          log "nothing to cluster"
          return
        end

        # for all children at depth N+1 (records if deepest level)
        # create a cluster of level N pointing to the child.
        # assuming the data set is sparse, we walk the set instead of walking
        # all possible tiles.
        # 1 tile processed at each iteractions.
        log "creating clusters from children"
        while points_ids.any?
          log "... #{points_ids.size} children left"
          point = find_from.find_by_id(points_ids.first)
          tile = Tile.including(point, :depth => depth)
          used_ids = _create_clusters(tile)
          points_ids -= used_ids
        end
        log "... done"

        # with the same sparse-wlk logic, run aggregation in each tile
        # containing clusters.
        cluster_ids = _adapter.clusters.at_depth(depth).collect_ids
        log "aggregating clusters"
        while cluster_ids.any?
          log "... #{cluster_ids.size} clusters to process"
          cluster = _adapter.clusters.find_by_id(cluster_ids.first)
          tile = Tile.including(cluster, :depth => depth)
          used_ids = _assemble_clusters(tile)
          cluster_ids -= used_ids
        end
        log "... done"

        # not implemented yet:
        # run clustering with this tile's and the neighbouringh tiles's clusters
        # _assemble_clusters(*tile.neighbours)
      end
    end

    private


    def log(msg)
      return unless ENV['VERBOSE']
      $stderr.puts("[clusterer] #{msg}")
      $stderr.flush
    end


    # return the record IDs used
    def _create_clusters(tile)
      used_ids = []

      if tile.depth == MAX_DEPTH
        _adapter.records.in_tile(tile).find_each do |child|
          cluster = _adapter.clusters.build_from(tile.depth, child)
          cluster.persist!
          used_ids << child.id
        end
      else
        _adapter.clusters.at_depth(tile.depth+1).in_tile(tile).find_each do |child|
          cluster = _adapter.clusters.build_from(tile.depth, child)
          cluster.persist!

          child.parent_id = child.id
          child.persist!
          used_ids << child.id
        end
      end

      return used_ids
    end


    def _assemble_clusters(*tiles)
      raise ArgumentError if tiles.map(&:depth).sort.uniq.size > 1

      clusters = []
      depth = tiles.first.depth

      _adapter.clusters
        .at_depth(depth)
        .in_tile(*tiles)
        .find_each { |c| clusters << c }
      used_ids = clusters.map(&:id)
      Aggregator.new(clusters).run
      used_ids
    end

  end
end
