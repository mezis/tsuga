# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20131021145316) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clusters", force: true do |t|
    t.string  "tilecode",      limit: 16
    t.integer "depth",         limit: 2
    t.string  "geohash",       limit: 16
    t.float   "lat"
    t.float   "lng"
    t.integer "parent_id"
    t.string  "children_type"
    t.string  "children_ids"
    t.float   "sum_lat"
    t.float   "sum_lng"
    t.float   "ssq_lat"
    t.float   "ssq_lng"
    t.integer "weight"
  end

  add_index "clusters", ["tilecode"], name: "index_clusters_on_tilecode", using: :btree

  create_table "points", force: true do |t|
    t.string   "name"
    t.float    "lat"
    t.float    "lng"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
