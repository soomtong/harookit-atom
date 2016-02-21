{CompositeDisposable} = require 'event-kit'
Directory = require './directory'
FileView = require './file-view'
{repoForPath} = require './helpers'

class DocumentsView extends HTMLElement
  initialize: (@directory) ->
    @subscriptions = new CompositeDisposable()
    @subscriptions.add @directory.onDidDestroy => @subscriptions.dispose()

    @subscribeToDirectory()

    @classList.add('entry', 'list-nested-item')

    @header = document.createElement('div')
    @header.classList.add('header', 'list-item')

    @directoryName = document.createElement('span')
    @directoryName.classList.add('name', 'icon')

    @entries = document.createElement('ol')
    @entries.classList.add('entries', 'list-tree')

    @appendChild(@entries)

    @draggable = true
    @subscriptions.add @directory.onDidStatusChange => @updateStatus()
    @updateStatus()

    @expand()

  updateStatus: ->
    @classList.remove('status-ignored', 'status-modified', 'status-added')
    @classList.add("status-#{@directory.status}") if @directory.status?

  subscribeToDirectory: ->
    console.log "retrieve haroocloud data"
    @subscriptions.add @directory.onDidAddEntries (addedEntries) =>
      numberOfEntries = @entries.children.length

      for entry in addedEntries
        unless entry instanceof Directory
          view = @createViewForEntry(entry)

          insertionIndex = entry.indexInParentDirectory
          if insertionIndex < numberOfEntries
            @entries.insertBefore(view, @entries.children[insertionIndex])
          else
            @entries.appendChild(view)

          numberOfEntries++

  getPath: ->
    @directory.path

  isPathEqual: (pathToCompare) ->
    @directory.isPathEqual(pathToCompare)

  createViewForEntry: (entry) ->
    view = new FileView()
    view.initialize(entry)
    view

  reload: ->
    @directory.reload() if @isExpanded

  expand: (isRecursive=false) ->
    console.log "expand()", @isExpanded, isRecursive
    unless @isExpanded
      @isExpanded = true
      @directory.expand()

    if isRecursive
      for entry in @entries.children when entry instanceof DocumentsView
        entry.expand(true)

    false


DocumentsElement = document.registerElement('harookit-atom-documents', prototype: DocumentsView.prototype, extends: 'li')
module.exports = DocumentsElement
