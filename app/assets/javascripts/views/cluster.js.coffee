# not a proper backbone view, as there is no backing DOM node
tsuga.Views.Cluster = Backbone.Model.extend

  initialize: (options)->
    @cluster = options.cluster # tsuga.Models.Cluster
    @parent  = options.parent  # tsuga.Views.Map
    @map     = @parent.map     # google.maps.map
    @circle  = null
    @line    = null
    @text    = null

  render: ->
    # console.log 'tsuga.Views.Cluster#render'
    cluster = @cluster.attributes
    center = new google.maps.LatLng(cluster.lat, cluster.lng)

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

    if cluster.parent.lat
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

    google.maps.event.addListener @circle, 'click', => (this._onClick())

    @circle.setMap(@map)
    @line.setMap(@map)  if @line
    @text.open(@map)    if @text


  unrender: ->
    # console.log 'tsuga.Views.Cluster#unrender'
    @circle.setMap(null)
    @line.setMap(null)  if @line
    @text.setMap(null)  if @text



  _onClick: () ->
    # console.log("click on cluster")
    @map.setCenter(@circle.getCenter())
    @map.setZoom(@map.getZoom() + 1)


  _getRadius: (center, cluster) ->
    point = new google.maps.LatLng(cluster.lat + cluster.dlat, cluster.lng + cluster.dlng)
    radius = google.maps.geometry.spherical.computeDistanceBetween(center, point)
    Math.max(radius, @parent.defaultRadius)

