require 'spec_helper'
require 'tsuga/service/clusterer'
require 'tsuga/adapter/memory/cluster'
require 'ostruct'

describe Tsuga::Service::Clusterer do
  subject { described_class.new(source: records, adapter: adapter) }
  let(:adapter) { Class.new { include Tsuga::Adapter::Memory::Cluster } }
  let(:records) { ArrayWithFindEach.new }

  def make_record(lat, lng)
    records << OpenStruct.new(lat: lat, lng: lng)
  end

  before { adapter.delete_all }

  describe '#run' do
    context 'with no records' do
      it('passes') { subject.run }
    end

    context 'with a single record' do
      before do
        make_record(0,0)
      end

      it('passes') { subject.run }

      it 'creates 1 cluster per depth' do
        subject.run
        adapter.collect_ids.length.should == 17
      end

      it 'creates clusters with the same position' do
        subject.run
        hashes = Set.new
        adapter.find_each { |c| hashes << c.geohash }
        hashes.size.should == 1
      end
    end

    context 'with two distant records' do
      before do
        make_record(0,0)
        make_record(45,0)
      end

      it('passes') { subject.run }

      it 'creates 2 clusters per depth' do
        subject.run
        adapter.collect_ids.length.should == 34
      end
    end


    context 'with random records' do
      before do
        10.times { make_record(rand, rand) }
        subject.run
      end

      let :toplevel_cluster do
        id = adapter.at_depth(3).collect_ids.first
        adapter.find_by_id(id)
      end

      let :barycenter do
        sum_lat = 0
        sum_lng = 0
        records.find_each { |r| sum_lat += r.lat ; sum_lng += r.lng }
        Tsuga::Model::Point.new.set_coords(0.1 * sum_lat, 0.1 * sum_lng)
      end

      it 'toplevel cluster has correct weight' do
        toplevel_cluster.weight.should == 10
      end

      it 'toplevel cluster is centered' do
        toplevel_cluster.should =~ barycenter
      end
    end
  end
end
