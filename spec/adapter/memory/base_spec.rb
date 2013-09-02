require 'spec_helper'
require 'tsuga/adapter/memory/base'

describe Tsuga::Adapter::Memory::Base do
  let(:stuff_class) do
    Class.new.class_eval do
      include Tsuga::Adapter::Memory::Base
      attr_accessor :foo
      self
    end
  end

  let(:stuff) { stuff_class.new }

  describe '#persist!' do
    it 'returns the record' do
      stuff.persist!.object_id.should == stuff.object_id
    end

    it 'makes objects retrievable' do
      stuff.persist!
      expect { stuff_class.find(stuff.id) }.not_to raise_error
    end

    it 'persists only current state' do
      stuff.foo = 1
      stuff.persist!
      stuff.foo = 2

      stuff_class.find(stuff.id).foo.should == 1
    end
  end

  describe '#destroy' do
    it 'removes records' do
      id = stuff.persist!.id
      stuff.destroy
      expect { stuff_class.find(id) }.to raise_error
    end

    it 'clears record id' do
      stuff.persist!.destroy.id.should be_nil
    end
  end

  describe '.find' do
    it 'retrives record by ID' do
      stuff.persist!
      stuff_class.find(stuff.id).id.should == stuff.id
    end

    it 'fails if not persisted' do
      stuff = stuff_class.new
      expect { stuff_class.find(stuff.id) }.to raise_error(Tsuga::RecordNotFound)
    end

    it 'fails if ID is unknown' do
      expect { stuff_class.find(123) }.to raise_error(Tsuga::RecordNotFound)
    end
  end

  describe '.find_each' do
    it 'yields nothing is no records present' do
      expect { |b| stuff_class.find_each(&b) }.not_to yield_control
    end

    it 'yields each persisted record' do
      id0 = stuff_class.new.persist!.id
      id1 = stuff_class.new.id
      id2 = stuff_class.new.persist!.id
      expect { |b| stuff_class.find_each(&b) }.to yield_control.twice
    end

    it 'allows writes while iterating' do
      stuff_class.new.persist!
      expect {
        stuff_class.find_each { |r| stuff_class.new.persist! }
      }.not_to raise_error
    end
  end

  describe '.delete_all' do
    it 'forgets persisted records' do
      stuff.persist!
      stuff_class.delete_all
      expect { stuff_class.find(stuff.id) }.to raise_error
    end
  end

  describe '.collect_ids' do
    it 'returns a set' do
      stuff_class.collect_ids.should be_a_kind_of(Set)
    end

    it 'returns all ids' do
      stuff_class.new.persist!
      stuff_class.new.persist!
      stuff_class.collect_ids.to_a.should =~ [1,2]
    end
  end

  describe '.scoped' do
    it 'returns a scope' do
      stuff_class.scoped.should be_a_kind_of(described_class::Scope)
    end
  end

  describe described_class::Scope do
    subject { stuff_class.scoped(lambda { |record| record.id % 2 == 0 }) }

    before do
      stuff1 = stuff_class.new.persist! # id 1
      stuff2 = stuff_class.new.persist! # id 2
    end

    describe '#find' do
      it 'finds selected items' do
        expect { subject.find(2) }.not_to raise_error
      end

      it 'filters out unscoped items' do
        expect { subject.find(1) }.to raise_error
      end
    end

    describe '#delete_all' do
      it 'deletes selected items' do
        subject.delete_all
        expect { stuff_class.find(2) }.to raise_error
      end

      it 'leaves filtered items' do
        subject.delete_all
        expect { stuff_class.find(1) }.not_to raise_error
      end
    end

    describe '#find_each' do
      it 'yields selected items' do
        expect { |b| subject.find_each(&b) }.to yield_control.once
      end
    end

    describe '#collect_ids' do
      it 'returns selected ids' do
        subject.collect_ids.to_a.should == [2]
      end
    end
  end

  describe 'defining named scopes' do
    before do
      stuff_class.class_eval do
        def self.id_multiple_of(n)
          scoped(lambda { |r| r.id % n == 0 })
        end
      end

      10.times { stuff_class.new.persist! }
    end

    it 'works' do
      expect { |b|
        stuff_class.id_multiple_of(3).find_each(&b)
      }.to yield_control.exactly(3).times
    end

    it 'is chainable' do
      expect { |b|
        stuff_class.id_multiple_of(3).id_multiple_of(2).find_each(&b)
      }.to yield_control.exactly(1).times
    end
  end
end
