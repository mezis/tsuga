require 'tsuga/model/cluster'
require 'tsuga/model/tile'
require 'tsuga/adapter/active_record/base'

module Tsuga::Adapter::ActiveRecord
  module Cluster
    def self.included(by)
      by.send :include, Base
      by.send :include, Tsuga::Model::Cluster
      by.extend Scopes
    end

    def children_ids
      @_children_ids ||= begin
        stored = super
        stored ? stored.split(',').map(&:to_i) : []
      end
    end

    def children_ids=(value)
      changed = (@_children_ids != value)
      @_children_ids = value
      super(@_children_ids.join(',')) if changed
      @_children_ids
    end

    module Scopes
      def at_depth(depth)
        where(:depth => depth)
      end

      # FIXME: this also is redundant with the mongoid adapter implementation
      def in_tile(tile)
        sw = tile.southwest.geohash.to_s(16)
        ne = tile.northeast.geohash.to_s(16)
        where(depth: tile.depth).where('geohash >= ? AND geohash <= ?', sw, ne)
      end

      def in_tiles(tiles)
        sql_clause = (['(geohash >= ? AND geohash <= ?)'] * tiles.length).join(' OR ')
        boundaries = tiles.map { |t| [t.southwest.geohash.to_s(16), t.northeast.geohash.to_s(16)] }.flatten
        where(depth: tiles.first.depth).where(sql_clause, *boundaries)
      end

      def in_viewport(sw:nil, ne:nil, depth:nil)
        tiles = Tsuga::Model::Tile.enclosing_viewport(point_sw: sw, point_ne: ne, depth: depth)
        in_tiles(tiles)
      end
    end
  end
end
