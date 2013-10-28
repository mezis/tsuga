require 'tsuga/adapter'
require 'active_record'

module Tsuga::Adapter::ActiveRecord
  module Migration
    def self.included(by)
      by.extend(ClassMethods)
    end

    def up
      create_table _clusters_table_name do |t|
        t.string  :tilecode,       limit:32
        t.integer :depth,          limit:1
        t.string  :geohash,        limit:32
        t.float   :lat
        t.float   :lng
        t.integer :weight
        t.integer :parent_id
        t.string  :children_type
        t.text    :children_ids
        t.float   :sum_lat,        limit:53
        t.float   :sum_lng,        limit:53
        t.float   :ssq_lat,        limit:53
        t.float   :ssq_lng,        limit:53
      end

      add_index _clusters_table_name, :tilecode, using: :hash
    end

    def down
      drop_table _clusters_table_name
    end

    private

    def _clusters_table_name
      self.class.clusters_table_name
    end

    module ClassMethods
      def clusters_table_name=(custom_name)
        @clusters_table_name = custom_name
      end

      def clusters_table_name
        @clusters_table_name ||= :clusters
      end
    end
  end
end