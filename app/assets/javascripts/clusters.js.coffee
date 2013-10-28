# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class TsugaCluster
  constructor: (cluster, @defaultRadius, @map) ->
    @circle = null
    @line   = null

    center    = new google.maps.LatLng(cluster.lat, cluster.lng)
    if cluster.weight == 1
      fillColor = '#ff0000'
      radius    = @defaultRadius
    else
      fillColor = '#ff00ff'
      radius    = this._getRadius(center, cluster)
      # radius    = @defaultRadius
    options =
      # strokeColor:    null
      strokeOpacity:  0.0
      # strokeWeight:   2
      fillColor:      fillColor
      fillOpacity:    0.1
      center:         center
      radius:         radius
    @circle = new google.maps.Circle(options)
    console.log "cluster #{cluster.id} radius #{radius}"

    parent = new google.maps.LatLng(cluster.parent.lat, cluster.parent.lng)
    @line = new google.maps.Polyline
      path:           [center, parent]
      geodesic:       true
      strokeColor:    fillColor,
      strokeOpacity:  0.3
      strokeWeight:   2

  show: ->
    @circle.setMap(@map)
    @line.setMap(@map)
  hide: ->
    @circle.setMap(null)
    @line.setMap(null)
  update: (radius) ->
    null

  _getRadius: (center, cluster) ->
    point = new google.maps.LatLng(cluster.lat + cluster.dlat, cluster.lng + cluster.dlng)
    radius = google.maps.geometry.spherical.computeDistanceBetween(center, point)
    Math.max(radius, @defaultRadius)


class TsugaPoint
  constructor: (point, @radius, @map) ->
    @circle = null
    options =
      strokeOpacity:  0.0
      fillColor:      '#000000'
      fillOpacity:    0.5
      center:         new google.maps.LatLng(point.lat, point.lng)
      radius:         0.25 * @radius
    @circle = new google.maps.Circle(options)

  show: ->
    @circle.setMap(@map)
  hide: ->
    @circle.setMap(null)
  update: (radius) ->
    return if radius == @radius
    @radius = radius
    @circle.setRadius(0.25 * radius)


class TsugaTile
  constructor: (tile, @map) ->
    nw = new google.maps.LatLng(tile.n, tile.w)
    ne = new google.maps.LatLng(tile.n, tile.e)
    se = new google.maps.LatLng(tile.s, tile.e)
    sw = new google.maps.LatLng(tile.s, tile.w)

    @poly = new google.maps.Polyline
      path:           [nw, ne, se, sw, nw]
      geodesic:       true
      strokeColor:    '#ffff00',
      strokeOpacity:  0.6
      strokeWeight:   2

  show: ->
    @poly.setMap(@map)
  hide: ->
    @poly.setMap(null)


class TsugaDemo
  constructor: (@selector) ->
    @clusters = {}
    @points   = {}
    @tiles = []

  setup: ->
    mapOptions = {
      center:    new google.maps.LatLng(41.40205735144555, 2.1651799769821123),
      zoom:      15,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    @map = new google.maps.Map($(@selector)[0], mapOptions)
    google.maps.event.addListener @map, 'zoom_changed', =>
      this._onChangeViewport()
    google.maps.event.addListener @map, 'center_changed', =>
      this._onChangeViewport()
    setTimeout =>
      this._onChangeViewport()
    , 200
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
    clearTimeout(@timeout)
    @timeout = setTimeout =>
      this._fetchClusters()
    , 250
    $('#js-zoomlevel').text(@map.getZoom())

  _fetchClusters: ->
    rect   = this._getViewport()

    $.ajax
      url:      $(@selector).data('points-path')
      data:     rect
      dataType: 'json'
      success:  (data) =>
        this._updateObjects data, @points, (item) =>
          new TsugaPoint(item, @defaultRadius, @map)
        $('#js-point-count').text(data.length)
    $.ajax
      url:      $(@selector).data('clusters-path')
      data:     rect
      dataType: 'json'
      success:  (data) =>
        this._updateObjects data, @clusters, (item) =>
          new TsugaCluster(item, @defaultRadius, @map)
        $('#js-cluster-count').text(data.length)
    $.ajax
      url:      $(@selector).data('tiles-path')
      data:     rect
      dataType: 'json'
      success:  (data) =>
        this._updateTiles(data)


  _updateObjects: (data, collection, factory, updater) ->
    for id, object of collection
      object.dirty = true
    for item in data
      this._log "new object: #{item.lat}, #{item.lng}"
      if old_object = collection[item.id]
        old_object.update(@defaultRadius) # fixme: pass an updater through dependency injection?
      else
        new_object = factory(item)
        new_object.show()
        collection[item.id] = new_object
      collection[item.id].dirty = false
    for id, object of collection
      continue unless object.dirty
      object.hide()
      delete collection[id]


  _setDefaultRadius: ->
    @defaultRadius = google.maps.geometry.spherical.computeDistanceBetween(
      @bounds.getNorthEast(),
      @bounds.getSouthWest()
    ) * 0.01


  _updateTiles: (data) ->
    newTiles = []
    for rect in data
      this._log "new tile: #{rect.n}, #{rect.s}, #{rect.e}, #{rect.w}"
      newTiles.push new TsugaTile(rect, @map)
    for tile in newTiles
      tile.show()
    for tile in @tiles
      tile.hide()
    @tiles = newTiles


  _log: (msg) ->
    # console.log msg




window.TsugaDemo = TsugaDemo
