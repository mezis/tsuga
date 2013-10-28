class CreatePoints < ActiveRecord::Migration
  def up
    create_table :points do |t|
      t.string :name
      t.float  :lat
      t.float  :lng
    end

    add_index :points, [:lat, :lng]
  end

  def down
    drop_table :points
  end
end
