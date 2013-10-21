require 'tsuga/adapter/memory/base'
require 'tsuga/adapter/memory/cluster'
require 'ostruct'

module Tsuga::Adapter::Memory
  module Test
    class << self
      def clusters
        models.clusters
      end

      def models
        @_models ||= _build_test_models
      end


      private 

      def _build_test_models

        OpenStruct.new :clusters => Class.new {
          include Tsuga::Adapter::Memory::Cluster 
        }, :records => Array
      end
    end
  end
end
