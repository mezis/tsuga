tsuga.Views.Map = Backbone.View.extend

  initialize: ->
    this.setElement $('#map-canvas')
    @defaultRadius = null
    @map           = null

    this.listenTo this.model, 'change',          this.render
    this.listenTo this,       'change:viewport', this._onViewportChange
    this.listenTo this,       'idle:viewport',   this._onViewportIdle


  render: ->
    console.log("tsuga.Views.Map#render")
    @map ||= this._getNewMap()

    position = this.model.get('position')
    newCenter = new google.maps.LatLng(position.lat, position.lng)
    currentCenter = @map.getCenter()
    if !currentCenter? || Math.abs(currentCenter.lat() - newCenter.lat()) > 1e-8 || Math.abs(currentCenter.lng() - newCenter.lng()) > 1e-8
      @map.setCenter(newCenter)
    if position.zoom != @map.getZoom()
      @map.setZoom(position.zoom)
    null


  _getNewMap: ->
    mapOptions = 
      mapTypeId:          google.maps.MapTypeId.TERRAIN
      disableDefaultUI:   true
      maxZoom:            19
      minZoom:            2
      mapTypeControl:     true
      overviewMapControl: true
      overviewMapControlOptions:
        opened:           true
      panControl:         false
      rotateControl:      true
      scaleControl:       false
      streetViewControl:  false
      zoomControl:        true

    map = new google.maps.Map(this.el, mapOptions)
    google.maps.event.addListener map, 'bounds_changed', => (this.trigger('change:viewport'))
    google.maps.event.addListener map, 'idle',           => (this.trigger('idle:viewport'))
    return map


  _onViewportChange: ->
    this._delayed =>
      this._updateModel()
      this._setDefaultRadius()


  _onViewportIdle: ->
    $('#js-zoomlevel').text(this.model.get('position').zoom)


  _updateModel: ->
    console.log("tsuga.Views.Map#_updateModel")
    bounds = @map.getBounds()
    this.model.set
      position:
        zoom: @map.getZoom()
        lat:  @map.getCenter().lat()
        lng:  @map.getCenter().lng()
      viewport:
        n:    bounds.getNorthEast().lat()
        e:    bounds.getNorthEast().lng()
        s:    bounds.getSouthWest().lat()
        w:    bounds.getSouthWest().lng()


  _delayed: (callback) ->
    clearTimeout(@timeout) if @timeout
    @timeout = setTimeout ->
      clearTimeout(@timeout) if @timeout
      callback()
    , 250


  _setDefaultRadius: ->
    @defaultRadius = google.maps.geometry.spherical.computeDistanceBetween(
      @map.getBounds().getNorthEast(),
      @map.getBounds().getSouthWest()
    ) * 0.01

