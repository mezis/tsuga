
window.tsuga =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  initialize: ->
    @app = new tsuga.Routers.Map()

$(document).ready ->
  window.tsuga.initialize()
  Backbone.history.start({pushState: false})
