require 'spec_helper'
require 'tsuga/service/clusterer'
require 'tsuga/adapter/memory_adapter'
require 'tsuga/adapter/sequel_adapter'
require 'tsuga/adapter/mongoid_adapter'

describe 'adapters' do
  shared_examples_for 'an adapter suitable for clustering' do
    let(:clusterer) { Tsuga::Service::Clusterer.new(adapter) }

    def make_record(lat, lng)
      adapter.records.new.set_coords(lat,lng).persist!
    end

    before { adapter.clusters.delete_all }
    before { adapter.records.delete_all }

    context 'with random records' do
      let(:count) { 10 }
      before do
        count.times { make_record(rand, rand) }
        clusterer.run
      end

      let :toplevel_cluster do
        id = adapter.clusters.at_depth(3).collect_ids.first
        adapter.clusters.find_by_id(id)
      end

      let :barycenter do
        sum_lat = 0
        sum_lng = 0
        adapter.records.find_each { |r| sum_lat += r.lat ; sum_lng += r.lng }
        Tsuga::Model::Point.new.set_coords(sum_lat/count, sum_lng/count)
      end

      it 'toplevel cluster has correct weight' do
        toplevel_cluster.weight.should == count
      end

      it 'toplevel cluster is centered' do
        toplevel_cluster.lat
        (toplevel_cluster & barycenter).should < 1e-6 # 10 micro degrees ~ 1 meter at equator
      end
    end
  end

  describe 'memory adapter' do
    let(:adapter)   { Tsuga::Adapter::MemoryAdapter.test_adapter }
    it_should_behave_like 'an adapter suitable for clustering'
  end

  describe 'sequel adapter' do
    let(:adapter)   { Tsuga::Adapter::SequelAdapter.test_adapter }
    it_should_behave_like 'an adapter suitable for clustering'
  end

  describe 'mongo adapter' do
    let(:adapter)   { Tsuga::Adapter::MongoidAdapter.test_adapter }
    it_should_behave_like 'an adapter suitable for clustering'
  end
end