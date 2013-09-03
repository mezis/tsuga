require 'tsuga/model/cluster'
require 'tsuga/adapter/sequel/base'

module Tsuga::Adapter::Sequel
  class ClusterModel < Sequel::Model(:clusters)
  end

  class Cluster < ClusterModel
    include Base
    include Tsuga::Model::Cluster

    module Scopes
      def at_depth(depth)
        wrapped_dataset do
          where(:depth => depth)
        end
      end

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
