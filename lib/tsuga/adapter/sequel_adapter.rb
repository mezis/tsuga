require 'tsuga/adapter/base'
require 'sequel'
require 'sqlite3'

module Tsuga::Adapter
  class SequelAdapter < Base
    def initialize(url = nil)
      @_connection = url ? ::Sequel.connect(url) : ::Sequel.sqlite
      @_connection.extension(:pagination)
    end

    def records
      ensure_schema
      require 'tsuga/adapter/sequel/record'
      Tsuga::Adapter::Sequel::Record
    end

    def clusters
      ensure_schema
      require 'tsuga/adapter/sequel/cluster'
      Tsuga::Adapter::Sequel::Cluster
    end

    private

    def ensure_schema
      @_connection.create_table?(:records) do
        primary_key :id
        BigDecimal  :geohash, :size => 21
        Float       :lat
        Float       :lng

        index       :geohash
      end

      @_connection.create_table?(:clusters) do
        primary_key :id
        BigDecimal  :geohash, :size => 21
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
    end
  end
end
