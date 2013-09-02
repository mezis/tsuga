require 'tsuga/adapter/base'
require 'tsuga/adapter/memory/record'
require 'tsuga/adapter/memory/cluster'

module Tsuga::Adapter
  class MemoryAdapter < Base
    RecordNotFound = Class.new(RuntimeError)

    def records
      Tsuga::Adapter::Memory::Record
    end

    def clusters
      Tsuga::Adapter::Memory::Cluster
    end
  end
end
