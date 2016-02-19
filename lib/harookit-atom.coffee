{CompositeDisposable} = require 'atom'

module.exports = HarookitAtom =
  listView: null
  subscriptions: null

  activate: (@state) ->
    @subscriptions = new CompositeDisposable
    @state.attached ?= true if @shouldAttach()

    @createView() if @state.attached

    @subscriptions.add atom.commands.add('atom-workspace', {
      'harookit:list-show': => @createView().show()
      'harookit:list-toggle': => @createView().toggle()
    })

  deactivate: ->
    @subscriptions.dispose()
    @listView?.deactivate()
    @listView = null

  serialize: ->
    if @listView?
      @listView.serialize()
    else
      @state

  createView: ->
    unless @listView?
      ListView = require './harookit-atom-view'
      @listView = new ListView(@state)
    @listView

  shouldAttach: ->
    projectPath = atom.project.getPaths()[0]
    if atom.workspace.getActivePaneItem()
      false
    else if path.basename(projectPath) is '.git'
      projectPath is atom.getLoadSettings().pathToOpen
    else
      true
