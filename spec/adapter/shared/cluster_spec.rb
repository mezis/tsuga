require 'spec_helper'
require 'tsuga/adapter/shared/cluster'
require 'tsuga/adapter/memory/cluster'

describe Tsuga::Adapter::Shared::Cluster do
  let(:concretion_class) do
    Class.new.class_eval do
      include Tsuga::Adapter::Memory::Cluster
      self
    end
  end

  let(:concretion) { concretion_class.new }

  describe '#children' do
    let(:records) { (1..5).map { concretion_class.new.persist! } }

    it 'retrieves child records' do
      concretion.children_type = concretion.class.name
      concretion.children_ids  = records.map(&:id)
      concretion.children.map(&:id).should == records.map(&:id)
    end

    it 'works with no children' do
      concretion.children_type = concretion.class.name
      concretion.children_ids  = []
      concretion.children.should == []
    end
  end

  describe '#leaves' do
    # setup: r1 -> r2 -> r3 ; r4 isolated
    before do
      @r1 = concretion_class.new.persist!
      @r2 = concretion_class.new.persist!
      @r3 = concretion_class.new.persist!
      @r4 = concretion_class.new.persist!

      @r2.children_type = concretion_class.name
      @r2.children_ids  = [@r1.id]
      @r2.persist!

      @r3.children_type = concretion_class.name
      @r3.children_ids  = [@r2.id]
      @r3.persist!
    end

    it 'follows branches' do
      @r3.leaves.map(&:id).should == [@r1.id]
    end

    it 'works with no children' do
      @r4.leaves.map(&:id).should == [@r4.id]
    end
  end
end
