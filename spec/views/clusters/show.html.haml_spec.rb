require 'spec_helper'

describe "clusters/show" do
  before(:each) do
    @cluster = assign(:cluster, stub_model(Cluster,
      :lat => 1.5,
      :lng => 1.5
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1.5/)
    rendered.should match(/1.5/)
  end
end
