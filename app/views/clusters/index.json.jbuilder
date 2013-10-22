json.array!(@clusters) do |cluster|
  json.extract! cluster, :lat, :lng, :weight, :dlng, :dlat
end
