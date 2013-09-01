module Tsuga::Model
  # Concretions have the following accessors:
  # (same as Point)
  # 
  # And respond to class methods:
  # - :find(id)
  # - :collect_ids (returns a Set)
  # 
  class Record
    include Tsuga::Model::PointTrait

    def update_geohash
      self.geohash
    end

  end
end