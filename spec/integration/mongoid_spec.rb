require 'spec_helper'
require 'tsuga/adapter/mongoid/test'
require 'integration/shared'

describe 'integration' do
  describe 'mongoid adapter' do
    let(:adapter) { Tsuga::Adapter::Mongoid::Test.clusters }
    it_should_behave_like 'an adapter suitable for clustering'
  end
end
