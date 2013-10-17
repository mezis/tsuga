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
        while points_ids.any?
          log "... #{points_ids.size} children left"
          point = find_from.find_by_id(points_ids.first)
          tile = Tile.including(point, :depth => depth)
          used_ids, clusters = _build_clusters(tile)
          points_ids -= used_ids
          _assemble_clusters(clusters)
          clusters.each { |c| c.persist! }
        end

        # TODO: fix parent_id in tree
      end
    end

    private


    def log(msg)
      return unless ENV['VERBOSE']
      $stderr.puts("[clusterer] #{msg}")
      $stderr.flush
    end


    # return the record IDs used
    def _build_clusters(tile)
      used_ids = []
      clusters = []

      if tile.depth == MAX_DEPTH
        _adapter.records.in_tile(tile).find_each do |child|
          cluster = _adapter.clusters.build_from(tile.depth, child)
          clusters << cluster
          used_ids << child.id
        end
      else
        _adapter.clusters.at_depth(tile.depth+1).in_tile(tile).find_each do |child|
          cluster = _adapter.clusters.build_from(tile.depth, child)
          clusters << cluster
          used_ids << child.id
        end
      end

      return [used_ids, clusters]
    end


    def _assemble_clusters(clusters)
      warn "running aggregation on #{clusters.size} clusters" if clusters.size > 50
      Aggregator.new(clusters).run
    end

  end
end
