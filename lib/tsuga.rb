module Tsuga
  def self.Point(*args)
    require 'tsuga/model/point'
    Tsuga::Model::Point.new(*args)
  end
end

require "tsuga/version"
