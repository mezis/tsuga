require 'tsuga/adapter/shared'

# Shared functionnality between adapters
module Tsuga::Adapter::Shared::Cluster
  def children
    return [] if children_ids.nil?
    children_ids.map do |_id|
      self.class.find_by_id(_id)
    end
  end

  def leaves
    if children_type != self.class.name || children_ids.nil? || children_ids.empty?
      [self]
    else
      children.map(&:leaves).inject(:+)
    end
  end
end