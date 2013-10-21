require 'spec_helper'

describe "points/new" do
  before(:each) do
    assign(:point, stub_model(Point,
      :name => "MyString",
      :lat => 1.5,
      :lng => 1.5
    ).as_new_record)
  end

  it "renders new point form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", points_path, "post" do
      assert_select "input#point_name[name=?]", "point[name]"
      assert_select "input#point_lat[name=?]", "point[lat]"
      assert_select "input#point_lng[name=?]", "point[lng]"
    end
  end
end
