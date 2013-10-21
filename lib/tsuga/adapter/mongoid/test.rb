require 'tsuga/adapter/mongoid/base'
require 'tsuga/adapter/mongoid/cluster'
require 'tsuga/adapter/mongoid/record'
require 'mongoid'
require 'ostruct'
require 'forwardable'

module Tsuga::Adapter::Mongoid
  module Test
    class << self
      extend Forwardable
      delegate [:records, :clusters] => :models

      def models
        @_models ||= _build_test_models
      end


      private 


      def _build_test_models
        ::Mongoid.load!("spec/support/mongoid.yml", :test)
        _cluster_model.create_indexes
        _record_model.create_indexes

        # FIXME: hardly elegant but Mongoid insists on a named class.
        self.const_set :Cluster, _cluster_model
        self.const_set :Record,  _record_model

        OpenStruct.new :clusters => _cluster_model, :records => _record_model
      end


      def _cluster_model
        @_cluster_model ||= Class.new do
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
          field :ssq_lat
          field :ssq_lng
          field :weight

          store_in :collection => 'clusters'
          index depth:1, geohash:1

          include Tsuga::Adapter::Mongoid::Cluster
        end
      end


      def _record_model
        @_record_model ||= Class.new do
          include Mongoid::Document

          field :geohash
          field :lat
          field :lng

          store_in :collection => 'records'
          index geohash:1

          include Tsuga::Adapter::Mongoid::Record
        end
      end
    end
  end
end
