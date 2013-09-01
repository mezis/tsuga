#!/usr/bin/env ruby
ENV['CPUPROFILE_FREQUENCY'] = '500'

require 'bundler/setup'
require 'perftools'
require 'benchmark'
require 'tsuga/adapter/memory_adapter'
require 'tsuga/service/aggregator'

Clusters = Tsuga::Adapter::MemoryAdapter.clusters

def new_cluster(depth, lat, lng)
  Clusters.new.tap do |cluster|
    cluster.depth = depth
    cluster.set_coords(lat,lng)
    cluster.weight  = 1
    cluster.sum_lat = lat
    cluster.sum_lng = lng
    cluster.children_ids = []
    cluster.persist!
  end
end

PerfTools::CpuProfiler.start("tmp/profile") do
  10.times do |idx|
    Tsuga::Adapter::MemoryAdapter.clusters.delete_all
    lat_max = 45 - 1e-4
    lng_max = 90 - 1e-4
    clusters = (1..150).map { new_cluster(2, rand*lat_max, rand*lng_max) }

    runtime = Benchmark.measure do
      Tsuga::Service::Aggregator.new(clusters).run
    end
    puts "run #{idx}: #{runtime}"
  end
end

system "pprof.rb --pdf tmp/profile > tmp/profile.pdf"
system "open tmp/profile.pdf"