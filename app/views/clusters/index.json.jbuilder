json.array!(@clusters) do |cluster|
  json.extract! cluster, :id, :lat, :lng, :weight, :dlng, :dlat
  if cluster.parent
    json.parent do
      json.lat cluster.parent.lat
      json.lng cluster.parent.lng
    end
  end
end
