require 'tsuga/model/record'
require 'tsuga/adapter/active_record/base'

module Tsuga::Adapter::ActiveRecord
  module Record
    def self.included(by)
      by.send :include, Base
      by.send :include, Tsuga::Model::Record
      by.extend Scopes
    end

    module Scopes
    end
  end
end
