require 'tsuga/model/record'
require 'tsuga/adapter/mongoid/base'
require 'mongoid'

module Tsuga::Adapter::Mongoid
  module Record
    def self.included(by)
      by.extend ScopeMethods
    end

    module ScopeMethods
      def in_tile(tile)
        nw = '%016x' % tile.northwest.geohash
        se = '%016x' % tile.southeast.geohash
        where(:geohash.gte => nw, :geohash.lte => se)
      end
    end
  end
end
