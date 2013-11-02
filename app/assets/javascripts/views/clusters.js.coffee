# not a proper backbone view, as there is no backing DOM node
tsuga.Views.Clusters = Backbone.Model.extend

  initialize: (options)->
    @clusters = options.clusters # tsuga.Collections.Clusters
    @parent   = options.parent   # tsuga.Views.Map
    @views    = {}               # of tsuga.Views.Cluster

    this.listenTo @clusters, 'add',    this._addCluster
    this.listenTo @clusters, 'remove', this._removeCluster
    this.listenTo @clusters, 'all',    this._updateCounters


  render: ->
    null


  _addCluster: (cluster, collection) ->
    # console.log '_addCluster'
    view = new tsuga.Views.Cluster
      cluster:  cluster
      parent:   @parent
    view.render()
    @views[cluster.id] = view


  _removeCluster: (cluster, collection) ->
    # console.log '_removeCluster'
    view = @views[cluster.id]
    return unless view
    view.unrender()
    delete @views[cluster.id]


  _updateCounters: ->
    this._delayed =>
      $('#js-cluster-count').text(@clusters.size())      


  # FIXME: this shoud be factored out in a mixin
  _delayed: (callback, time) ->
    duration = 250 unless duration?
    clearTimeout(@timeout) if @timeout
    @timeout = setTimeout ->
      clearTimeout(@timeout) if @timeout
      callback()
    , duration
