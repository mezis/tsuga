# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class TsugaDemo
  constructor: (@selector) ->
    @markers = []

  setup: ->
    mapOptions = {
      center:    new google.maps.LatLng(41.368748, 2.147869),
      zoom:      13,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    @map = new google.maps.Map($(@selector)[0], mapOptions)
    google.maps.event.addListener @map, 'zoom_changed', =>
      this._onChangeViewport()
    google.maps.event.addListener @map, 'center_changed', =>
      this._onChangeViewport()
    this._log "loaded map"

  _getViewport: ->
    rect =
      n: @bounds.getNorthEast().lat()
      e: @bounds.getNorthEast().lng()
      s: @bounds.getSouthWest().lat()
      w: @bounds.getSouthWest().lng()
      z: @map.getZoom()

  _onChangeViewport: ->
    @bounds = @map.getBounds()
    this._setDefaultRadius()
    rect = this._getViewport()
    this._log "panned to n:#{rect.n}, w:#{rect.w}, s:#{rect.s}, e:#{rect.e}"
    this._fetchMarkers()

  _fetchMarkers: ->
    rect   = this._getViewport()
    $.ajax
      url:      $(@selector).data('clusters-path')
      data:     rect
      dataType: 'json'
      success:  (data) =>
        this._updateMarkers(data)

  _updateMarkers: (data) ->
    this._removeMarkers()
    for cluster in data
      this._log "new marker: #{cluster.lat}, #{cluster.lng}"
      this._addMarker(cluster)
    for marker in @markers
      marker.setMap(@map)

  _addMarker: (cluster) ->
    center    = new google.maps.LatLng(cluster.lat, cluster.lng)
    if cluster.weight == 1
      fillColor = '#ff0000'
      radius    = @defaultRadius
    else
      fillColor = '#ff00ff'
      radius    = this._getRadius(center, cluster)
    options =
      strokeColor:    '#ff0000'
      strokeOpacity:  0.8
      strokeWeight:   2
      fillColor:      fillColor
      fillOpacity:    0.35
      center:         center
      radius:         radius
    marker = new google.maps.Circle(options)
    @markers.push(marker)

  _removeMarkers: ->
    for marker in @markers
      marker.setMap(null)
    @markers = []

  _getRadius: (center, cluster) ->
    point = new google.maps.LatLng(cluster.lat + cluster.dlat, cluster.lng + cluster.dlng)
    google.maps.geometry.spherical.computeDistanceBetween(center, point)

  _setDefaultRadius: ->
    @defaultRadius = google.maps.geometry.spherical.computeDistanceBetween(
      @bounds.getNorthEast(),
      @bounds.getSouthWest()
    ) * 0.01

  _log: (msg) ->
    # console.log msg




window.TsugaDemo = TsugaDemo
