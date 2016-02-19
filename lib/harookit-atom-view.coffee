{BufferedProcess, CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

LocalStorage = window.localStorage

toggleConfig = (keyPath) ->
  atom.config.set(keyPath, not atom.config.get(keyPath))

module.exports =
class HarookitAtomView extends View
  panel: null

  @content: ->
    @div class: 'harookit-list-resizer tool-panel', 'data-show-on-left-side': atom.config.get('harookit-atom.showOnLeftSide'), =>
      @div class: 'harookit-list-scroller order--center', outlet: 'scroller', =>
        @ol class: 'harookit-list full-menu list-tree has-collapsable-children focusable-panel', tabindex: -1, outlet: 'list'
      @div class: 'harookit-list-resize-handle', outlet: 'resizeHandle'

  initialize: (state) ->
    console.log "initialized()", state
    @disposables = new CompositeDisposable
    @focusAfterAttach = false
    @documents = []
    @scrollLeftAfterAttach = -1
    @scrollTopAfterAttach = -1
    @selected = null

    @handleEvents()

    @updateList(state.harooCloudConfig)

    @width(state.width) if state.width > 0

  attached: ->
    console.log "attached()"
    @focus() if @focusAfterAttach
    @scroller.scrollLeft(@scrollLeftAfterAttach) if @scrollLeftAfterAttach > 0
    @scrollTop(@scrollTopAfterAttach) if @scrollTopAfterAttach > 0

  updateList: (config) ->
    console.log 'updateList()', config
    @documents = [
      { name: 'untitled 1', title: 'No one exist here', createdAt: new Date() }
      { name: 'untitled 2', title: 'No one exist here', createdAt: new Date() }
      { name: 'untitled 3', title: 'No one exist here', createdAt: new Date() }
      { name: 'untitled 4', title: 'No one exist here', createdAt: new Date() }
    ]

  detached: ->
    console.log "detached()"

  serialize: ->
    console.log "serialize()"
    harooCloudConfig: {
      host: atom.config.get('harookit-atom.harooCloudHost')
      id: atom.config.get('harookit-atom.harooCloudUserId')
      password: atom.config.get('harookit-atom.harooCloudUserPassword')
      side: atom.config.get('harookit-atom.showOnLeftSide')
    }
    hasFocus: @hasFocus()
    attached: @panel?
    scrollLeft: @scroller.scrollLeft()
    scrollTop: @scrollTop()
    width: @width()

  deactivate: ->
    @disposables.dispose()
    @detach() if @panel?

  handleEvents: ->
    console.log "bind Event"
    @disposables.add atom.config.onDidChange 'harookit-atom.showOnLeftSide', ({newValue}) =>
      console.log "toggle showOnLeftSide config data"
      @onSideToggled(newValue)

  toggle: ->
    console.log "toggle()"
    if @isVisible()
      @detach()
    else
      @show()

  show: ->
    console.log "show()"
    @attach()
    @focus()

  attach: ->
    console.log "attach()"
    @panel ?=
      if atom.config.get('harookit-atom.showOnLeftSide')
        atom.workspace.addLeftPanel(item: this)
      else
        atom.workspace.addRightPanel(item: this)

  detach: ->
    console.log "detach()"
    @scrollLeftAfterAttach = @scroller.scrollLeft()
    @scrollTopAfterAttach = @scrollTop()

    @panel.destroy()
    @panel = null
    @unfocus()

  focus: ->
    @list.focus()

  unfocus: ->
    atom.workspace.getActivePane().activate()

  hasFocus: ->
    @list.is(':focus') or document.activeElement is @list[0]

  toggleFocus: ->
    if @hasFocus()
      @unfocus()
    else
      @show()

  selectedEntry: ->
    @list[0].querySelector('.selected')

  selectEntry: (entry) ->
    return unless entry?

    @selectedPath = entry.getPath()

    selectedEntries = @getSelectedEntries()
    if selectedEntries.length > 1 or selectedEntries[0] isnt entry
      @deselect(selectedEntries)
      entry.classList.add('selected')
    entry

  getSelectedEntries: ->
    @list[0].querySelectorAll('.selected')

  deselect: (elementsToDeselect=@getSelectedEntries()) ->
    selected.classList.remove('selected') for selected in elementsToDeselect
    undefined

  toggleSide: ->
    toggleConfig('harookit-atom.showOnLeftSide')

  onSideToggled: (newValue) ->
    @element.dataset.showOnLeftSide = newValue
    if @isVisible()
      @detach()
      @attach()

