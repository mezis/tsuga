require 'spec_helper'
require 'tsuga/model/point'
require 'tsuga/model/tile'

describe Tsuga::Model::Tile do

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
        result.southeast.lng.should be_within(1e-6).of(360.0 * (2 ** -18))
        result.southeast.lat.should be_within(1e-6).of(180.0 * (2 ** -18))
      end

    end
  end

  describe '#contains?' do
    let(:point)  { Tsuga::Model::Point.new }

    subject do
      described_class.including(
        Tsuga::Model::Point.new.set_coords(0,0), :depth => 2)
    end

    let(:result) { subject.contains?(point) }

    it 'includes the northwest corner' do
      point.set_coords(0,0)
      result.should be_true
    end

    it 'excludes the southeast corner' do
      point.set_coords(45,90)
      result.should be_false
    end

    it 'includes point close to the southeast corner' do
      point.set_coords(45 - 1e-6, 90 - 1e-6)
      result.should be_true
    end

    it 'includes the center point' do
      point.set_coords(22.5, 45)
      result.should be_true
    end

    it 'excludes points north of the border' do
      point.set_coords(-1, 45)
      result.should be_false
    end

    it 'excludes points south of the border' do
      point.set_coords(48, 45)
      result.should be_false
    end

    it 'excludes points west of the border' do
      point.set_coords(22.5, -1)
      result.should be_false
    end

    it 'excludes points east of the border' do
      point.set_coords(22.5, 91)
      result.should be_false
    end

  end

end