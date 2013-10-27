require 'tsuga/model/tile'
require 'tsuga/model/cluster'
require 'tsuga/adapter/mongoid/base'
require 'tsuga/adapter/shared/cluster'
require 'mongoid'

module Tsuga::Adapter::Mongoid
  module Cluster
    def self.included(by)
      by.send :include, Base
      by.send :include, Tsuga::Model::Cluster
      by.send :include, Tsuga::Adapter::Shared::Cluster
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
        codes = tiles.map { |t| "%016x" % t.code }
        where(:tilecode.in => codes)
      end
    end
  end
end
