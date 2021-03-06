require 'spec_helper'
require 'tsuga/model/point'
require 'tsuga/model/tile'
require 'ostruct'

describe Tsuga::Model::Tile do

  describe '.including' do
    let(:depth)  { OpenStruct.new :value => 1 }
    let(:point)  { Tsuga::Model::Point.new(lat:0, lng:0) }
    let(:result) { described_class.including(point, :depth => depth.value) }

    it 'creates a tile from a point' do
      result.should be_a_kind_of(Tsuga::Model::Tile)
    end

    context "on equator/greenwidth" do
      before do
        point.lat   = 0
        point.lng   = 0
        depth.value = 18
      end

      it 'calculates southwest' do
        result.southwest.should =~ point
      end

      it 'calculates northeast' do
        result.northeast.lng.should be_within(1e-6).of(360.0 * (2 ** -18))
        result.northeast.lat.should be_within(1e-6).of(180.0 * (2 ** -18))
      end

      it 'respects geohash ordering' do
        result.southwest.geohash.should < result.northeast.geohash
      end
    end
  end

  describe '#contains?' do
    let(:point)  { Tsuga::Model::Point.new }

    subject do
      described_class.including(
        Tsuga::Model::Point.new(lat:0, lng:0), :depth => 2)
    end

    let(:result) { subject.contains?(point) }

    it 'includes the northwest corner' do
      point.lat = 0
      point.lng = 0
      result.should be_true
    end

    it 'excludes the southeast corner' do
      point.lat = 45
      point.lng = 90
      result.should be_false
    end

    it 'includes point close to the southeast corner' do
      point.lat = 45 - 1e-6
      point.lng = 90 - 1e-6
      result.should be_true
    end

    it 'includes the center point' do
      point.lat = 22.5
      point.lng = 45
      result.should be_true
    end

    it 'excludes points north of the border' do
      point.lat = -1
      point.lng = 45
      result.should be_false
    end

    it 'excludes points south of the border' do
      point.lat = 48
      point.lng = 45
      result.should be_false
    end

    it 'excludes points west of the border' do
      point.lat = 22.5
      point.lng = -1
      result.should be_false
    end

    it 'excludes points east of the border' do
      point.lat = 22.5
      point.lng = 91
      result.should be_false
    end
  end

  describe '#neighbour' do
    subject { described_class.new(prefix:'300') }
    # . . . . . . . .   13
    # . . . . . . . .   02
    # . . . . - . . .
    # . . . - X - . .
    # . . . . - . . .
    # . . . . . . . .
    # . . . . . . . .
    # . . . . . . . .


    it('works to the east' ) { subject.neighbour(lat: 0, lng: 1).prefix.should == '302' }
    it('works to the west' ) { subject.neighbour(lat: 0, lng:-1).prefix.should == '122' }
    it('works to the north') { subject.neighbour(lat: 1, lng: 0).prefix.should == '301' }
    it('works to the south') { subject.neighbour(lat:-1, lng: 0).prefix.should == '211' }
  end

end