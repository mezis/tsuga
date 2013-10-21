require 'tsuga/errors'
require 'tsuga/adapter'
require 'sequel'
require 'delegate'

module Tsuga::Adapter::Sequel
  module Base
    def self.included(by)
      by.dataset_module DatasetMethods
    end

    def id
      @_id ||= super
    end

    def persist!
      save
    end

    module DatasetMethods
      def mass_create(new_records)
        multi_insert(new_records.map(&:to_hash))
      end

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
        # TODO: pagination would be nice to have here, but seems not to
        # work out-of-the-box with Sequel
        # where.extension(:pagination).each_page(2000) do |page|
        #   page.each { |r| yield r }
        # end
        all.each { |r| yield r }
      end
    end
  end
end
