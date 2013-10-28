require 'tsuga/adapter/active_record/migration'

class CreateClusters < ActiveRecord::Migration
  include Tsuga::Adapter::ActiveRecord::Migration
  self.clusters_table_name = :clusters
end
