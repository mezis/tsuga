# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class TsugaCluster
  constructor: (cluster, @defaultRadius, @map) ->
    @circle = null
    @line   = null
    @text   = null

    center    = new google.maps.LatLng(cluster.lat, cluster.lng)
    if cluster.weight == 1
      fillColor = '#ff00ff'
      radius    = @defaultRadius
    else
      fillColor = '#ff0000'
      radius    = this._getRadius(center, cluster)
    options =
      strokeOpacity:  0.0
      fillColor:      fillColor
      fillOpacity:    0.2
      center:         center
      radius:         radius
    @circle = new google.maps.Circle(options)
    @circle.cluster = this

    if cluster.parent
      parent = new google.maps.LatLng(cluster.parent.lat, cluster.parent.lng)
      @line = new google.maps.Polyline
        path:           [center, parent]
        geodesic:       true
        strokeColor:    fillColor,
        strokeOpacity:  0.2
        strokeWeight:   2

    if cluster.weight > 1
      textOptions =
        content:        cluster.weight,
        boxClass:       'cluster-info'
        disableAutoPan: true,
        pixelOffset:    new google.maps.Size(-45, -9),
        position:       center,
        closeBoxURL:    '',
        isHidden:       false,
        enableEventPropagation: true
      @text = new InfoBox(textOptions)

    google.maps.event.addListener @circle, 'click', this._onClickClosure

  show: ->
    @circle.setMap(@map)
    @line.setMap(@map) if @line
    @text.open(@map) if @text
  hide: ->
    @circle.setMap(null)
    @line.setMap(null) if @line
    @text.setMap(null) if @text
  update: (radius) ->
    null

  _onClickClosure: (event) ->
    this.cluster._onClick()
  _onClick: () ->
    @map.setCenter(@circle.getCenter())
    @map.setZoom(@map.getZoom() + 1)

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
      strokeOpacity:  0.2
      strokeWeight:   3

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
      this._runUpdate()
    , 250
    $('#js-zoomlevel').text(@map.getZoom())

  _runUpdate: ->
    rect = this._getViewport()
    this._updateTiles(rect)
    this._updateClusters(rect)

  _updateClusters: (rect) ->
    $.ajax
      url:      $(@selector).data('clusters-path')
      data:     rect
      dataType: 'json'
      success:  (data) =>
        this._updateObjects data, @clusters, (item) =>
          new TsugaCluster(item, @defaultRadius, @map)
        $('#js-cluster-count').text(data.length)

        pointsCount = this._totalWeight(data)
        this._log("total weight: #{pointsCount}")
        if pointsCount < 250
          this._updatePoints(rect)
        else
          $('#js-point-count').text("#{pointsCount} (hidden)")
          this._removePoints()


  _totalWeight: (data) ->
    weight = 0
    for id, cluster of data
      weight += cluster.weight
    return weight


  _updateTiles: (rect) ->
    this._log "_updateTiles"
    $.ajax
      url:      $(@selector).data('tiles-path')
      data:     rect
      dataType: 'json'
      success:  (data) =>
        newTiles = []
        for rect in data
          newTiles.push new TsugaTile(rect, @map)
        for tile in newTiles
          tile.show()
        for tile in @tiles
          tile.hide()
        @tiles = newTiles


  _updatePoints: (rect) ->
    $.ajax
      url:      $(@selector).data('points-path')
      data:     rect
      dataType: 'json'
      success:  (data) =>
        this._updateObjects data, @points, (item) =>
          new TsugaPoint(item, @defaultRadius, @map)
        $('#js-point-count').text(data.length)


  _removePoints: ->
    this._log("remove all points")
    this._updateObjects [], @points


  _updateObjects: (data, collection, factory) ->
    for id, object of collection
      object.dirty = true
    for item in data
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


  _log: (msg) ->
    console.log msg


window.tsuga =  
  Demo: TsugaDemo
