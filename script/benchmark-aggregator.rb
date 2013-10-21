#!/usr/bin/env ruby
require 'bundler/setup'
require 'perftools'
require 'benchmark'
require 'tsuga/adapter/memory/test'
require 'tsuga/adapter/sequel/test'
require 'tsuga/adapter/mongoid/test'
require 'tsuga/service/aggregator'
require 'pry'
require 'pry-nav'

COUNT = ENV.fetch('COUNT', '100').to_i
ENV['CPUPROFILE_FREQUENCY'] ||= '500'

case ENV['ADAPTER']
when /memory/i
  Cluster = Tsuga::Adapter::Memory::Test.clusters
when /mysql/i
  DB = Sequel.connect 'mysql2://root@localhost/tsuga'
  Cluster = Tsuga::Adapter::Sequel::Test.clusters
when /mongo/i
  Cluster = Tsuga::Adapter::Mongoid::Test.clusters
else
  puts 'specify an ADAPTER'
  exit 1
end

RAW_PROFILE = "tmp/profile_#{ENV['ADAPTER']}"
PDF_PROFILE = "#{RAW_PROFILE}.pdf"

def new_cluster(depth, lat, lng)
  Cluster.new.tap do |cluster|
    cluster.depth = depth
    cluster.set_coords(lat,lng)
    cluster.weight  = 1
    cluster.sum_lat = lat
    cluster.sum_lng = lng
    cluster.children_ids = []
    # cluster.persist!
  end
end


PerfTools::CpuProfiler.start(RAW_PROFILE) do
  begin
    10.times do |idx|
      Cluster.delete_all
      lat_max = 45 - 1e-4
      lng_max = 90 - 1e-4
      clusters = (1..COUNT).map { new_cluster(2, rand*lat_max, rand*lng_max) }

      runtime = Benchmark.measure do
        Tsuga::Service::Aggregator.new(clusters).run
      end
      puts "run #{idx}: #{runtime}"
    end
  rescue Exception => e
    puts "caught #{e.class.name} (#{e.message})"
    if ENV['DEBUG']
      binding.pry
    else
      puts "set DEBUG next time to inspect"
    end
    $failure = true
  end
end

unless $failure
  system "pprof.rb --pdf #{RAW_PROFILE} > #{PDF_PROFILE}"
  system "open #{PDF_PROFILE}"
end
