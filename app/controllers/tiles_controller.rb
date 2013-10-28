require 'tsuga/model/tile'
require 'tsuga/model/point'

class TilesController < ApplicationController

  # GET /tiles
  # GET /tiles.json?
  def index
    sw = Tsuga::Point(lat: params['s'].to_f, lng: params['w'].to_f)
    ne = Tsuga::Point(lat: params['n'].to_f, lng: params['e'].to_f)

    depth = params['z'].to_i - 1

    # find clusters
    @tiles = Tsuga::Model::Tile
      .enclosing_viewport(point_sw: sw, point_ne: ne, depth: depth)
  end

end
