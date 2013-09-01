require 'tsuga/model/tile'
require 'tsuga/service/aggregator'

module Tsuga::Service
  class Clusterer
    MAX_DEPTH = 20
    MIN_DEPTH = 3

    attr_reader :_adapter

    def initialize(adapter)
      @_adapter = adapter
    end

    def run
      # delete all clusters
      _adapter.clusters.delete_all

      # for all depths N from 20 to 3
      MAX_DEPTH.downto(MIN_DEPTH) do |depth|
        # create clusters from lower-level clusters (or records)
        # 1 tile processed at each iteractions.

        if depth == MAX_DEPTH
          points_ids = _adapter.records.collect_ids
          find_from = _adapter.records
        else
          points_ids = _adapter.clusters.at_depth(depth+1).collect_ids
          find_from = _adapter.clusters
        end

        # assuming the data set is sparse, we walk the set instead of walking
        # all possible tiles.
        # 1 tile processed at each iteractions.
        while points_ids.any?
          points = find_from.find(points_ids.first)
          tile = Tile.including(point, :depth => depth)
          used_ids = _create_clusters(tile)
          points_ids -= used_ids
        end

        cluster_ids = _adapter.clusters.at_depth(depth).collect_ids
        while cluster_ids.any?
          cluster = _adapter.clusters.find(cluster_ids.first)
          tile = Tile.including(cluster, :depth => depth)
          _assemble_clusters(tile)
        end

        _walk_tiles_at(depth) do |tile|
          # for all clusters at depth N+1 in tile T (records if deepest level)
          # create a cluster of level N pointing to the deeper cluster
          _create_clusters(depth, tile)
          # run clustering in tile
          _assemble_clusters(tile)
        end

        # for each tile T
        _walk_tiles_at(depth) do |tile|
          # run clustering with this tile's and the neighbouringh tiles's clusters
          # _assemble_clusters(*tile.neighbours)
        end
    end

    private

    # shorthand
    Tile = Tsuga::Model::Tile


    # return the record IDs used
    def _create_clusters(tile)
      result = Set.new

      if tile.depth == MAX_DEPTH
        _adapter.records
        .in_tile(tile).find_each do |record|
          cluster = _adaper.clusters.new(depth, record)
          cluster.persist!
          result << cluster.id
        end
      else
        _adapter.clusters.at_depth(tile.depth+1)
        .in_tile(tile).find_each do |cluster|
          parent = _adaper.clusters.new(depth, cluster)
          parent.persist!
          result << cluster.id

          cluster.parent_id = parent.id
          cluster.persist!
        end
      end
    end

    def _assemble_clusters(*tiles)
      clusters = Set.new
      _adapter.clusters.in_tile(*tiles).find_each { |c| clusters << c }
      Aggregator.new(clusters).run
    end

  end
end
