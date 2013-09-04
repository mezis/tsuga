require 'sequel'
require 'sqlite3'
require 'ostruct'

module Tsuga::Adapter::Sequel
  module Test
    class << self
      def models
        @_models ||= build_test_models
      end

      def build_test_models
        # Make sure a connection exists
        Sequel::DATABASES.first || Sequel.sqlite
        
        cluster_model = Sequel::Model(:test_clusters)
        record_model  = Sequel::Model(:test_records)
        db = cluster_model.db

        db.drop_table?(record_model.table_name)
        db.create_table(record_model.table_name) do
          primary_key :id
          Bignum      :geohash
          Float       :lat
          Float       :lng

          index       :geohash
        end

        db.drop_table?(cluster_model.table_name)
        db.create_table(cluster_model.table_name) do
          primary_key :id
          Bignum      :geohash
          Float       :lat
          Float       :lng
          Integer     :depth
          Integer     :parent_id
          String      :children_type
          String      :children_ids # FIXME
          Float       :sum_lat
          Float       :sum_lng
          Integer     :weight

          index       [:depth, :geohash]
        end

        record_model.set_dataset  record_model.table_name
        cluster_model.set_dataset cluster_model.table_name

        OpenStruct.new :clusters => cluster_model, :records => record_model
      end
    end
  end
end