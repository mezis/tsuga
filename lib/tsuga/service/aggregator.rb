require 'set'
require 'tsuga/model/point'
require 'tsuga/model/tile'

module Tsuga::Service

  # Aggregates clusters together until no two clusters are closer than
  # a given minimum distance.
  class Aggregator
    # - clusters (Array): list of points to aggregate
    # - fence (Tile): clusters outside this will not be aggregated
    # - ratio (0..1): minimum distance between clusters after aggregation,
    #   as a ratio of the tile diagonal
    def initialize(clusters:nil, ratio:nil, fence:nil)
      @_clusters          = clusters
      @_fence             = fence || _default_fence
      @min_distance_ratio = ratio # fraction of tile diagonal
      @_dropped_clusters   = IdSet.new
      @_updated_clusters   = IdSet.new
    end

    def run
      return if _clusters.empty?
      warn "warning: running aggregation on many clusters (#{_clusters.size})" if _clusters.size > 100

      if DENSITY_BIAS_FACTOR
        @min_density, @max_density = _clusters.collect(&:density).minmax
      end

      # build the set of pairs (n²/2)
      pairs  = []
      source = _clusters.dup
      while left = source.pop
        source.each do |right| 
          pairs << _build_pair(left, right, _fence)
        end
      end

      # pop & merge
      while pairs.any?
        best_pair = pairs.min
        break if best_pair.distance > min_distance

        # remove the closest pair
        left, right = best_pair.values
        left_id  = left.id
        right_id = right.id

        # remove pairs containing one of the items
        pairs.delete_if { |p| p.has?(left) || p.has?(right) }

        # merge clusters
        left.merge(right)
        _clusters.delete_if { |c| c.id == right_id }
        _updated_clusters.remove right
        _dropped_clusters.add    right
        _updated_clusters.add    left

        # create new pairs
        _clusters.each do |cluster|
          next if cluster.id == left_id
          pairs << _build_pair(left, cluster, _fence)
        end
      end
      nil
    end

    # after #run, this contains the clusters that were merged into other clusters
    def dropped_clusters
      _dropped_clusters.to_a
    end

    # after #run, this contains the clusters that were modified and need to be persisted
    def updated_clusters
      _updated_clusters.to_a
    end

    # fraction of the diagonal of the fence tile
    def min_distance
      @min_distance ||= (_fence.southwest & _fence.northeast) * @min_distance_ratio
    end

    private

    # FIXME: a sensible value would be ~0.4 in theory, but this
    # biasing seems to have little impact. remove?
    DENSITY_BIAS_FACTOR = nil

    attr_reader :_clusters, :_fence, :_dropped_clusters, :_updated_clusters

    # factory for pairs, switches between fenced/unfenced
    # and conditionnaly adds density bias
    def _build_pair(c1, c2, fence)
      pair = fence.nil? ? Pair.new(c1, c2) : FencedPair.new(c1, c2, fence)

      if DENSITY_BIAS_FACTOR && (@max_density != @min_density)
        # the least dense cluster pairs have a density_bias value close to 0, the densest closer to 1
        density_bias = (c1.density + c2.density - 2 * @min_density) / (2 * (@max_density - @min_density))
        # this makes dense clusters appear closer, and vice-versa
        pair.distance = pair.distance * (1 + DENSITY_BIAS_FACTOR * (1 - density_bias) - 0.5 * DENSITY_BIAS_FACTOR)
      end
      pair
    end

    def _default_fence
      return if _clusters.empty?
      Tsuga::Model::Tile.including(_clusters.first, depth:_clusters.first.depth)
    end

    # model a pair of clusters such as [a,b] == [b,a]
    # and comparison is based on distance
    class Pair
      include Comparable
      attr_accessor :distance

      def initialize(c1, c2)
        @left     = c1
        @right    = c2
        @left_id  = c1.id
        @right_id = c2.id
        @distance = (@left & @right)

        raise ArgumentError, 'pair elements must be distinct' if @left_id == @right_id
      end

      def <=>(other)
        self.distance <=> other.distance
      end

      # def ==(other)
      #   (self.left_id == other.left_id) && (self.right_id == other.right_id)
      # end

      def values
        [@left, @right]
      end

      def has?(c)
        c_id = c.id
        (@left_id == c_id) || (@right_id == c_id)
      end
    end

    # pairs where both points fall outside the fence are considered "at horizon"
    # i.e. their distance infinite. the point is to never aggregate them.
    class FencedPair < Pair
      def initialize(c1, c2, fence)
        super(c1, c2)
        @outside = !fence.contains?(c1) && !fence.contains?(c2)
      end

      def distance
        @outside ? Float::MAX : super
      end
    end

    class IdSet
      def initialize
        @data = {}
      end

      def add(item)
        @data[item.id] = item
      end

      def remove(item)
        @data.delete(item.id)
      end

      def to_a
        @data.values
      end
    end
  end
end
