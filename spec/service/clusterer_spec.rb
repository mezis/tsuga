require 'spec_helper'
require 'tsuga/service/clusterer'
require 'tsuga/adapter/memory_adapter'

describe Tsuga::Service::Clusterer do
  subject { described_class.new(adapter) }
  let(:adapter) { Tsuga::Adapter::MemoryAdapter.new  }

  def make_record(lat, lng)
    adapter.records.new.set_coords(lat,lng).persist!
  end

  before { adapter.clusters.delete_all }
  before { adapter.records.delete_all }

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
        adapter.clusters.collect_ids.length.should == 17
      end

      it 'creates clusters with the same position' do
        subject.run
        hashes = Set.new
        adapter.clusters.find_each { |c| hashes << c.geohash }
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
        adapter.clusters.collect_ids.length.should == 34
      end
    end


    context 'with random records' do
      before do
        10.times { make_record(rand, rand) }
        subject.run
      end

      let :toplevel_cluster do
        id = adapter.clusters.at_depth(3).collect_ids.first
        adapter.clusters.find_by_id(id)
      end

      let :barycenter do
        sum_lat = 0
        sum_lng = 0
        adapter.records.find_each { |r| sum_lat += r.lat ; sum_lng += r.lng }
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
