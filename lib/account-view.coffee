{CompositeDisposable} = require 'atom'
{$, TextEditorView, View}  = require 'atom-space-pen-views'

{linkMessage} = require './common'

module.exports = class AccountPanel extends View
  panel: null
  subscriptions: null
  harookitConfig: null
  accessToken: null

  @content: ->
    @div tabIndex: -1, class: 'harookit-atom-account', =>
      @h4 class: 'title', outlet: 'panelTitle'
      @h5 class: 'sub-title', "Haroo Cloud ID"
      @subview 'miniEditorID', new TextEditorView(mini: true, placeholderText: 'HarooCloud ID')
      @h5 class: 'sub-title', "Password"
      @subview 'miniEditorPassword', new TextEditorView(mini: true, placeholderText: 'Password')
      @div class: 'description', =>
        @a href: 'https://haroocloud.com', target: '_blank', 'haroocloud.com'
        @span class: 'more-info', 'for more information or'
        @a href: '#', outlet: 'swapLink', linkMessage.up
      @div class: 'btn-group btn-group-options pull-right', =>
        @button class: 'btn submit', outlet: 'submitForm', 'Submit'
        @button class: 'btn', outlet: 'closePanel', 'Close'

  initialize: (state) ->
    console.log 'initialize()', state
    @subscriptions = new CompositeDisposable

    @panel = atom.workspace.addModalPanel(item: this, visible: false)

    @subscriptions.add atom.commands.add @element,  # wtf. what is this.element!
      'harookit-atom:focus-next': => @toggleFocus()
      'harookit-atom:focus-previous': => @toggleFocus()
    @subscriptions.add @closePanel.on 'click', => @close()
    @subscriptions.add @swapLink.on 'click', => @toggleLink()

    # bind config and token
    @harookitConfig = state.harooCloudConfig

  toggleLink: ->
    if @swapLink.text() == linkMessage.in
      @swapLink.text(linkMessage.up)
      @showSignIn()
    else
      @swapLink.text(linkMessage.in)
      @showSignUp()

  toggleFocus: =>
    console.log 'toggleFocus()'
    if @miniEditorID.hasClass('is-focused')
      @miniEditorPassword.focus()
    else
      @miniEditorID.focus()

  toggle: ->
    if @panel.isVisible()
      @close()
    else
      @open()

  open: (msg) ->
    return if @panel.isVisible()

    @panelTitle.text(msg)
    @storeFocusElement()
    @panel.show()
    @miniEditorID.focus()

  close: (swap = false) ->
    return unless @panel.isVisible()

    console.log 'close()'
    unless swap
      miniEditorIDFocused = @miniEditorID.hasFocus()
      miniEditorPasswordFocused = @miniEditorPassword.hasFocus()
      @miniEditorID.setText('')
      @miniEditorPassword.setText('')
      @restoreFocus() if miniEditorIDFocused or miniEditorPasswordFocused
    @panel.hide()

    #@subscriptions.remove

  showSignIn: ->
    @close(true)
    @open(linkMessage.in)

  showSignUp: ->
    @close(true)
    @open(linkMessage.up)

  storeFocusElement: ->
    @previouslyFocusedElement = $(':focus')

  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.views.getView(atom.workspace).focus()
