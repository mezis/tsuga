#!/usr/bin/env ruby
ENV['CPUPROFILE_FREQUENCY'] = '500'

require 'bundler/setup'
require 'perftools'
require 'benchmark'
require 'zlib'
require 'yaml'
require 'tsuga/adapter/memory_adapter'
require 'tsuga/adapter/sequel_adapter'
require 'tsuga/service/clusterer'

Limit = ENV.fetch('LIMIT', '200').to_i

# Adapter = Tsuga::Adapter::MemoryAdapter.new

DB = Sequel.connect 'mysql2://root@localhost/tsuga'
Adapter = Tsuga::Adapter::SequelAdapter.test_adapter

Records = Adapter.records

puts 'loading records...'
raw = File.open('doc/places.yml.gz', 'r') { |io| Zlib::GzipReader.new(io).read }
data = YAML.load(raw)

puts 'creating records...'
Records.delete_all
total = 0
data.each_pair do |k,v|
  Records.new.set_coords(v[:lat], v[:lng]).persist!
  # r = Records.new.set_coords(rand, rand)
  # require 'pry' ; require 'pry-nav' ; binding.pry
  # r.persist!
  total += 1
  break if total >= Limit
end
puts " #{Records.count} records created"

# require 'pry' ; require 'pry-nav' ; binding.pry

puts 'profiling...'
# PerfTools::CpuProfiler.start("tmp/profile") do
  Tsuga::Service::Clusterer.new(Adapter).run
# end

# system "pprof.rb --pdf tmp/profile > tmp/profile.pdf"
# system "open tmp/profile.pdf"


__END__

100,000 records:
  real  110m17.156s
  user  83m0.333s
  sys 8m34.427s

