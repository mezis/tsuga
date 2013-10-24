require 'set'
require 'tsuga/model/point'
require 'tsuga/model/tile'

module Tsuga::Service

  # Aggregates clusters together until no two clusters are closer than
  # a given minimum distance.
  class Aggregator
    # after #run, this contains the clusters that were merged into other clusters
    attr_reader :dropped_clusters
    # after #run, this contains the clusters that were modified and need to be persisted
    attr_reader :updated_clusters

    def initialize(clusters:nil, ratio:nil)
      @_clusters = clusters
      @dropped_clusters = []
      @updated_clusters = Set.new
      @min_distance_ratio = ratio # fraction of tile diagonal
    end

    def run
      warn "running aggregation on #{_clusters.size} clusters" if _clusters.size > 50

      # build the set of pairs (n²/2)
      pairs  = []
      source = _clusters.dup
      while left = source.pop
        source.each do |right| 
          pairs << Pair.new(left, right)
        end
      end

      # pop & merge
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
        dropped_clusters << right
        updated_clusters << left

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
        (tile.southwest & tile.northeast) * @min_distance_ratio
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
