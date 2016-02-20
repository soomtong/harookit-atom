path = require 'path'
shell = require 'shell'

_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'
fs = require 'fs-plus'

LocalStorage = window.localStorage

DocumentView = require './document-view'
Directory = require './directory'
DirectoryView = require './directory-view'
FileView = require './file-view'

toggleConfig = (keyPath) ->
  atom.config.set(keyPath, not atom.config.get(keyPath))

module.exports =
class HarookitAtomView extends View
  panel: null

  @content: ->
    @div class: 'harookit-atom-resizer tree-view-resizer tool-panel', 'data-show-on-right-side': !atom.config.get('harookit-atom.showOnLeftSide'), =>
      @div class: 'harookit-atom-scroller tree-view-scroller order--center', outlet: 'scroller', =>
        @ol class: 'harookit-atom list-tree has-collapsable-children focusable-panel', tabindex: -1, outlet: 'list'
      @div class: 'harookit-atom-resize-handle tree-view-resize-handle', outlet: 'resizeHandle'

  initialize: (state) ->
    console.log "initialized()", state
    @disposables = new CompositeDisposable
    @focusAfterAttach = false
    @roots = []
    @scrollLeftAfterAttach = -1
    @scrollTopAfterAttach = -1
    @selectedPath = null
    @ignoredPatterns = []

    @documents = []
    @selected = null

    @handleEvents()

#    @updateList(state.harooCloudConfig)

    @updateRoots(state.directoryExpansionStates)
#    @selectEntry(@roots[0])

    @width(state.width) if state.width > 0

  loadIgnoredPatterns: ->
    @ignoredPatterns.length = 0
    return unless atom.config.get('tree-view.hideIgnoredNames')

#    Minimatch ?= require('minimatch').Minimatch

    ignoredNames = atom.config.get('core.ignoredNames') ? []
    ignoredNames = [ignoredNames] if typeof ignoredNames is 'string'
    for ignoredName in ignoredNames when ignoredName
      try
        @ignoredPatterns.push({})
      catch error
        atom.notifications.addWarning("Error parsing ignore pattern (#{ignoredName})", detail: error.message)

  updateRoots: (expansionStates={}) ->
    oldExpansionStates = {}
    for root in @roots
      oldExpansionStates[root.directory.path] = root.directory.serializeExpansionState()
      root.directory.destroy()
      root.remove()

    @loadIgnoredPatterns()

    @roots = for projectPath in atom.project.getPaths()
      directory = new Directory({
        name: path.basename(projectPath)
        fullPath: projectPath
        symlink: false
        isRoot: true
        expansionState: expansionStates[projectPath] ?
          oldExpansionStates[projectPath] ?
        {isExpanded: true}
        @ignoredPatterns
      })
      root = new DirectoryView()
      root.initialize(directory)
      @list[0].appendChild(root)
      root

    if @attachAfterProjectPathSet
      @attach()
      @attachAfterProjectPathSet = false

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
    @on 'dblclick', '.harookit-atom-resize-handle', =>
      @resizeToFitContent()
    @on 'mousedown', '.tree-view-resize-handle', (e) =>
      @resizeStarted(e)

    @on 'click', '.entry', (e) =>
      return if e.target.classList.contains('entries')

      @entryClicked(e) unless e.shiftKey or e.metaKey or e.ctrlKey
    @on 'mousedown', '.entry', (e) =>
      @onMouseDown(e)

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

  onMouseDown: (e) ->
    e.stopPropagation()
    console.log "onMouseDown(e)"

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
        console.log "1: select entry! from entryClicked(e)"
#        if entry instanceof FileView
#          if entry.getPath() is atom.workspace.getActivePaneItem()?.getPath?()
#            @focus()
#          else
#            @openedItem = atom.workspace.open(entry.getPath(), pending: true)
#        else if entry instanceof DirectoryView
#          entry.toggleExpansion(isRecursive)
      when 2
        console.log "2: select entry! from entryClicked(e)"
#        if entry instanceof FileView
#          @openedItem.then((item) -> item.terminatePendingState?())
#          unless entry.getPath() is atom.workspace.getActivePaneItem()?.getPath?()
#            @unfocus()
#        else if entry instanceof DirectoryView
#          entry.toggleExpansion(isRecursive)

    false


  onSideToggled: (newValue) ->
    @element.dataset.showOnLeftSide = newValue
    if @isVisible()
      @detach()
      @attach()

