require 'set'
require 'tsuga/model/point'
require 'tsuga/model/tile'

module Tsuga::Service

  # Aggregates clusters together until no two clusters are closer than
  # a given minimum distance.
  class Aggregator
    def initialize(clusters)
      @_clusters = clusters.dup
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
        _clusters.delete(right)
        to_delete << right
        to_persist << left.id

        # create new pairs
        _clusters.each do |cluster|
          next if cluster == left
          pairs << Pair.new(left, cluster)
        end
      end

      # persistence
      _clusters.each { |c| c.persist! if to_persist.include?(c.id) }
      to_delete.each { |c| c.destroy }
      nil
    end

    # 1/5th of the diagonal of a tile
    def min_distance
      @min_distance ||= begin
        depth = _clusters.first.depth
        point = Tsuga::Model::Point.new.set_coords(0,0)
        tile  = Tsuga::Model::Tile.including(point, :depth => depth)
        (tile.northwest & tile.southeast) * 0.2
      end
    end

    private

    attr_reader :_clusters

    class SortedSet < ::SortedSet
      def pop
        first.tap { |item| delete(item) }
      end
    end

    # model a pair of clusters such as [a,b] == [b,a]
    # and comparison is based on distance
    class Pair
      include Comparable
      attr_reader :distance

      def initialize(c1, c2)
        @left  = c1
        @right = c2
        @distance = (@left & @right)
      end

      def <=>(other)
        self.distance <=> other.distance
      end

      def values
        [@left, @right]
      end

      def has?(c)
        (@left.id == c.id) || (@right.id == c.id)
      end

      def hash
        [@left.id, @right.id].sort.hash
      end
    end
  end
end
