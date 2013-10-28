require 'tsuga/adapter/active_record/base'
require 'tsuga/adapter/active_record/cluster'
require 'tsuga/adapter/active_record/record'
require 'tsuga/adapter/active_record/migration'
require 'active_record'
require 'sqlite3'
require 'ostruct'
require 'forwardable'
require 'yaml'

module Tsuga::Adapter::ActiveRecord
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
        @_db ||= begin
          unless ActiveRecord::Base.connected?
            ActiveRecord::Base.establish_connection(adapter:'sqlite3', database:':memory:')
          end
          ActiveRecord::Base.connection
        end
      end

      def _prepare_tables
        _db.drop_table(:test_records) if _db.table_exists?(:test_records)
        _db.create_table(:test_records) do |t|
          t.string   :geohash, limit:32
          t.float    :lat
          t.float    :lng
        end
        _db.add_index :test_records, :geohash

        _db.drop_table(:test_clusters) if _db.table_exists?(:test_clusters)
        Migration.new.tap { |m| m.verbose = false ; m.up }
      end

      def _build_test_models
        _prepare_tables

        cluster_model = Class.new(ActiveRecord::Base) do
          self.table_name = 'test_clusters'
          include Tsuga::Adapter::ActiveRecord::Cluster

          def run_callbacks(*args)
            yield if block_given?
          end
        end

        record_model = Class.new(ActiveRecord::Base) do
          self.table_name = 'test_records'
          include Tsuga::Adapter::ActiveRecord::Record
        end

        OpenStruct.new :clusters => cluster_model, :records => record_model
      end

      class Migration < ActiveRecord::Migration
        include Tsuga::Adapter::ActiveRecord::Migration
        self.clusters_table_name = :test_clusters
      end
    end

  end
end
