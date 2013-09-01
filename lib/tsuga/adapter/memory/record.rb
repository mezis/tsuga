require 'tsuga/model/record'
require 'tsuga/adapter/memory/base'

module Tsuga::Adapter::Memory
  class Record 
    include Base
    include Tsuga::Model::Record
    attr_accessor :geohash, :lat, :lng
  end
end
