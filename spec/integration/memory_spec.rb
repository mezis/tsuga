require 'spec_helper'
require 'tsuga/adapter/memory/cluster'
require 'integration/shared'

describe 'integration' do
  describe 'memory adapter' do
    let(:adapter)   { Class.new { include Tsuga::Adapter::Memory::Cluster } }
    it_should_behave_like 'an adapter suitable for clustering'
  end
end
