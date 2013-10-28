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


    def geohash=(value)
      super(value)
      _updating_coords { _set_latlng_from_geohash }
      geohash
    end


    def lat=(value)
      _validate_lat(value) if value
      super(value)
      _updating_coords { _set_geohash_from_latlng }
      lat
    end


    def lng=(value)
      _validate_lng(value) if value
      super(value)
      _updating_coords { _set_geohash_from_latlng }
      lng
    end


    def inspect
      "<%s lat:%s lng:%s geohash:%s>" % [
        (self.class.name || 'Point').gsub(/.*::/, ''),
        lat ? ("%.3f" % lat) : 'nil',
        lng ? ("%.3f" % lng) : 'nil',
        geohash ? geohash : 'nil'
      ]
    end

    def prefix(depth)
      geohash[0...depth]
    end

    private

    # only the outmost call yields.
    # prevents infinite loops of latlng <-> geohash updates
    def _updating_coords
      return if @_updating
      @_updating = true
      yield
      @_updating = false
    end


    def _validate_lat(_lat)
      raise ArgumentError, 'bad lat' unless ( -90.0 ...  90.0).include?(_lat)
    end

    def _validate_lng(_lng)
      raise ArgumentError, 'bad lng' unless (-180.0 ... 180.0).include?(_lng)
    end


    def _validate_geohash(value)
      raise ArgumentError, 'bad geohash' unless /^[0-3]{32}$/ =~ value
    end


    def _geohash_to_int(value)
      value.to_i(4)
    end

    def _int_to_geohash(value)
      value.to_s(4).rjust(32,'0')
    end

    # Convert the geohash into lat/lng
    def _set_latlng_from_geohash
      geohash = self.geohash
      if geohash.nil?
        self.lat = self.lng = nil
        return
      end
      _validate_geohash(geohash)

      geohash_i = _geohash_to_int(geohash)
      lat,lng = _deinterleave_bits(geohash_i)
      lat = lat * 180.0 / (1<<32) -  90.0
      lng = lng * 360.0 / (1<<32) - 180.0
      self.lat = lat
      self.lng = lng
      return
    end


    def _set_geohash_from_latlng
      lat = self.lat
      lng = self.lng
      if lat.nil? || lng.nil?
        self.geohash = nil
        return
      end
      _validate_lat(lat)
      _validate_lng(lng)
      normalized_lat = ((lat +  90.0) * (1<<32) / 180.0).to_i
      normalized_lng = ((lng + 180.0) * (1<<32) / 360.0).to_i

      geohash_i = _interleave_bits(normalized_lat, normalized_lng)
      self.geohash = _int_to_geohash(geohash_i)
      return
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

    def initialize(geohash: nil, lat: nil, lng: nil)
      if geohash
        self.geohash = geohash
      else
        self.lat = lat
        self.lng = lng
      end
    end
  end
end
