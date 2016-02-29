{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

Request = require 'superagent'
Notify = require 'atom-notify'

HeaderView = require './header-view'
ItemView = require './item-view'

module.exports = class RepositoryView extends View
  panel: null
  config: null

  @content: ->
    @div class: 'harookit-atom-resizer tree-view-resizer tool-panel', 'data-show-on-right-side': !atom.config.get('harookit-atom.showOnLeftSide'), =>
      @div class: 'harookit-atom-scroller tree-view-scroller order--center', outlet: 'scroller', =>
        @ol class: 'harookit-atom list-tree focusable-panel', tabindex: -1, outlet: 'list'
      @div class: 'harookit-atom-resize-handle tree-view-resize-handle', outlet: 'resizeHandle'

  initialize: (state) ->
    @disposables = new CompositeDisposable
    @focusAfterAttach = false
    @scrollLeftAfterAttach = -1
    @scrollTopAfterAttach = -1
    @selectedPath = null
    @ignoredPatterns = []

    @documents = []
    @selected = null

    @handleEvents()

    @config = {
      id: atom.config.get('harookit-atom.harooCloudUserId')
      token: atom.config.get('harookit-atom.harooCloudAccessToken')
    }
    @updateRepository()
    @updateItems()

    @width(state.width) if state.width > 0

  updateRepository: (config={}) ->
    repository = new HeaderView()
    repository.initialize({id: @config.id, token: @config.token})
    @list[0].appendChild(repository)
    repository

  updateItems: (accessToken={}) ->
    notifier = Notify "Harookit"

    url = 'http://localhost:3030/api/documents/'
    Request.get url + @config.token
    .set 'x-access-host', 'harookit-atom'
    .end (err, result) =>
      console.info err, result
      if !err and result.statusCode == 200
        console.log result.body.data
      else
        #notifier.addError "Operation Failed", dismissable: false

    results = [
      {
        title: "title 2"
        summery: "summer 2"
        name: "file name 2"
        path: "file path 2"
      }
      {
        title: "title 1"
        summery: "summer 1"
        name: "file name 1"
        path: "file path 1"
      }
    ]

    for entry in results
      @list[0].appendChild(@createViewForEntry(entry))

    if @attachAfterProjectPathSet
      @attach()
      @attachAfterProjectPathSet = false

  createViewForEntry: (entry) ->
    item = new ItemView()
    item.initialize(entry)
    item

  attached: ->
    @focus() if @focusAfterAttach
    @scroller.scrollLeft(@scrollLeftAfterAttach) if @scrollLeftAfterAttach > 0
    @scrollTop(@scrollTopAfterAttach) if @scrollTopAfterAttach > 0

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
    @on 'dblclick', '.harookit-atom-resize-handle', =>
      @resizeToFitContent()
    @on 'mousedown', '.tree-view-resize-handle', (e) =>
      @resizeStarted(e)

    @on 'click', '.entry', (e) =>
      return if e.target.classList.contains('entries')

      @entryClicked(e) unless e.shiftKey or e.metaKey or e.ctrlKey
    @on 'mousedown', '.entry', (e) =>
      @onMouseDown(e)

    atom.commands.add @element,
      'harookit-atom:open-selected-entry': => @openSelectedEntry()

    @disposables.add atom.config.onDidChange 'harookit-atom.showOnLeftSide', ({newValue}) =>
      console.log "toggle showOnLeftSide config data"
      @onSideToggled(newValue)

  toggle: ->
    if @isVisible()
      @detach()
    else
      @show()

  show: ->
    @attach()
    @focus()

  hide: ->
    if @isVisible()
      @detach()

  attach: ->
    @panel ?=
      if atom.config.get('harookit-atom.showOnLeftSide')
        atom.workspace.addLeftPanel(item: this)
      else
        atom.workspace.addRightPanel(item: this)

  detach: ->
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

  resizeStarted: =>
    $(document).on('mousemove', @resizeTreeView)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resizeTreeView)
    $(document).off('mouseup', @resizeStopped)

  resizeTreeView: ({pageX, which}) =>
    return @resizeStopped() unless which is 1

    if !atom.config.get('harookit-atom.showOnLeftSide')
      width = @outerWidth() + @offset().left - pageX
    else
      width = pageX - @offset().left
    @width(width)

  resizeToFitContent: ->
    @width(1) # Shrink to measure the minimum width of list
    @width(@list.outerWidth())

  selectedEntry: ->
    @list[0].querySelector('.selected')

  selectEntry: (entry) ->
    return unless entry? and entry.getPath?

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
    atom.config.set('harookit-atom.showOnLeftSide', not atom.config.get('harookit-atom.showOnLeftSide'))

  onMouseDown: (e) ->
    e.stopPropagation()

    # mouse right click or ctrl click as right click on darwin platforms
    if e.currentTarget.classList.contains('selected') and (e.button is 2 or e.ctrlKey and process.platform is 'darwin')
      console.log "context button clicked!"
      return

    entryToSelect = e.currentTarget
    @selectEntry(entryToSelect)

  entryClicked: (e) ->
    entry = e.currentTarget
    switch e.originalEvent?.detail ? 1
      when 1
        @selectEntry(entry)
        console.log "single clicked: todo) open as pending"
        if entry instanceof ItemView
          if entry.getPath() is atom.workspace.getActivePaneItem()?.getPath?()
            @focus()
          else
            @openedItem = atom.workspace.open(entry.getPath(), pending: true)
      when 2
        console.log "double clicked: todo) open as download"
        if entry instanceof ItemView
          @openedItem.then((item) -> item.terminatePendingState?())
          unless entry.getPath() is atom.workspace.getActivePaneItem()?.getPath?()
            @unfocus()

    false

  openSelectedEntry: (options={}, expandDirectory=false) ->
    selectedEntry = @selectedEntry()
    uri = selectedEntry.getPath()
    item = atom.workspace.getActivePane()?.itemForURI(uri)
    if item? and not options.pending
      item.terminatePendingState?()
    atom.workspace.open(uri, options)

  onSideToggled: (newValue) ->
    @element.dataset.showOnLeftSide = newValue
    if @isVisible()
      @detach()
      @attach()

