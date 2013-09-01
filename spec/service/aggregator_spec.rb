require 'spec_helper'
require 'tsuga/service/aggregator'
require 'tsuga/adapter/memory_adapter'

describe Tsuga::Service::Aggregator do
  subject { described_class.new(clusters) }

  def new_cluster(depth, lat, lng)
    # require 'pry' ; require 'pry-nav' ; binding.pry
    Tsuga::Adapter::MemoryAdapter.clusters.new.tap do |cluster|
      cluster.depth = depth
      cluster.set_coords(lat,lng)
      cluster.weight  = 1
      cluster.sum_lat = lat
      cluster.sum_lng = lng
      cluster.children_ids = []
      cluster.persist!
    end
  end

  describe '#min_distance' do
    let(:clusters) { [new_cluster(2,0,0)] }

    it 'is about 20% of a tile diagonal' do
      subject.min_distance.should == be_within(1e-6).of(Math.sqrt(45*45 + 90*90) / 5)
    end
  end

  describe '#run' do
    context 'when the list of clusters is empty' do
      let(:clusters) { [] }
      it('passes') { subject.run }
    end

    context 'with a single cluster' do
      let(:clusters) { [new_cluster(2,0,0)] }
      it('passes') { subject.run }
    end

    context 'with 4 distant clusters' do
      let(:north) { 0 }
      let(:south) { 45 - 1e-4 }
      let(:west)  { 0 }
      let(:east)  { 90 - 1e-4 }

      let(:clusters) {[
        new_cluster(2, north, west),
        new_cluster(2, south, west),
        new_cluster(2, south, east),
        new_cluster(2, north, east)
      ]}
      it('passes') { subject.run }
    end
  end

end