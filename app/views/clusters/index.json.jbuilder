json.array!(@clusters) do |cluster|
  json.extract! cluster, :id, :lat, :lng, :weight, :dlng, :dlat
end
