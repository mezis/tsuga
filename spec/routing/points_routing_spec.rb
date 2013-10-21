require "spec_helper"

describe PointsController do
  describe "routing" do

    it "routes to #index" do
      get("/points").should route_to("points#index")
    end

    it "routes to #new" do
      get("/points/new").should route_to("points#new")
    end

    it "routes to #show" do
      get("/points/1").should route_to("points#show", :id => "1")
    end

    it "routes to #edit" do
      get("/points/1/edit").should route_to("points#edit", :id => "1")
    end

    it "routes to #create" do
      post("/points").should route_to("points#create")
    end

    it "routes to #update" do
      put("/points/1").should route_to("points#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/points/1").should route_to("points#destroy", :id => "1")
    end

  end
end
