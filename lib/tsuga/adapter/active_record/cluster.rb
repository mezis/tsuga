require 'tsuga/model/cluster'
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

      def in_tile(tile)
        nw = tile.northwest.geohash
        se = tile.southeast.geohash
        where('geohash >= ? AND geohash <= ?', nw, se)
      end

      def in_viewport(point_nw, point_se)
        in_tile(Tile.enclosing_viewport(point_nw, point_se))
      end
    end
  end
end
