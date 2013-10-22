require 'tsuga/adapter/active_record/cluster'

class Cluster < ActiveRecord::Base
  include Tsuga::Adapter::ActiveRecord::Cluster
end
