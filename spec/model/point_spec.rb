require 'spec_helper'
require 'tsuga/model/point'

describe Tsuga::Model::Point do
  # class TestPoint < Struct.new(:lat, :lng, :geohash)
  #   include Tsuga::Model::Point
  # end

  # subject { TestPoint.new }

  describe '#distance_to' do
    let(:p00) { described_class.new.set_coords(0,0) }
    let(:p01) { described_class.new.set_coords(0,1) }
    let(:p11) { described_class.new.set_coords(1,1) }

    it 'is zero for the same point' do
      p00.distance_to(p00).should be_within(1e-6).of(0)
    end

    it 'is 1 for points 1 degree apart' do
      p00.distance_to(p01).should be_within(1e-6).of(1)
    end

    it 'uses euclidian distance' do
      p00.distance_to(p11).should be_within(1e-6).of(Math.sqrt(2))
    end
  end

  describe '#set_coords' do
    let(:result) { "%064b" % subject.geohash }

    it 'converts latitude and longitude to a geohash' do
      subject.set_coords -90, -180
      result.should == '0000000000000000000000000000000000000000000000000000000000000000'
    end

    it 'is ok for the highest hash' do
      subject.set_coords 90 - 1e-8, 180 - 1e-8
      result.should == '1111111111111111111111111111111111111111111111111111111111111111'
    end

    it 'is ok or equator/greenwhich' do
      subject.set_coords 0, 0
      result.should == '1100000000000000000000000000000000000000000000000000000000000000'
    end

    it 'fails when lat/lng missing' do
      expect { subject.set_coords nil, 0 }.to raise_error(ArgumentError)
    end

    it 'fails when out of bounds' do
      expect { subject.set_coords 90, 180 }.to raise_error(ArgumentError)
    end
  end

  describe '#lat #lng' do
    it 'computes coordinates from hash' do
      subject.geohash = 0b1010101010101010101010101010101010101010101010101010101010101010
      subject.lat.should be_within(1e-6).of(-90)
      subject.lng.should be_within(1e-6).of(180)
    end

    it 'is ok or equator/greenwhich' do
      subject.geohash = 0b1100000000000000000000000000000000000000000000000000000000000000
      subject.lat.should be_within(1e-6).of(0)
      subject.lng.should be_within(1e-6).of(0)
    end
  end

  describe '(comparison)' do
    it 'preserves lat-order' do
      described_class.new.set_coords(45, 2).should <
      described_class.new.set_coords(46, 2)
    end

    it 'preserves lng-order' do
      described_class.new.set_coords(45, 2).should <
      described_class.new.set_coords(45, 3)
    end

    it 'preserves order around greenwich' do
      described_class.new.set_coords(45, -1).should <
      described_class.new.set_coords(45,  1)
    end

    it 'preserves order around equator' do
      described_class.new.set_coords(-1, 2).should <
      described_class.new.set_coords( 1, 2)
    end
  end
end

