#!/usr/bin/env ruby

require 'bundler/setup'
require 'perftools'
require 'benchmark'
require 'zlib'
require 'yaml'
require 'csv'
require 'ostruct'
require 'tsuga/adapter/memory_adapter'
require 'tsuga/adapter/sequel_adapter'
require 'tsuga/adapter/mongoid_adapter'
require 'tsuga/service/clusterer'

ENV['CPUPROFILE_FREQUENCY'] ||= '500'

LIMIT = ENV.fetch('LIMIT', '200').to_i
SOURCE = ENV.fetch('SOURCE', 'doc/barcelona.csv.gz')
ADAPTER_NAME = ENV.fetch('ADAPTER','mysql')

case ADAPTER_NAME
when /memory/i
  Adapter = Tsuga::Adapter::MemoryAdapter.new
when /mysql/i
  DB = Sequel.connect 'mysql2://root@localhost/tsuga'
  Adapter = Tsuga::Adapter::SequelAdapter.test_adapter
when /mongo/i
  Adapter = Tsuga::Adapter::MongoidAdapter.test_adapter
else
  puts 'specify an ADAPTER'
  exit 1
end
Clusters = Adapter.clusters
Records  = Adapter.records

puts 'loading records...'
data = {}
Zlib::GzipReader.open(SOURCE) do |io|
  CSV(io) do |csv|
    csv.each do |row|
      id,lng,lat = row
      data[id] = {lat:lat.to_f, lng:lng.to_f}
      break if data.size >= LIMIT
    end
  end
end

puts 'creating records...'
Records.delete_all
data.each_pair do |k,v|
  Records.new.set_coords(v[:lat], v[:lng]).persist!
end
puts " #{Records.count} records created"

puts 'profiling...'
PerfTools::CpuProfiler.start("tmp/profile") do
  Tsuga::Service::Clusterer.new(Adapter).run
end

system "pprof.rb --pdf tmp/profile > tmp/profile.pdf"
system "open tmp/profile.pdf"


__END__

100,000 random records:
  real  110m17.156s
  user  83m0.333s
  sys 8m34.427s

