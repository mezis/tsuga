require 'tsuga/model/cluster'
require 'tsuga/model/tile'
require 'tsuga/adapter/active_record/base'

module Tsuga::Adapter::ActiveRecord
  module Cluster
    def self.included(by)
      by.send :include, Base
      by.send :include, Tsuga::Model::Cluster
      by.extend Scopes
    end

    def children_ids
      @_children_ids ||= begin
        stored = super
        stored ? stored.split(',').map(&:to_i) : []
      end
    end

    def children_ids=(value)
      changed = (@_children_ids != value)
      @_children_ids = value
      super(@_children_ids.join(',')) if changed
      @_children_ids
    end

    module Scopes
      def at_depth(depth)
        where(depth: depth)
      end

      # FIXME: this also is redundant with the mongoid adapter implementation
      def in_tile(*tiles)
        depths = tiles.map(&:depth).uniq
        raise ArgumentError, 'all tile must be at same depth' if depths.length > 1
        codes = tiles.map { |t| "%016x" % t.code }
        where(depth: depths.first, tilecode: codes)
      end

      def in_viewport(sw:nil, ne:nil, depth:nil)
        tiles = Tsuga::Model::Tile.enclosing_viewport(point_sw: sw, point_ne: ne, depth: depth)
        in_tile(*tiles)
      end
    end
  end
end

