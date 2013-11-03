# Tsuga

[![Build Status](https://travis-ci.org/mezis/tsuga.png?branch=master)](https://travis-ci.org/mezis/tsuga)

<img width="320" style="margin-left:1em;margin-bottom:1em;clear:both;float:right;" src="http://cl.ly/image/251X2b1p1B00/b1.jpg"/>
<img width="320" style="margin-left:1em;margin-bottom:1em;clear:both;float:right;" src="http://cl.ly/image/1T1U421F1P2G/b2.jpg"/>

A **clustering engine** for geographical data (points of interest) that
produces a **tree** of clusters, with depths matching zoomlevels on typical
maps, and source points of interest as leaves.

Makes heavy use of [Geohash](http://en.wikipedia.org/wiki/Geohash)-like and
[Morton codes](http://en.wikipedia.org/wiki/Morton_number_(number_theory)).

Designed with Rails usage in mind, but usable without Rails or even without a database.

Go play with the [live demo](http://tsuga-demo.herokuapp.com/) from which
the screenshots on the right were taken. Be patient, it's a free Heroku app!
The [source](http://github.com/mezis/tsuga-demo) of the demo is an example
of how to use Tsuga.

# Installation

Add the `tsuga` gem to your `Gemfile`:

    gem 'tsuga'


# Usage

Four steps are typically involved:

1. Provide a source of points of interest to cluster
2. Provide storage for clusters
3. Run the clusterer
4. Lookup clusters or a particlar map viewport


## Providing source points

Tsuga need to know how to iterate over points of interests.
Any enumerable will do as long as 
- it responds to `find_each` or `each`, and
- it yields records that respond to `id` with an integer, and to `lat` and `lng` with floating-point numbers.

Simply put, anything `ActiveModel`-ish should do.


## Providing cluster storage


Tsuga also need you to provide storage for the clusters. Currently supported
are [Mongoid][mongoid], [Sequel][sequel], and [ActiveRecord][active_record] (an in-memory backend is provided, but is
only useful for testing or extremely small datasets).


### ActiveRecord

Example with [ActiveRecord][active_record]. Create a migration:

    require 'tsuga/adapter/active_record/cluster_migration'

    class AddClusters < ActiveRecord::Migration
      include Tsuga::Adapter::ActiveRecord::Migration
      self.clusters_table_name = :clusters
    end

And the matching `Cluster` model:

    # app/models/cluster.rb
    require 'tsuga/adapter/active_record/cluster_model'

    class Cluster < ActiveRecord::Model
      include Tsuga::Adapter::ActiveRecord::ClusterModel
    end


### Mongoid

Example with [Mongoid][mongoid].

    # app/models/cluster.rb
    require 'tsuga/adapter/mongoid/cluster_model'

    class Cluster
      include Tsuga::Adapter::Mongoid::ClusterModel
    end


### Sequel

Example with [Sequel][sequel].

    # app/models/cluster.rb
    require 'tsuga/adapter/sequel/cluster_model'

    class Cluster < Sequel::Model(:clusters)
      include Tsuga::Adapter::Sequel::ClusterModel
    end

You will have to provide your own migration, respecting the schema in
`Tsuga::Adapter::ActiveRecord::Migration`.


## Running the clusterer service

The clustering engine is `Tsuga::Service::Clusterer`, and running a full
clustering is as simple as:

    require 'tsuga'
    Tsuga::Service::Clusterer.new(source: PointOfInterest, adapter: Cluster).run

This will delete all existing clusters, walk the points of interest, and
rebuild a tree of clusters.


## Finding clusters

Tsuga extended your cluster class with helper class methods:

    nw = Tsuga::Point(lat: 45, lng: 1)
    se = Tsuga::Point(lat: 44, lng: 2)
    Cluster.in_viewport(nw, se)

will return an enumerable (scopish where possible), that responds to
`find_each`, `each`, and `count`, and contains clusters within the specified
viewport.

## Cluster API

Clusters have at least the following accessors:

| method      | description                            |
|-------------|----------------------------------------|
| `lat`       | latitude of the cluster's barycenter   |
| `lng`       | longitude of the cluster's barycenter  |
| `weight`    | total number of points (leaves) in subtree |
| `children`  | enumerable of child clusters (or points of interest) |
| `depth`     | the scale this cluster is relevant at, where 0 is the whole world |


[mongoid]:       http://mongoid.org/
[sequel]:        http://sequel.rubyforge.org/
[active_record]: http://guides.rubyonrails.org/

