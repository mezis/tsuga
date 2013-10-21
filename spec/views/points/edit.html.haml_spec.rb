require 'spec_helper'

describe "points/edit" do
  before(:each) do
    @point = assign(:point, stub_model(Point,
      :name => "MyString",
      :lat => 1.5,
      :lng => 1.5
    ))
  end

  it "renders the edit point form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", point_path(@point), "post" do
      assert_select "input#point_name[name=?]", "point[name]"
      assert_select "input#point_lat[name=?]", "point[lat]"
      assert_select "input#point_lng[name=?]", "point[lng]"
    end
  end
end
