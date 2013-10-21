require 'spec_helper'

describe "clusters/index" do
  before(:each) do
    assign(:clusters, [
      stub_model(Cluster,
        :lat => 1.5,
        :lng => 1.5
      ),
      stub_model(Cluster,
        :lat => 1.5,
        :lng => 1.5
      )
    ])
  end

  it "renders a list of clusters" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
  end
end
