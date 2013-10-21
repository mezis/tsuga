require 'spec_helper'

describe "clusters/new" do
  before(:each) do
    assign(:cluster, stub_model(Cluster,
      :lat => 1.5,
      :lng => 1.5
    ).as_new_record)
  end

  it "renders new cluster form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", clusters_path, "post" do
      assert_select "input#cluster_lat[name=?]", "cluster[lat]"
      assert_select "input#cluster_lng[name=?]", "cluster[lng]"
    end
  end
end
