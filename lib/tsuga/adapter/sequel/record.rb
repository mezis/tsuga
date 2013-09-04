require 'tsuga/model/record'
require 'tsuga/adapter/sequel/base'

module Tsuga::Adapter::Sequel
  module Record
    include Tsuga::Model::Record

    def self.included(by)
      by.dataset_module Scopes
    end

    module Scopes
      def in_tile(tile)
        nw = tile.northwest.geohash
        se = tile.southeast.geohash
        where { geohash >= nw }.and { geohash <= se }
      end
    end
  end
end
