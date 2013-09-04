require 'tsuga/adapter/base'
require 'tsuga/adapter/sequel/record'
require 'tsuga/adapter/sequel/cluster'
require 'tsuga/adapter/sequel/test'

module Tsuga::Adapter
  class SequelAdapter < Base
    def initialize(options = {})
      @_clusters_model = options.fetch :clusters
      @_records_model  = options.fetch :records
    end

    def records
      @_records ||= begin
        Class.new(@_records_model) do
          include Sequel::Base
          include Sequel::Record
          include Tsuga::Model::Record
        end
      end
    end

    def clusters
      @_clusters ||= begin
        Class.new(@_clusters_model) do
          include Sequel::Base
          include Sequel::Cluster
          include Tsuga::Model::Cluster
        end
      end
    end

    def self.test_adapter
      @_test_adapter ||= begin
        new(
          :clusters => Sequel::Test.models.clusters,
          :records  => Sequel::Test.models.records)
      end
    end

  end
end
