require 'tsuga/model/cluster'
require 'tsuga/model/tile'
require 'tsuga/adapter/sequel/base'

module Tsuga::Adapter::Sequel
  module Cluster
    def self.included(by)
      by.send :include, Base
      by.send :include, Tsuga::Model::Cluster
      by.dataset_module Scopes
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
        sw = tile.southwest.geohash
        ne = tile.northeast.geohash
        where { geohash >= sw }.and { geohash <= ne }
      end
    end
  end
end
