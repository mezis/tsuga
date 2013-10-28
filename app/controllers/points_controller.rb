require 'ostruct'

class PointsController < ApplicationController

  # GET /clusters
  # GET /clusters.json?
  def index
    n = params['n'].to_f
    s = params['s'].to_f
    e = params['e'].to_f
    w = params['w'].to_f

    # find clusters
    @points = Point
      .where('lat BETWEEN ? AND ?', s, n)
      .where('lng BETWEEN ? AND ?', w, e)
  end

end
