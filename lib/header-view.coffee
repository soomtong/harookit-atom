{CompositeDisposable} = require 'event-kit'

module.exports = class HeaderView extends HTMLElement
  initialize: (@file) ->
    @subscriptions = new CompositeDisposable()

    @classList.add('entry', 'list-nested-item', 'project-root')

    @header = document.createElement('div')
    @header.classList.add('header', 'list-item')

    @directoryName = document.createElement('span')
    @directoryName.classList.add('name', 'icon')

    @entries = document.createElement('ol')
    @entries.classList.add('entries', 'list-tree')

    @directoryName.classList.add('icon-database')
    @directoryName.dataset.id = @file.id
    @directoryName.title = @file.id
    @directoryName.dataset.token = @file.token

    directoryNameTextNode = document.createTextNode(@file.id)

    @appendChild(@header)
    @directoryName.appendChild(directoryNameTextNode)
    @header.appendChild(@directoryName)

module.exports = document.registerElement('harookit-atom-account', prototype: HeaderView.prototype, extends: 'li')
