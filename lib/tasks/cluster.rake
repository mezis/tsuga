require 'tsuga/service/clusterer'

namespace :tsuga do
  desc 'run clustering on points in database'
  task :cluster => :environment do
    Cluster.delete_all
    Tsuga::Service::Clusterer.new(source: Point, adapter: Cluster).run
  end
end
