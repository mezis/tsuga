require 'tsuga/adapter/base'
require 'tsuga/adapter/mongoid/record'
require 'tsuga/adapter/mongoid/cluster'
require 'tsuga/adapter/mongoid/test'

module Tsuga::Adapter
  class MongoidAdapter < Base
    def initialize(options = {})
      @_clusters_model = options.fetch :clusters
      @_records_model  = options.fetch :records
    end

    def records
      @_records ||= begin
        Class.new(@_records_model) do
          include Mongoid::Base
          include Mongoid::Record
          include Tsuga::Model::Record
        end
      end
    end

    def clusters
      @_clusters ||= begin
        Class.new(@_clusters_model) do
          include Mongoid::Base
          include Mongoid::Cluster
          include Tsuga::Model::Cluster
        end
      end
    end

    def self.test_adapter
      @_test_adapter ||= begin
        new(
          :clusters => Mongoid::Test.models.clusters,
          :records  => Mongoid::Test.models.records)
      end
    end

  end
end
