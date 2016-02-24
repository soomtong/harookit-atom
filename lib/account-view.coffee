{$, TextEditorView, View}  = require 'atom-space-pen-views'

module.exports =
  class AccountPanel extends View
    @activate: ->
      new AccountPanel

    @content: ->
      @div class: 'harookit-atom', =>
        @h4 class: 'title', outlet: 'status'
        @subview 'miniEditor', new TextEditorView(mini: true)
        @div class: 'description', "Assign this document's title if you wants"
        @div class: 'btn-group btn-group-options pull-right', =>
          @button class: 'btn submit', outlet: 'submitForm', 'Submit'
          @button class: 'btn', outlet: 'closePanel', 'Close'


    initialize: ->
      @panel = atom.workspace.addModalPanel(item: this, visible: false)

      # @miniEditor.on 'blur', =>
      #   console.log "lose focus in editor"
      #   console.log @useMarkdown.hasFocus()
      #   @close()

    toggle: ->
      if @panel.isVisible()
        @close()
      else
        @open()

    close: ->
      return unless @panel.isVisible()

      miniEditorFocused = @miniEditor.hasFocus()
      @miniEditor.setText('')
      @panel.hide()
      @restoreFocus() if miniEditorFocused

    confirm: ->
      harookitDocumentTitle = @miniEditor.getText()
      harookitDocumentOptions = {
        useMarkdown: @useMarkdown.hasClass 'selected'
      }
      editor = atom.workspace.getActiveTextEditor()
      # console.log("submit", editor? and harookitDocumentTitle)
      @close()

      return editor? and [harookitDocumentTitle, harookitDocumentOptions]

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

    open: ->
      return if @panel.isVisible()

      if editor = atom.workspace.getActiveTextEditor()
        @storeFocusElement()
        @panel.show()
        @miniEditor.focus()
