require 'tsuga/model/tile'
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
        sw = '%016x' % tile.southwest.geohash
        ne = '%016x' % tile.northeast.geohash
        where(:geohash.gte => sw, :geohash.lte => ne)
      end
    end
  end
end
