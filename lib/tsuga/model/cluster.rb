require 'tsuga/model/point'

module Tsuga::Model
  # Concretions (provided by adapters) have the following accessors:
  # - :depth
  # - :parent_id
  # - :children_type (Record or Cluster)
  # - :children_ids
  # - :weight (count of Record in subtree)
  # - :sum_lat
  # - :sum_lng
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
      self.depth   ||= 1
      self.geohash ||= 0xC000000000000000 # equator/greenwich
    end

    def self.build_from(depth, other)
      new.tap do |cluster|
        cluster.depth = depth
        cluster._inherit_fields_from(other)
      end
    end

    # other is either a Cluster or a Record
    def _inherit_fields_from(other)
      self.geohash       = other.geohash
      self.children_ids  = [other.id]
      self.children_type = other.class.name

      case other
      when Record
        self.weight      = 1
        self.sum_lng     = other.lng
        self.sum_lat     = other.lat
      when Cluster
        self.weight      = other.weight
        self.sum_lng     = other.sum_lng
        self.sum_lat     = other.sum_lat
      else
        raise ArgumentError
      end
    end
  end
end