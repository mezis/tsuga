require 'set'
require 'tsuga/errors'
require 'tsuga/adapter'

module Tsuga::Adapter::Memory
  # A memory-backed activerecord pattern implementation.
  # Makes my test fly like crazy.
  module Base

    def self.included(by)
      by.send :attr_reader, :id
      by.extend ClassMethods
    end


    def initialize(*args)
      super(*args)
    end


    def persist!
      @id ||= self.class.generate_id
      self.class._records[id] = self.clone
      self
    end

    def destroy
      self.class._records.delete(id)
      @id = nil
      self
    end


    module ClassMethods
      # FIXME: not thread safe. not sure we care, either.
      def generate_id
        @_last_id ||= 0
        @_last_id += 1
      end

      def find_by_id(id)
        _records.fetch(id) { raise Tsuga::RecordNotFound }.clone
      end

      def scoped(*filters)
        Scope.new(self, filters)
      end

      def delete_all
        _records.replace Hash.new
      end

      def find_each
        _records.dup.each_value { |r| yield r.clone }
      end

      def collect_ids
        Set.new(_records.keys)
      end

      def _records
        @_records ||= {}
      end
    end # ClassMethods


    class Scope
      attr_reader :_filters
      attr_reader :_origin

      def initialize(origin, filters)
        @_origin  = origin
        @_filters = filters
      end

      def scoped(*filters)
        Scope.new(_origin, _filters + filters)
      end

      def find_by_id(id)
        _origin.find_by_id(id).tap do |record|
          raise Tsuga::RecordNotFound unless _matches?(record)
        end
      end

      def delete_all
        _origin._records.each_pair do |id,record|
          next unless _matches?(record)
          _origin._records.delete(id)
        end
      end

      def find_each
        _origin._records.dup.each_value do |record| 
          next unless _matches?(record)
          yield record.clone
        end
      end

      def collect_ids
        Set.new.tap do |result|
          _origin._records.each_value do |record| 
            next unless _matches?(record)
            result << record.id
          end
        end
      end

      def method_missing(method, *args)
        result = _origin.send(method, *args)
        result = scoped(*(result._filters)) if result.kind_of?(Scope)
      end

      def respond_to?(method, include_private=false)
        super || _origin.respond_to?(method, include_private)
      end

      private 

      def _matches?(record)
        _filters.all? { |f| f.call(record) }
      end
    end # Scope

  end
end
