json.array!(@clusters) do |cluster|
  json.extract! cluster, :id, :lat, :lng, :weight, :dlng, :dlat
  json.parent do
    json.lat cluster.parent.lat
    json.lng cluster.parent.lng
  end
end
