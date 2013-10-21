require 'tsuga'
require 'tsuga/model/point'

module Tsuga::Model
  class Tile
    # corner points
    attr_accessor :northwest, :southeast

    # level in the tile tree, also number of relevant high bits
    # in the geohash.
    attr_accessor :depth

    def contains?(point)
      (point.geohash >= northwest.geohash) && (point.geohash <= southeast.geohash)
    end

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
        raise ArgumentError, 'bad depth' unless (1..31).include?(depth)

        bits  = 2 * depth
        lo_mask = ((1<<bits) - 1) << (64-bits) # mask for high bits
        hi_mask = ((1<<(64-bits)) - 1)         # mask for low bits

        new.tap do |t|
          t.depth = depth
          t.northwest = Point.new(geohash: point.geohash.to_i & lo_mask)
          t.southeast = Point.new(geohash: point.geohash.to_i & lo_mask | hi_mask)
        end
      end

      # Return a Tile instance that encloses both corner points
      # FIXME: this is untested
      def enclosing_viewport(point_nw, point_se)
        0.upto(31) do |depth|
          tile = including(point_nw)
          break tile if tile.contains?(point_se)
        end
      end
    end
    extend ClassMethods
  end
end
