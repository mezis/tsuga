require 'spec_helper'
require 'tsuga/adapter/memory/test'
require 'integration/shared'

describe 'integration' do
  describe 'memory adapter' do
    let(:adapter)   { Tsuga::Adapter::Memory::Test.clusters }
    it_should_behave_like 'an adapter suitable for clustering'
  end
end
