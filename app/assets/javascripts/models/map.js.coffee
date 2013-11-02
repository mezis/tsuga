tsuga.Models.Map = Backbone.Model.extend
  defaults: ->
    result =
      position:
        zoom: 13
        lat:  41.39734205254693
        lng:  2.160280522608784
      viewport:
        n:    null
        s:    null
        e:    null
        w:    null
