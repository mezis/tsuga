require 'tsuga/model/cluster'
require 'tsuga/adapter/mongoid/base'
require 'mongoid'

module Tsuga::Adapter::Mongoid
  module Cluster
    def self.included(by)
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
    end
  end
end
