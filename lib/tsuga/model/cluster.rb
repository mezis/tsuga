require 'tsuga'
require 'tsuga/model/point'

module Tsuga::Model
  # Concretions (provided by adapters) have the following accessors:
  # - :depth
  # - :parent_id
  # - :children_type (Record or Cluster)
  # - :children_ids
  # - :weight (count of Record in subtree)
  # - :sum_lat, :sum_lng
  # - :ssq_lat, :ssq_lng
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
      # equator/greenwich
      self.lat     ||= 0 
      self.lng     ||= 0
    end

    # latitude deviation in cluster
    def dlat
      @_dlat ||= _safe_sqrt(ssq_lat/weight - (sum_lat/weight)**2)
    end

    # longitude deviation in cluster
    def dlng
      @_dlng ||= _safe_sqrt(ssq_lng/weight - (sum_lng/weight)**2)
    end

    # radius of cluster
    def radius
      @_radius ||= Math.sqrt(dlat ** 2 + dlng ** 2)
    end

    # density (weight per unit area)
    def density
      @_density ||= begin
        # min. radius 1.4e-4 (about 15m at european latitudes)
        # for 1-point clusters where density would otherwise be infinite
        our_radius = [radius, 1.4e-4].max 
        # Math.log(weight / (our_radius ** 2)) / Math.log(2)
        weight / (our_radius ** 2)
      end
    end

    def geohash=(value)
      super(value)
      _update_tilecode
      geohash
    end

    def depth=(value)
      super(value)
      _update_tilecode
      depth
    end


    def merge(other)
      raise ArgumentError, 'not same depth'  unless depth == other.depth
      raise ArgumentError, 'not same parent' unless parent_id == other.parent_id

      self.weight  += other.weight
      self.sum_lat += other.sum_lat
      self.sum_lng += other.sum_lng
      self.ssq_lat += other.ssq_lat
      self.ssq_lng += other.ssq_lng
      self.lat      = sum_lat/weight
      self.lng      = sum_lng/weight
      self.children_ids += other.children_ids

      # dirty calculated values
      @_dlng = @_dlat = @_radius = @_density = nil
    end


    module ClassMethods
      # Cluster factory.
      # +other+ is either a Cluster or a Record
      # 
      # FIXME: there's a potential for overflow here on large datasets on the sum-
      # and sum-of-squares fields. it can be mitigated by using double-precision
      # fields, or calculating sums only on the children (instead of the subtree)
      def build_from(depth, other)
        c = new()
        c.depth = depth

        c.lat           = other.lat
        c.lng           = other.lng
        c.children_ids  = [other.id]
        c.children_type = other.class.name

        case other
        when Cluster
          c.weight      = other.weight
          c.sum_lng     = other.sum_lng
          c.sum_lat     = other.sum_lat
          c.ssq_lng     = other.ssq_lng
          c.ssq_lat     = other.ssq_lat
        else
          c.weight      = 1
          c.sum_lng     = other.lng
          c.sum_lat     = other.lat
          c.ssq_lng     = other.lng ** 2
          c.ssq_lat     = other.lat ** 2
        end

        c.geohash # force geohash calculation
        return c
      end
    end

    def self.included(by)
      by.extend(ClassMethods)
    end
  

    private


    def _safe_sqrt(value)
      (value < 0) ? 0 : Math.sqrt(value)
    end


    def _update_tilecode
      if geohash && depth
        self.tilecode = prefix(depth)
      else
        self.tilecode = nil
      end
    end
  end
end