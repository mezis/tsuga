require 'tsuga'

module Tsuga::Model

  # Represents a position in the 0..1 x 0..1 square, modeling points on the
  # Earth as represented by their longitude/latitude coordinates.
  # 
  # Concretions have the following accessors:
  # - :geohash (64-bit integer)
  # 
  # - :lat (float, -90..90)
  # - :lng (float, -180..180)
  # 
  module PointTrait



    def distance_to(other)
      Math.sqrt((self.lat - other.lat) ** 2 + (self.lng - other.lng) ** 2)
    end


    def =~(other)
      self.geohash == other.geohash
    end


    def &(other)
      distance_to(other)
    end


    def geohash(autoupdate=true)
      autoupdate ? (super() || _update_geohash) : super()
    end


    def geohash=(value, dirty=true)
      self.lat = self.lng = nil if value && dirty
      super(value)
    end


    def lat(autoupdate=true)
      autoupdate ? (super() || _update_latlng.first) : super()
    end


    def lng(autoupdate=true)
      autoupdate ? (super() || _update_latlng.last) : super()
    end


    def lat=(value, dirty=true)
      self.geohash = nil if value && dirty
      super(value)
    end


    def lng=(value, dirty=true)
      self.geohash = nil if value && dirty
      super(value)
    end


    def set_coords(_lat, _lng)
      _validate_latlng(_lat, _lng)

      self.lat = _lat
      self.lng = _lng
      self.geohash
      self
    end


    def inspect
      "<%s lat:%s lng:%s geohash:%s>" % [
        (self.class.name || 'Point').gsub(/.*::/, ''),
        lat(false) ? ("%.3f" % lat(false)) : 'nil',
        lng(false) ? ("%.3f" % lng(false)) : 'nil',
        geohash(false) ? ("%016x" % geohash(false)) : 'nil'
      ]
    end


    private


    def _validate_latlng(_lat, _lng)
      raise ArgumentError, 'bad lat' unless ( -90.0 ...  90.0).include?(_lat)
      raise ArgumentError, 'bad lng' unless (-180.0 ... 180.0).include?(_lng)
    end


    # Convert the geohash into lat/lng
    def _update_latlng
      geohash = self.geohash(false)
      return [nil,nil] if geohash.nil?
      raise ArgumentError, 'bad hash' unless (0 ... (1<<64)).include?(geohash)

      lat,lng = _deinterleave_bits(geohash)
      lat = lat * 180.0 / (1<<32) -  90.0
      lng = lng * 360.0 / (1<<32) - 180.0
      self.send(:lat=, lat, false)
      self.send(:lng=, lng, false)

      [lat, lng]
    end


    def _update_geohash
      lat = self.lat(false)
      lng = self.lng(false)
      return nil if lat.nil? || lng.nil?
      _validate_latlng(lat, lng)
      normalized_lat = ((lat +  90.0) * (1<<32) / 180.0).to_i
      normalized_lng = ((lng + 180.0) * (1<<32) / 360.0).to_i
      geohash = _interleave_bits(normalized_lat, normalized_lng)
      self.send(:geohash=, geohash, false)
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


  class Point
    module Fields
      attr_accessor :lat, :lng, :geohash
    end
    include Fields
    include PointTrait

    def initialize(geohash=nil)
      self.geohash = geohash
    end
  end
end
