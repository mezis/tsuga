require 'pathname'
require 'zlib'
require 'csv'

namespace :tsuga do
  desc 'import points of interest in FILE (in .csv.gz format)'
  task :import => :environment do
    path = Pathname(ENV['FILE'])
    path.exist? or raise 'file not found'

    Zlib::GzipReader.open(path) do |io|
      Point.delete_all
      Cluster.delete_all
      CSV(io) do |csv|
        csv.each do |row|
          id,lng,lat,name = row
          Point.create!(lat: lat.to_f, lng: lng.to_f, name: name)
        end
      end
    end
  end
end