require 'spec_helper'
require 'tsuga/adapter/memory/cluster'

describe Tsuga::Adapter::Memory::Cluster do
  let(:concretion_class) do
    Class.new.class_eval do
      include Tsuga::Adapter::Memory::Cluster
      self
    end
  end

  let(:concretion) { concretion_class.new }

  describe '#persist!' do
    it 'returns the record' do
      concretion.persist!.object_id.should == concretion.object_id
    end

    it 'makes objects retrievable' do
      concretion.persist!
      expect { concretion_class.find_by_id(concretion.id) }.not_to raise_error
    end
  end

  describe '#destroy' do
    it 'removes records' do
      id = concretion.persist!.id
      concretion.destroy
      expect { concretion_class.find_by_id(id) }.to raise_error
    end
  end

  describe '.find' do
    it 'retrives record by ID' do
      concretion.persist!
      concretion_class.find_by_id(concretion.id).id.should == concretion.id
    end
  end
end
