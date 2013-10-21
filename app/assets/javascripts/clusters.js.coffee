# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

window.TsugaDemo = {}

TsugaDemo.initialize = (selector) ->
  mapOptions = {
    center:    new google.maps.LatLng(41.368748, 2.147869),
    zoom:      13,
    mapTypeId: google.maps.MapTypeId.ROADMAP
  }
  TsugaDemo.map = new google.maps.Map($(selector)[0], mapOptions)
  console.log "loaded map"

