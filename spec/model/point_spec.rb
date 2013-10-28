require 'spec_helper'
require 'tsuga/model/point'

describe Tsuga::Model::Point do
  describe '#distance_to' do
    let(:p00) { described_class.new(lat:0, lng:0) }
    let(:p01) { described_class.new(lat:0, lng:1) }
    let(:p11) { described_class.new(lat:1, lng:1) }

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

  describe '#lat=, #lng=' do
    let(:result) { subject.geohash }

    it 'converts latitude and longitude to a geohash' do
      subject.lat =  -90
      subject.lng = -180
      result.should == '00000000000000000000000000000000'
    end

    it 'is ok for the highest hash' do
      subject.lat = 90 - 1e-8
      subject.lng = 180 - 1e-8
      result.should == '33333333333333333333333333333333'
    end

    it 'is ok or equator/greenwhich' do
      subject.lat = 0
      subject.lng = 0
      result.should == '30000000000000000000000000000000'
    end

    it 'fails when lat/lng missing' do
      subject.lat = nil
      subject.lng = 0
      result.should be_nil
    end

    it 'fails when lat out of bounds' do
      expect { subject.lat = 90 }.to raise_error(ArgumentError)
    end

    it 'fails when lng out of bounds' do
      expect { subject.lng = 180 }.to raise_error(ArgumentError)
    end
  end

  describe '#lat #lng' do
    it 'computes coordinates from hash' do
      subject.geohash = '22222222222222222222222222222222'
      subject.lat.should be_within(1e-6).of(-90)
      subject.lng.should be_within(1e-6).of(180)
    end

    it 'is ok or equator/greenwhich' do
      subject.geohash = '30000000000000000000000000000000'
      subject.lat.should be_within(1e-6).of(0)
      subject.lng.should be_within(1e-6).of(0)
    end
  end

  describe '#prefix' do
    it 'returns a prefix of the geohash' do
      subject.geohash = '12332100000000000000000000000000'
      subject.prefix(6).should == '123321'
    end
  end

  describe '(comparison)' do
    it 'preserves lat-order' do
      described_class.new(lat:45, lng:2).geohash.should <
      described_class.new(lat:46, lng:2).geohash
    end

    it 'preserves lng-order' do
      described_class.new(lat:45, lng:2).geohash.should <
      described_class.new(lat:45, lng:3).geohash
    end

    it 'preserves order around greenwich' do
      described_class.new(lat:45, lng:-1).geohash.should <
      described_class.new(lat:45, lng: 1).geohash
    end

    it 'preserves order around equator' do
      described_class.new(lat:-1, lng:2).geohash.should <
      described_class.new(lat: 1, lng:2).geohash
    end
  end
end

