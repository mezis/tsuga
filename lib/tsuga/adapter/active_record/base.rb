require 'tsuga/errors'
require 'tsuga/adapter'
require 'active_record'
require 'delegate'

module Tsuga::Adapter::ActiveRecord
  module Base
    def self.included(by)
      by.extend DatasetMethods
    end

    def persist!
      save
    end

    # TODO: the geohash-conversion is shared with the Mongoid adapter. Factor this out.
    def geohash
      value = super
      value.kind_of?(String) ? value.to_i(16) : value
    end

    def geohash=(value)
      value = '%016x' % value if value.kind_of?(Integer)
      super(value)
    end

    def tilecode
      value = super
      value.kind_of?(String) ? value.to_i(16) : value
    end

    def tilecode=(value)
      value = '%016x' % value if value.kind_of?(Integer)
      super(value)
    end

    module DatasetMethods
      def mass_create(new_records)
        return if new_records.empty?
        attributes = new_records.map(&:attributes)
        keys = attributes.first.keys - ['id']
        column_names = keys.map { |k| connection.quote_column_name(k) }.join(', ')
        sql = <<-SQL
          INSERT INTO #{quoted_table_name} (#{column_names}) VALUES
        SQL
        value_template = (["?"] * keys.length).join(', ')
        value_strings = attributes.map do |attrs|
          values = keys.map { |k| attrs[k] }
          sanitize_sql_array([value_template, *values])
        end
        full_sql = sql + value_strings.map { |str| "(#{str})"}.join(', ')
        connection.insert_sql(full_sql)
      end

      def collect_ids
        pluck(:id)
      end

    end
  end
end
