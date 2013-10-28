require 'tsuga/errors'
require 'tsuga/adapter'
require 'scanf'

module Tsuga::Adapter::Mongoid
  module Base
    def self.included(by)
      by.extend ScopeMethods
    end

    def persist!
      save!
    end

    def id
      @_id ||= super
    end

    module ScopeMethods
      def mass_create(new_records)
        collection.insert(new_records.map(&:attributes))
      end

      def mass_update(records)
        records.map(&:persist!)
      end

      def find_by_id(id)
        find(id)
      end

      def collect_ids
        pluck(:id)
      end

      def find_each(&block)
        each(&block)
      end
    end
  end
end
