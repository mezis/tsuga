require 'tsuga/model/cluster'
require 'tsuga/adapter/sequel/base'

module Tsuga::Adapter::Sequel
  module Cluster
    include Tsuga::Model::Cluster

    def self.included(by)
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
        nw = tile.northwest.geohash
        se = tile.southeast.geohash
        where { geohash >= nw }.and { geohash <= se }
      end
    end
  end
end
