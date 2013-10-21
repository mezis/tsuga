module Tsuga
  MIN_DEPTH = 3
  MAX_DEPTH = 19
  
  def self.Point(*args)
    require 'tsuga/model/point'
    Tsuga::Model::Point.new(*args)
  end
end

require "tsuga/version"
