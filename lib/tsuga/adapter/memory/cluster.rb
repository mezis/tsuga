require 'tsuga/model/cluster'
require 'tsuga/adapter/memory/base'

module Tsuga::Adapter::Memory
  class Cluster
    module Fields
      attr_accessor :geohash, :lat, :lng, :depth, :parent_id, :children_ids
      attr_accessor :sum_lat, :sum_lng, :weight
    end
    include Fields
    include Base
    include Tsuga::Model::Cluster

  end
end
