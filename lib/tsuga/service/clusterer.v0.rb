require 'tsuga/model/tile'

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
        # for each tile T
        _walk_tiles_at(depth) do |tile|
          # for all clusters at depth N+1 in tile T (records if deepest level)
          # create a cluster of level N pointing to the deeper cluster
          _create_clusters(depth, tile)
          # run clustering in tile
          _assemble_clusters(depth, tile)
        end

        # for each tile T
        _walk_tiles_at(depth) do |tile|
          # run clustering with this tile's and the neighbouringh tiles's clusters
          _assemble_clusters(depth, tile.neighbours)          
        end
    end

    private

    def _walk_tiles_at(depth)
      Tsuga::Model::Tile.each_at_depth(depth) { |t| yield t }
    end

    def _create_clusters(depth, tile)
      if depth == MAX_DEPTH
        _adapter.records.in_tile(tile).find_each do |record|
          cluster = _adaper.clusters.new(depth, record)
          cluster.persist!
        end
      else
        _adapter.clusters.at_depth(depth+1).in_tile(tile).find_each do |cluster|
          parent = _adaper.clusters.new(depth, cluster)
          parent.persist!

          cluster.parent_id = parent.id
          cluster.persist!
        end
      end
    end
  end
end
