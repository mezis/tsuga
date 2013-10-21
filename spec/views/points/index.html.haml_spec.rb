require 'spec_helper'

describe "points/index" do
  before(:each) do
    assign(:points, [
      stub_model(Point,
        :name => "Name",
        :lat => 1.5,
        :lng => 1.5
      ),
      stub_model(Point,
        :name => "Name",
        :lat => 1.5,
        :lng => 1.5
      )
    ])
  end

  it "renders a list of points" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
  end
end
