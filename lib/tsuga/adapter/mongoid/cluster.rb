require 'tsuga/model/cluster'
require 'tsuga/adapter/mongoid/base'
require 'mongoid'

module Tsuga::Adapter::Mongoid
  module Cluster
    def self.included(by)
      by.send :include, Base
      by.send :include, Tsuga::Model::Cluster
      by.extend ScopeMethods
    end

    module ScopeMethods
      def at_depth(depth)
        where(:depth => depth)
      end

      def in_tile(tile)
        nw = '%016x' % tile.northwest.geohash
        se = '%016x' % tile.southeast.geohash
        where(:geohash.gte => nw, :geohash.lte => se)
      end

      def in_viewport(point_nw, point_se)
        in_tile(Tile.enclosing_viewport(point_nw, point_se))
      end
    end
  end
end