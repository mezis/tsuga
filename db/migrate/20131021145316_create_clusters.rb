class CreateClusters < ActiveRecord::Migration
  def change
    create_table :clusters do |t|
      t.integer :depth,   limit:1
      t.decimal :geohash, precision:21
      t.float   :lat
      t.float   :lng
      t.integer :parent_id
      t.string  :children_type
      t.string  :children_ids
      t.float   :sum_lat
      t.float   :sum_lng
      t.integer :weight
    end

    add_index :clusters, [:depth, :geohash]
  end
end
