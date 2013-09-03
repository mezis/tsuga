require 'tsuga/model/record'
require 'tsuga/adapter/sequel/base'

module Tsuga::Adapter::Sequel
  class RecordModel < Sequel::Model(:records)
  end

  class Record < RecordModel
    include Base
    include Tsuga::Model::Record

    module Scopes
      def in_tile(tile)
        wrapped_dataset do
          nw = tile.northwest.geohash
          se = tile.southeast.geohash
          where { geohash >= nw }.and { geohash <= se }
        end
      end
    end
    extend Scopes
  end
end
