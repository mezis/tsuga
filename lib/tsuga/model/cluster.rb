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
  class Cluster
    include Tsuga::Model::PointTrait

    def initialize(depth, other)
      self.depth = depth
      inherit_fields_from(other)
    end

    # other is either a Cluster or a Record
    def inherit_fields_from(other)
      self.geohash       = other.geohash
      self.lat           = other.lat
      self.lng           = other.lng
      self.children_ids  = [other.id]
      self.children_type = other.class.name

      case other
      when Record
        self.weight      = 1
        self.sum_lng     = other.lng
        self.sum_lat     = other.lat
      else
        self.weight      = other.weight
        self.sum_lng     = other.sum_lng
        self.sum_lat     = other.sum_lat
      end
    end
  end
end