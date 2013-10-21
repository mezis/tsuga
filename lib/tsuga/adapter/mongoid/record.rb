require 'tsuga/model/record'
require 'tsuga/adapter/mongoid/base'
require 'mongoid'

module Tsuga::Adapter::Mongoid
  module Record
    def self.included(by)
      by.send :include, Base
      by.send :include, Tsuga::Model::Record
      by.extend ScopeMethods
    end

    module ScopeMethods
    end
  end
end
