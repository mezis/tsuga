class CreateClusters < ActiveRecord::Migration
  def up
    create_table :clusters do |t|
      t.string  :tilecode,       limit:16
      t.integer :depth,          limit:1
      t.string  :geohash,        limit:16
      t.float   :lat
      t.float   :lng
      t.integer :parent_id
      t.string  :children_type
      t.string  :children_ids
      t.float   :sum_lat
      t.float   :sum_lng
      t.float   :ssq_lat
      t.float   :ssq_lng
      t.integer :weight
    end

    add_index :clusters, :tilecode
  end

  def down
    drop_table :clusters
  end
end
