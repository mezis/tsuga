tsuga.Routers.Map = Backbone.Router.extend

  routes: {
    ':zoom/:lat/:lng': '_panMapAction',
    '*path':           '_panMapDefaultAction'
  }

  initialize: ->
    @map          = new tsuga.Models.Map()
    @view         = new tsuga.Views.Map({ model: @map })
    @clusters     = new tsuga.Collections.Clusters()
    @clustersView = new tsuga.Views.Clusters({ parent: @view, clusters: @clusters })

    this.listenTo @map,      'change:position', this._updateNavigation
    this.listenTo @map,      'change:position', this._updateClusters

    this.listenToOnce @view, 'idle:viewport', =>
      console.log '*** first update'
      this._updateNavigation()
      this._updateClusters()

    @view.render()
    console.log 'tsuga.Routers.Map#initialize done'


  _panMapDefaultAction: ->
    console.log 'tsuga.Routers.Map#_panMapDefaultAction'
    @map.set 'position', @map.defaults().position


  _panMapAction: (zoom, lat, lng) ->
    console.log 'tsuga.Routers.Map#_panMapAction'
    @map.set 'position',
      zoom: parseInt(zoom)
      lat:  parseFloat(lat)
      lng:  parseFloat(lng)


  _updateNavigation: ->
    console.log 'tsuga.Routers.Map#_updateNavigation'
    position = @map.get('position')
    this.navigate "#{position.zoom}/#{position.lat}/#{position.lng}",
      trigger: false


  _updateClusters: ->
    console.log 'tsuga.Routers.Map#_updateClusters'
    pos = @map.get('position')
    v   = @map.get('viewport')

    position = @map.get('position')
    viewport = @map.get('viewport')
    @clusters.fetch
      data:
        z:   position.zoom
        n:   viewport.n
        s:   viewport.s
        e:   viewport.e
        w:   viewport.w
