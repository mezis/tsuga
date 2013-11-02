tsuga.Models.Cluster = Backbone.Model.extend
  defaults: ->
    result =
      id:     null
      lat:    null
      lng:    null
      weight: null
      dlat:   null
      dlng:   null
      parent:
        lat:  null
        lng:  null

