require 'sqlite3'
require 'ostruct'

module Tsuga::Adapter::Mongoid
  module Test
    class << self
      def models
        @_models ||= build_test_models
      end

      private 

      def build_test_models
        ::Mongoid.load!("spec/support/mongoid.yml", :test)

        cluster_model = Class.new do
          include Mongoid::Document

          field :geohash
          field :lat
          field :lng
          field :depth
          field :parent_id
          field :children_type
          field :children_ids
          field :sum_lat
          field :sum_lng
          field :weight

          store_in :collection => 'clusters'
          index depth:1, geohash:1
        end

        record_model = Class.new do
          include Mongoid::Document

          field :geohash
          field :lat
          field :lng

          store_in :collection => 'records'
          index geohash:1
        end

        cluster_model.create_indexes
        record_model.create_indexes
        OpenStruct.new :clusters => cluster_model, :records => record_model
      end
    end
  end
end
