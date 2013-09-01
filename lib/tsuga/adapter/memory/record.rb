require 'tsuga/model/record'
require 'tsuga/adapter/memory/base'

module Tsuga::Adapter::Memory
  class Record 
    module Fields
      attr_accessor :geohash, :lat, :lng
    end
    include Fields
    include Base
    include Tsuga::Model::Record

    def self.in_tile(tile)
      scoped(lambda { |r| tile.contains?(r) })
    end
  end
end
