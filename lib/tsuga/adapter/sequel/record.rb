require 'tsuga/model/record'
require 'tsuga/adapter/sequel/base'

module Tsuga::Adapter::Sequel
  module Record
    def self.included(by)
      by.send :include, Base
      by.send :include, Tsuga::Model::Record
      by.dataset_module Scopes
    end

    module Scopes
    end
  end
end
