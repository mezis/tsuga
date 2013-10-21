require 'spec_helper'

describe "clusters/edit" do
  before(:each) do
    @cluster = assign(:cluster, stub_model(Cluster,
      :lat => 1.5,
      :lng => 1.5
    ))
  end

  it "renders the edit cluster form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", cluster_path(@cluster), "post" do
      assert_select "input#cluster_lat[name=?]", "cluster[lat]"
      assert_select "input#cluster_lng[name=?]", "cluster[lng]"
    end
  end
end
