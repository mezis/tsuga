require "spec_helper"

describe ClustersController do
  describe "routing" do

    it "routes to #index" do
      get("/clusters").should route_to("clusters#index")
    end

    it "routes to #new" do
      get("/clusters/new").should route_to("clusters#new")
    end

    it "routes to #show" do
      get("/clusters/1").should route_to("clusters#show", :id => "1")
    end

    it "routes to #edit" do
      get("/clusters/1/edit").should route_to("clusters#edit", :id => "1")
    end

    it "routes to #create" do
      post("/clusters").should route_to("clusters#create")
    end

    it "routes to #update" do
      put("/clusters/1").should route_to("clusters#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/clusters/1").should route_to("clusters#destroy", :id => "1")
    end

  end
end
