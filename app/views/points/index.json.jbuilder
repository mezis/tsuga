json.array!(@points) do |point|
  json.extract! point, :id, :lat, :lng
end
