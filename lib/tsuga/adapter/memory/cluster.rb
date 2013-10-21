require 'tsuga/model/cluster'
require 'tsuga/adapter/memory/base'

module Tsuga::Adapter::Memory
  module Cluster
    module Fields
      attr_accessor :geohash, :lat, :lng, :depth, :parent_id
      attr_accessor :children_type, :children_ids
      attr_accessor :sum_lat, :sum_lng, :weight
    end

    def self.included(by)
      by.send :include, Fields
      by.send :include, Base
      by.send :include, Tsuga::Model::Cluster
      by.extend ClassMethods
    end

    module ClassMethods
      def at_depth(depth)
        scoped(lambda { |r| r.depth == depth })
      end

      def in_tile(*tiles)
        scoped(lambda { |r| tiles.any? { |t| t.contains?(r) } })
      end
    end
  end
end
