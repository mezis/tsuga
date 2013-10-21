class ClustersController < ApplicationController

  # GET /clusters
  # GET /clusters.json
  def index
    @clusters = Cluster.all
  end

end
