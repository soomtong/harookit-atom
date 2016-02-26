{$, TextEditorView, View}  = require 'atom-space-pen-views'

module.exports = class AccountPanel extends View
  panel: null

  @content: ->
    @div class: 'harookit-atom-account', =>
      @h4 class: 'title', outlet: 'panelTitle'
      @h5 class: 'sub-title', "Haroo Cloud ID"
      @subview 'miniEditorID', new TextEditorView(mini: true)
      @h5 class: 'sub-title', "Password"
      @subview 'miniEditorPassword', new TextEditorView(mini: true)
      @div class: 'description', "Assign this document's title if you wants"
      @div class: 'btn-group btn-group-options pull-right', =>
        @button class: 'btn submit', outlet: 'submitForm', 'Submit'
        @button class: 'btn', outlet: 'closePanel', 'Close'

  initialize: (state) ->
    console.log state
    @panel = atom.workspace.addModalPanel(item: this, visible: false)

  toggle: ->
    if @panel.isVisible()
      @close()
    else
      @open()

  open: (msg) ->
    return if @panel.isVisible()

    console.info @panelTitle
    @panelTitle.text(msg)
    @storeFocusElement()
    @panel.show()
    @miniEditorID.focus()

  close: ->
    return unless @panel.isVisible()

    #miniEditorFocused = @miniEditor.hasFocus()
    #@miniEditor.setText('')
    @panel.hide()
    #@restoreFocus() if miniEditorFocused

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
