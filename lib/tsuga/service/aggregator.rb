require 'set'
require 'tsuga/model/point'
require 'tsuga/model/tile'

module Tsuga::Service

  # Aggregates clusters together until no two clusters are closer than
  # a given minimum distance.
  class Aggregator
    # fraction of tile diagonal
    MIN_DISTANCE_RATIO = 0.2

    def initialize(clusters)
      @_clusters = clusters
    end

    def run
      # build the set of pairs (n²/2)
      pairs  = []
      source = _clusters.dup
      while left = source.pop
        source.each do |right| 
          pairs << Pair.new(left, right)
        end
      end

      # pop & merge
      to_delete  = []
      to_persist = Set.new
      while pairs.any?
        best_pair = pairs.min
        break if best_pair.distance > min_distance

        # remove the closest pair
        left, right = best_pair.values

        # remove pairs containing one of the items
        pairs.delete_if { |p| p.has?(left) || p.has?(right) }

        # merge clusters
        left.merge(right)
        _clusters.delete_if { |c| c.object_id == right.object_id }

        # create new pairs
        _clusters.each do |cluster|
          next if cluster.object_id == left.object_id
          pairs << Pair.new(left, cluster)
        end
      end
      nil
    end

    # 1/5th of the diagonal of a tile
    def min_distance
      @min_distance ||= begin
        depth = _clusters.first.depth
        point = Tsuga::Model::Point.new.set_coords(0,0)
        tile  = Tsuga::Model::Tile.including(point, depth: depth)
        (tile.southwest & tile.northeast) * MIN_DISTANCE_RATIO
      end
    end

    private

    attr_reader :_clusters

    # model a pair of clusters such as [a,b] == [b,a]
    # and comparison is based on distance
    class Pair
      include Comparable
      attr_reader :distance

      def initialize(c1, c2)
        raise ArgumentError, 'pair elements must be distinct' if c1.object_id == c2.object_id
        @left  = c1
        @right = c2
        @distance = (@left & @right)
      end

      def <=>(other)
        self.distance <=> other.distance
      end

      def ==(other)
        (self.left.object_id == other.left.object_id) && (self.right.object_id == other.right.object_id)
      end

      def values
        [@left, @right]
      end

      def has?(c)
        (@left.object_id == c.object_id) || (@right.object_id == c.object_id)
      end
    end
  end
end
