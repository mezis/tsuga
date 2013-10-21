json.array!(@clusters) do |cluster|
  json.extract! cluster, :name, :lat, :lng, :geohash, :depth, :parent_id, :children_type, :children_ids, :sum_lat, :sum_lng, :weight
end
