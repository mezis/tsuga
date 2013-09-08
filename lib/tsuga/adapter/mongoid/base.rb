require 'tsuga/errors'
require 'tsuga/adapter'
require 'scanf'

module Tsuga::Adapter::Mongoid
  module Base
    def self.included(by)
      by.extend ScopeMethods
    end

    # def id
    #   @_cached_id ||= begin
    #     v = super
    #     v = v.to_s.to_i(16) unless v.nil?
    #     v
    #   end
    # end

    def persist!
      save!
    end

    def geohash
      value = super
      value.kind_of?(String) ? value.to_i(16) : value
    end

    def geohash=(value)
      value = '%016x' % value if value.kind_of?(Integer)
      super(value)
    end


    module ScopeMethods
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
