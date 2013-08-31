require 'spec_helper'
require 'tsuga/model/point'
require 'tsuga/model/tile'

describe Tsuga::Model::Tile do
  # class TestPoint < Struct.new(:lat, :lng, :geohash)
  #   include Tsuga::Model::Point
  # end

  describe '.including' do
    let(:depth)  { OpenStruct.new :value => 1 }
    let(:point)  { Tsuga::Model::Point.new }
    let(:result) { described_class.including(point, :depth => depth.value) }

    it 'creates a tile from a point' do
      result.should be_a_kind_of(Tsuga::Model::Tile)
    end

    context "on equator/greenwidth" do
      before do
        point.set_coords(0,0)
        depth.value = 18
      end

      it 'calculates northwest' do
        result.northwest.should == point
      end

      it 'calculates southeast' do
        result.southeast.should > point
      end

    end
  end

end