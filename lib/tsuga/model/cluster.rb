require 'tsuga/model/point'

module Tsuga::Model
  # Concretions (provided by adapters) have the following accessors:
  # - :depth
  # - :parent_id
  # - :children_type (Record or Cluster)
  # - :children_ids
  # - :weight (count of Record in subtree)
  # - :sum_lat, :sum_lng
  # 
  # Respond to class methods:
  # - :in_tile(Tile) (scopish, response responds to :find_each)
  # - :at_depth(depth)
  # - :delete_all
  # - :find(id)
  # 
  # Respond to the following instance methods:
  # - :destroy
  module Cluster
    include Tsuga::Model::PointTrait
    
    def initialize
      super
      self.depth   ||= 1
      self.geohash ||= 0xC000000000000000 # equator/greenwich
    end


    def merge(other)
      raise ArgumentError, 'not same depth'  unless depth == other.depth
      raise ArgumentError, 'not same parent' unless parent_id == other.parent_id

      self.weight  += other.weight
      self.sum_lat += other.sum_lat
      self.sum_lng += other.sum_lng
      set_coords(sum_lat/weight, sum_lng/weight)
      self.children_ids += other.children_ids
    end


    module ClassMethods
      # Cluster factory.
      # +other+ is either a Cluster or a Record
      def build_from(depth, other)
        c = new()
        c.depth = depth

        c.lat           = other.lat
        c.lng           = other.lng
        c.children_ids  = [other.id]
        c.children_type = other.class.name

        case other
        when Record
          c.weight      = 1
          c.sum_lng     = other.lng
          c.sum_lat     = other.lat
        when Cluster
          c.weight      = other.weight
          c.sum_lng     = other.sum_lng
          c.sum_lat     = other.sum_lat
        else
          raise ArgumentError
        end

        c.geohash # force geohash calculation
        return c
      end
    end

    def self.included(by)
      by.extend(ClassMethods)
    end
  end
end