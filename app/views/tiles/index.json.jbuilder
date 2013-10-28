json.array!(@tiles) do |tile|
  json.n tile.northeast.lat
  json.s tile.southwest.lat
  json.e tile.northeast.lng
  json.w tile.southwest.lng
end
