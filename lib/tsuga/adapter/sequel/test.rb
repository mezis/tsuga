require 'tsuga/adapter/sequel/base'
require 'tsuga/adapter/sequel/cluster'
require 'tsuga/adapter/sequel/record'
require 'sequel'
require 'sqlite3'
require 'ostruct'
require 'forwardable'

module Tsuga::Adapter::Sequel
  module Test
    class << self
      extend Forwardable
      delegate [:records, :clusters] => :models

      def models
        @_models ||= _build_test_models
      end

      private

      # Makes sure a connection exists
      def _db
        @_db ||= Sequel::DATABASES.first || Sequel.sqlite
      end

      def _prepare_tables
        _db.drop_table?(:test_records)
        _db.create_table(:test_records) do
          primary_key :id
          BigDecimal  :geohash, size:21
          Float       :lat
          Float       :lng

          index       :geohash
        end

        _db.drop_table?(:test_clusters)
        _db.create_table(:test_clusters) do
          primary_key :id
          Integer     :depth
          BigDecimal  :geohash,  size:21
          BigDecimal  :tilecode, size:21
          Float       :lat
          Float       :lng
          Integer     :parent_id
          String      :children_type
          String      :children_ids # FIXME
          Double      :sum_lat
          Double      :sum_lng
          Double      :ssq_lat
          Double      :ssq_lng
          Integer     :weight

          index       :tilecode
        end
      end

      def _build_test_models
        _prepare_tables

        cluster_model = Class.new(Sequel::Model(:test_clusters)) do
          include Tsuga::Adapter::Sequel::Cluster
        end

        record_model = Class.new(Sequel::Model(:test_records)) do
          include Tsuga::Adapter::Sequel::Record
        end

        OpenStruct.new :clusters => cluster_model, :records => record_model
      end
    end
  end
end
