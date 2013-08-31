require 'spec_helper'
require 'tsuga/model/point'

describe Tsuga::Model::Point do
  # class TestPoint < Struct.new(:lat, :lng, :geohash)
  #   include Tsuga::Model::Point
  # end

  # subject { TestPoint.new }

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
end