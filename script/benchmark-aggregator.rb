#!/usr/bin/env ruby
ENV['CPUPROFILE_FREQUENCY'] = '500'

require 'bundler/setup'
require 'perftools'
require 'benchmark'
require 'tsuga/adapter/memory_adapter'
require 'tsuga/adapter/sequel_adapter'
require 'tsuga/service/aggregator'

# Adapter = Tsuga::Adapter::MemoryAdapter.new

DB = Sequel.connect 'mysql2://root@localhost/tsuga'
Adapter = Tsuga::Adapter::SequelAdapter.test_adapter

def new_cluster(depth, lat, lng)
  Adapter.clusters.new.tap do |cluster|
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
    Adapter.clusters.delete_all
    lat_max = 45 - 1e-4
    lng_max = 90 - 1e-4
    clusters = (1..300).map { new_cluster(2, rand*lat_max, rand*lng_max) }

    runtime = Benchmark.measure do
      Tsuga::Service::Aggregator.new(clusters).run
    end
    puts "run #{idx}: #{runtime}"
  end
end

system "pprof.rb --pdf tmp/profile > tmp/profile.pdf"
system "open tmp/profile.pdf"