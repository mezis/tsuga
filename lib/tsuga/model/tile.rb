require 'tsuga'
require 'tsuga/model/point'

module Tsuga::Model
  class Tile
    # corner points
    attr_accessor :southwest, :northeast

    # level in the tile tree, also number of relevant high bits
    # in the geohash.
    attr_accessor :depth

    WIGGLE_FACTOR = 1e-4

    def contains?(point)
      point.prefix(depth) == southwest.prefix(depth)
    end

    def dlat(count = 1)
      (northeast.lat - southwest.lat) * (count + WIGGLE_FACTOR)
    end

    def dlng(count = 1)
      (northeast.lng - southwest.lng) * (count + WIGGLE_FACTOR)
    end

    def code
      @_code ||= southwest.get_tilecode(depth)
    end

    # return the 4 children of this tile
    def children
      geohash = southwest.geohash
      new_depth = depth + 1
      [0b00, 0b01, 0b10, 0b11].map { |quadrant|
        geohash | (quadrant << (64 - new_depth * 2))
      }.map { |hash|
        # TODO: this cound be more efficiently written using a depth/southwest constructor
        self.class.including(Point.new(geohash: hash), depth: new_depth)
      }
    end

    # return a neighouring tile offset in tile increments
    # TODO: this could be implemented using bit logic
    def neighbour(lat:0, lng:0)
      new_point = Point.new(
        lat: southwest.lat + dlat(lat),
        lng: southwest.lng + dlng(lng))
      Tile.including(new_point, depth: depth)
    end

    # return neighbouring tiles to the north, northeast, and east
    def neighbours
      offsets = (-1..1).to_a.product((-1..1).to_a)
      offsets.map do |lat, lng|
        begin 
          neighbour(lat:lat, lng:lng)
        rescue NoMethodError => e
          require 'pry' ; require 'pry-nav' ; binding.pry
        rescue ArgumentError
          nil # occurs on world boundaries
        end
      end.compact
    end

    module ClassMethods
      # Returns a Tile instance.
      # +point+ should respond to +geohash+.
      # Options:
      # - :depth
      def including(point, options={})
        depth = options[:depth]
        raise ArgumentError, 'bad depth' unless (0..31).include?(depth)

        bits  = 2 * depth
        lo_mask = ((1<<bits) - 1) << (64-bits) # mask for high bits
        hi_mask = ((1<<(64-bits)) - 1)         # mask for low bits

        new.tap do |t|
          t.depth = depth
          t.southwest = Point.new(geohash: point.geohash.to_i & lo_mask)
          # TODO: calculating northeast can probably be done lazily
          t.northeast = Point.new(geohash: point.geohash.to_i & lo_mask | hi_mask)
          t.southwest.lat
          t.northeast.lat
        end
      end

      # Return an array of Tile instances that encloses both corner points
      # FIXME: this is untested
      def enclosing_viewport(point_ne:nil, point_sw:nil, depth:nil)
        # $stderr.puts "aiming to enclose:"
        # $stderr.puts "%.2f %.2f -> %.2f %.2f" % [point_ne.lat, point_ne.lng, point_sw.lat, point_sw.lng]
        # $stderr.flush

        tiles = []
        first_tile = including(point_sw, depth:depth)

        offset_lat = 0
        loop do
          offset_lng = 0
          loop do 
            # $stderr.puts("offset: #{offset_lat} #{offset_lng}")
            # $stderr.flush
            new_tile = first_tile.neighbour(lat:offset_lat, lng:offset_lng)
            tiles << new_tile

            # $stderr.puts "%.2f %.2f -> %.2f %.2f" % [new_tile.southwest.lat, new_tile.southwest.lng, new_tile.northeast.lat, new_tile.northeast.lng]
            # $stderr.flush

            offset_lng += 1
            break if tiles.last.northeast.lng >= point_ne.lng
          end
          break if tiles.last.northeast.lat >= point_ne.lat
          offset_lat += 1
          offset_lng = 0
        end

        return tiles
      end
    end
    extend ClassMethods
  end
end

__END__

load 'lib/tsuga/model/tile.rb'

# {"n"=>"41.41169761785169", "e"=>"2.2055472226562642", "s"=>"41.33015287320352", "w"=>"2.107700237792983", "z"=>"3"
  

sw = Tsuga::Model::Point.new(lat: 41.33015287320352, lng: 2.107700237792983)
ne = Tsuga::Model::Point.new(lat: 41.41169761785169, lng: 2.2055472226562642)

Tsuga::Model::Tile.including(sw, depth: 7)
Tsuga::Model::Tile.including(ne, depth: 7)

Tsuga::Model::Tile.enclosing_viewport(point_sw:sw, point_ne:ne, depth:7).length

