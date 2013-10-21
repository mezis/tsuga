require 'spec_helper'
require 'tsuga/adapter/active_record/test'
require 'integration/shared'

describe 'integration' do
  describe 'active_record adapter' do
    let(:adapter) { Tsuga::Adapter::ActiveRecord::Test.clusters }
    it_should_behave_like 'an adapter suitable for clustering'
  end
end
