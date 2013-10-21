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

      def in_tile(*tiles)
        # where(:geohash.gte => sw, :geohash.lte => ne)
        depths = tiles.map(&:depth).uniq
        raise ArgumentError, 'all tiles must be at same depth' if depths.length > 1
        where(:depth => depths.first, :geohash_prefix.in => tiles.map(&:prefix))
      end
    end
  end
end
