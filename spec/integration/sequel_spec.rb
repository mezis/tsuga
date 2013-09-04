require 'spec_helper'
require 'tsuga/service/clusterer'
require 'tsuga/adapter/sequel_adapter'

describe 'Sequel integration' do
  let(:adapter)   { Tsuga::Adapter::SequelAdapter.test_adapter  }
  let(:clusterer) { Tsuga::Service::Clusterer.new(adapter) }

  def make_record(lat, lng)
    adapter.records.new.set_coords(lat,lng).persist!
  end

  before { adapter.clusters.delete_all }
  before { adapter.records.delete_all }

  describe '#run' do
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
        # (toplevel_cluster & barycenter).should < 1e-6 # 1 micro degrees ~ 10 cm at equator
      end

      # it 'debugs' do
      #   require 'pry' ; require 'pry-nav' ; binding.pry
      # end
    end
  end
end
