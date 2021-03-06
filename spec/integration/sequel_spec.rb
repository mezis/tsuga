require 'spec_helper'
require 'tsuga/adapter/sequel/test'
require 'integration/shared'

describe 'integration' do
  describe 'sequel adapter' do
    let(:adapter)   { Tsuga::Adapter::Sequel::Test.clusters }
    it_should_behave_like 'an adapter suitable for clustering'
  end
end
