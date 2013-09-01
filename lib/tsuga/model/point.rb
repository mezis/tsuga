module Tsuga::Model

  # Represents a position in the 0..1 x 0..1 square, modeling points on the
  # Earth as represented by their longitude/latitude coordinates.
  # 
  # Concretions have the following accessors:
  # - :geohash (64-bit integer)

  # - :lat (float, -90..90)
  # - :lng (float, -180..180)
  # 
  module PointTrait
    include Comparable

    def <=>(other)
      geohash <=> other.geohash
    end


    def distance_to(other)
      Math.sqrt((self.lat - other.lat) ** 2 + (self.lng - other.lng) ** 2)
    end


    def &(other)
      distance_to(other)
    end


    def geohash=(value)
      @_latlng = nil
      super
    end

    def set_coords(lat, lng)
      raise ArgumentError, 'bad lng' unless (-180.0 ... 180.0).include?(lng)
      raise ArgumentError, 'bad lat' unless ( -90.0 ...  90.0).include?(lat)

      self.geohash = _geohash_from_latlng(lat, lng)
    end


    def lat
      _latlng.first
    end


    def lng
      _latlng.last
    end


    private


    def _latlng
      @_latlng ||= _latlng_from_geohash
    end


    # Convert the geohash into lat/lng
    def _latlng_from_geohash
      raise ArgumentError, 'bad hash' unless (0 ... (1<<64)).include?(geohash)

      lat,lng = _deinterleave_bits(geohash)

      lat = lat * 180.0 / (1<<32) -  90.0
      lng = lng * 360.0 / (1<<32) - 180.0

      [lat, lng]
    end


    def _geohash_from_latlng(lat, lng)
      normalized_lat = ((lat +  90.0) * (1<<32) / 180.0).to_i
      normalized_lng = ((lng + 180.0) * (1<<32) / 360.0).to_i
      _interleave_bits(normalized_lat, normalized_lng)
    end


    def _interleave_bits(a,b)
      (_interleave_bits_16b(a >> 16,    b >> 16) << 32) |
      (_interleave_bits_16b(a & 0xffff, b & 0xffff))
    end

    def _deinterleave_bits(z)
      x_hi, y_hi = _deinterleave_bits_16b(z >> 32)
      x_lo, y_lo = _deinterleave_bits_16b(z & 0xFFFFFFFF)

      [((x_hi << 16) | x_lo), ((y_hi << 16) | y_lo)]
    end

    Magic = [0x55555555, 0x33333333, 0x0F0F0F0F, 0x00FF00FF]

    # Interleave lower 16 bits of x and y, so the bits of x
    # are in the even positions and bits from y in the odd;
    # z gets the resulting 32-bit Morton Number.  
    # x and y must initially be less than 65536.
    # Rubyfied from http://graphics.stanford.edu/~seander/bithacks.html
    def _interleave_bits_16b(x,y)
      x = (x | (x << 8)) & Magic[3]
      x = (x | (x << 4)) & Magic[2]
      x = (x | (x << 2)) & Magic[1]
      x = (x | (x << 1)) & Magic[0]
      y = (y | (y << 8)) & Magic[3]
      y = (y | (y << 4)) & Magic[2]
      y = (y | (y << 2)) & Magic[1]
      y = (y | (y << 1)) & Magic[0]
      z = x | (y << 1)
    end

    # Deinterleave even bits and odd bits (resp.) to a 2-tuple.
    # Rubyfied from http://fgiesen.wordpress.com/2009/12/13/decoding-morton-codes/
    def _deinterleave_bits_16b(z)
      [_even_bits(z), _even_bits(z >> 1)]
    end

    def _even_bits(z)
      x = z & 0x55555555
      x = (x ^ (x >>  1)) & 0x33333333
      x = (x ^ (x >>  2)) & 0x0f0f0f0f
      x = (x ^ (x >>  4)) & 0x00ff00ff
      x = (x ^ (x >>  8)) & 0x0000ffff
    end
  end


  class Point < Struct.new(:geohash)
    include PointTrait
  end
end
