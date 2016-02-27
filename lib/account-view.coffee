{$, TextEditorView, View}  = require 'atom-space-pen-views'

{CompositeDisposable} = require 'atom'

module.exports = class AccountPanel extends View
  panel: null
  subscriptions: null

  @content: ->
    @div tabIndex: -1, class: 'harookit-atom-account', =>
      @h4 class: 'title', outlet: 'panelTitle'
      @h5 class: 'sub-title', "Haroo Cloud ID"
      @subview 'miniEditorID', new TextEditorView(mini: true, placeholderText: 'HarooCloud ID')
      @h5 class: 'sub-title', "Password"
      @subview 'miniEditorPassword', new TextEditorView(mini: true, placeholderText: 'Password')
      @div class: 'description', "Assign this document's title if you wants"
      @div class: 'btn-group btn-group-options pull-right', =>
        @button class: 'btn submit', outlet: 'submitForm', 'Submit'
        @button class: 'btn', outlet: 'closePanel', 'Close'

  initialize: (state) ->
    console.log state
    @subscriptions = new CompositeDisposable

    @panel = atom.workspace.addModalPanel(item: this, visible: false)

    @subscriptions.add atom.commands.add @element,  # wtf. what is this.element!
      'harookit-atom:focus-next': => @toggleFocus()
      'harookit-atom:focus-previous': => @toggleFocus()

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

  close: ->
    return unless @panel.isVisible()

    miniEditorIDFocused = @miniEditorID.hasFocus()
    miniEditorPasswordFocused = @miniEditorPassword.hasFocus()
    @miniEditorID.setText('')
    @miniEditorPassword.setText('')
    @panel.hide()
    @restoreFocus() if miniEditorIDFocused or miniEditorPasswordFocused

  confirm: ->
    harookitDocumentTitle = @miniEditorID.getText()
    harookitDocumentOptions = {
      useMarkdown: @useMarkdown.hasClass 'selected'
    }
    editor = atom.workspace.getActiveTextEditor()
    # console.log("submit", editor? and harookitDocumentTitle)
    @close()

    return editor? and [harookitDocumentTitle, harookitDocumentOptions]

  showSignIn: ->
    @open('Sign In')

  showSignUp: ->

  storeFocusElement: ->
    @previouslyFocusedElement = $(':focus')

  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.views.getView(atom.workspace).focus()

  setOptionButtonState: (optionButton, selected) ->
    if selected
      optionButton.addClass 'selected'
    else
      optionButton.removeClass 'selected'
