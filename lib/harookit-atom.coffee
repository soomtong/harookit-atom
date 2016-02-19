{CompositeDisposable} = require 'atom'

module.exports = 
  harookitView: null
  subscriptions: null

  activate: (@state) ->
    @subscriptions = new CompositeDisposable
    @state.attached ?= true if @shouldAttach()

    @createView() if @state.attached

    @subscriptions.add atom.commands.add('atom-workspace', {
      'harookit:list-show': => @createView().show()
      'harookit:list-toggle': => @createView().toggle()
      'harookit:toggle-side': => @createView().toggleSide()
    })

  deactivate: ->
    @subscriptions.dispose()
    @harookitView?.deactivate()
    @harookitView = null

  serialize: ->
    console.log "serialize()"
    if @harookitView?
      @harookitView.serialize()
    else
      @state

  createView: ->
    console.log "createView()"
    unless @harookitView?
      HarookitView = require './harookit-atom-view'
      @harookitView = new HarookitView(@state)
    @harookitView

  shouldAttach: ->
    console.log "shouldAttach()", atom.project.getPaths()[0]
    if atom.workspace.getActivePaneItem()
      false
    else
      true