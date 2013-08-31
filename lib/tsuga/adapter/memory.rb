require 'tsuga/adapter/base'
require 'tsuga/model/record'
require 'tsuga/model/cluster'

module Tsuga::Adapter
  class Memory < Base

    module ClassMethods
      def records
        Tsuga::Adapter::Memory::Record
      end

      def clusters
        Tsuga::Adapter::Memory::Cluster
      end
    end

    extend ClassMethods

    module MemoryPersistedRecord
      def self.included(by)
        by.send :attr_reader, :id
        by.extend ClassMethods
      end

      module ClassMethods
        def records
          @_records ||= {}
        end

        def generate_id
          @_last_id ||= 0
          @_last_id += 1
        end

        def find(id)
          records[id]
        end

        def delete_all
          records.replace Hash.new
        end
      end

      def initialize(*args)
        super(*args)
        @id = self.class.generate_id
      end

      def persist!
        self.class.records[id] = self
      end

      def self.find_each
        self.class.records.each_value { |r| yield r.clone }
      end

    end

    class Record 
      include MemoryPersistedRecord
      include Tsuga::Record
      attr_accessor :geohash, :lat, :lng
    end

    class Cluster
      include MemoryPersistedRecord
      include Tsuga::Cluster
      attr_accessor :geohash, :lat, :lng, :depth, :parent_id, :children_ids, :sum_lat, :sum_lng
    end
  end
end
