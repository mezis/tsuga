require 'tsuga/errors'
require 'tsuga/adapter'
require 'sequel'
require 'delegate'

module Tsuga::Adapter::Sequel
  module Base
    def self.included(by)
      by.extend ClassMethods
    end

    def id
      @_id ||= super
    end

    def persist!
      save
    end

    module ClassMethods
      def find_by_id(id)
        self[id]
      end

      def delete_all
        where.delete
      end

      def collect_ids
        map(:id)
      end

      def find_each
        where.each_page(2000) do |page|
          page.each { |r| yield r }
        end
      end

      def wrapped_dataset
        SimpleDelegator.new(yield).tap do |scope|
          scope.extend(ClassMethods)
          scope.extend(self::Scopes) if defined?(self::Scopes)
        end
      end
    end
  end
end

