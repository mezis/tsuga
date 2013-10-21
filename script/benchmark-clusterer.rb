#!/usr/bin/env ruby

require 'bundler/setup'
require 'perftools'
require 'benchmark'
require 'zlib'
require 'yaml'
require 'csv'
require 'pry'
require 'ostruct'
require 'tsuga/adapter/memory/test'
require 'tsuga/adapter/sequel/test'
require 'tsuga/adapter/mongoid/test'
require 'tsuga/service/clusterer'

ENV['CPUPROFILE_FREQUENCY'] ||= '500'

LIMIT        = ENV.fetch('LIMIT', '200').to_i
SOURCE       = ENV.fetch('SOURCE', 'doc/barcelona.csv.gz')
ADAPTER_NAME = ENV.fetch('ADAPTER','mysql')

case ADAPTER_NAME
when /memory/i
  Adapter = Tsuga::Adapter::Memory::Test
when /mysql/i
  DB      = Sequel.connect 'mysql2://root@localhost/tsuga'
  Adapter = Tsuga::Adapter::Sequel::Test
when /mongo/i
  Adapter = Tsuga::Adapter::Mongoid::Test
else
  puts 'specify an ADAPTER'
  exit 1
end

Clusters = Adapter.clusters
Records  = Adapter.records

RAW_PROFILE = "tmp/profile_#{ENV['ADAPTER']}"
PDF_PROFILE = "#{RAW_PROFILE}.pdf"

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
PerfTools::CpuProfiler.start(RAW_PROFILE) do
  begin
    Tsuga::Service::Clusterer.new(source: Records, adapter: Clusters).run
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

__END__

100,000 random records:
  real  110m17.156s
  user  83m0.333s
  sys 8m34.427s

10,000 real records (properties)
  122.76 real
   92.49 user
    7.50 sys

20,000 real records (properties)
  239.47 real
   176.16 user
    15.94 sys

