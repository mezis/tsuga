require 'tsuga/service/clusterer'
require 'tsuga/model/point'

shared_examples_for 'an adapter suitable for clustering' do
  let(:clusterer) { Tsuga::Service::Clusterer.new(source: records, adapter: adapter) }
  let(:records) { ArrayWithFindEach.new }

  def make_record(lat, lng)
    records << OpenStruct.new(lat:lat, lng:lng)
  end

  before { adapter.delete_all }

  context 'with random records' do
    let(:count) { 10 }
    before do
      count.times { make_record(rand, rand) }
      clusterer.run
    end

    let :toplevel_cluster do
      id = adapter.at_depth(3).collect_ids.first
      adapter.find_by_id(id)
    end

    let :barycenter do
      sum_lat = 0
      sum_lng = 0
      records.each { |r| sum_lat += r.lat ; sum_lng += r.lng }
      Tsuga::Model::Point.new.set_coords(sum_lat/count, sum_lng/count)
    end

    it 'toplevel cluster has correct weight' do
      toplevel_cluster.weight.should == count
    end

    it 'toplevel cluster is centered' do
      toplevel_cluster.lat
      (toplevel_cluster & barycenter).should < 1e-6 # 10 micro degrees ~ 1 meter at equator
    end

    it 'all depths have same total weight' do
      3.upto(19) do |depth|
        total_weight = 0
        adapter.at_depth(depth).find_each { |c| total_weight += c.weight }
        total_weight.should == 10
      end
    end
  end
end
