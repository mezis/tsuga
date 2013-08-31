require 'tsuga/model/point'

module Tsuga::Model
  class Tile
    # corner points
    attr_accessor :northwest, :southeast

    # level in the tile tree, also number of relevant high bits
    # in the geohash.
    attr_accessor :depth

    def neighbours
      raise NotImplementedError
    end

    module ClassMethods
      # Returns a Tile instance.
      # +point+ should respond to +geohash+.
      # Options:
      # - :depth
      def including(point, options={})
        depth = options[:depth]
        lo_mask = ((1<<depth) - 1) << (64-depth) # mask for high bits
        hi_mask = ((1<<(64-depth)) - 1)          # mask for low bits

        new.tap do |t|
          t.depth = depth
          t.northwest = Point.new(point.geohash & lo_mask)
          t.southeast = Point.new(point.geohash & lo_mask | hi_mask)
        end
      end
    end
    extend ClassMethods
  end
end
