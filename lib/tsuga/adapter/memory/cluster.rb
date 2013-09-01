require 'tsuga/model/cluster'
require 'tsuga/adapter/memory/base'

module Tsuga::Adapter::Memory
  class Cluster
    include Base
    include Tsuga::Model::Cluster
    attr_accessor :geohash, :lat, :lng, :depth, :parent_id, :children_ids, :sum_lat, :sum_lng
  end
end
