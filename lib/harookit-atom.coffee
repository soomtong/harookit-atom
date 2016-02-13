HarookitAtomView = require './harookit-atom-view'
{CompositeDisposable} = require 'atom'

module.exports = HarookitAtom =
  harookitAtomView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @harookitAtomView = new HarookitAtomView(state.harookitAtomViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @harookitAtomView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'harookit-atom:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @harookitAtomView.destroy()

  serialize: ->
    harookitAtomViewState: @harookitAtomView.serialize()

  toggle: ->
    console.log 'HarookitAtom was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
