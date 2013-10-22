require 'ostruct'

class ClustersController < ApplicationController

  # GET /clusters
  # GET /clusters.json?
  def index
    sw = Tsuga::Point(lat: params['s'].to_f, lng: params['w'].to_f)
    ne = Tsuga::Point(lat: params['n'].to_f, lng: params['e'].to_f)

    # find clusters
    @clusters = Cluster.in_viewport(sw: sw, ne: ne, depth: params['z'].to_i)
  end

end
