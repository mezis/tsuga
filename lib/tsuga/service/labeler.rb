module Tsuga::Service
  # Adds geo hashes to records.
  class Labeler
    def initialize(adapter)
      @_adapter = adapter
    end

    def run
      _adapter.records.find_each do |record|
        record.update_geohash
        record.persist!
      end
    end

    private 

    attr_reader :_adapter

  end
end
