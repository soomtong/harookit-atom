RepositoryView = require './repository-view'
AccountView = require './account-view'

{CompositeDisposable} = require 'atom'

module.exports = 
  subscriptions: null
  harookitView: null
  harookitToken: null

  activate: (@state) ->
    console.info "activate()"

    @subscriptions = new CompositeDisposable

#    @state.attached ?= true if @shouldAttach()
    @state.accessToken = @getAccessToken()

#    console.log  @state.attached
#    @createView() if @state.attached

    @createView()

  deactivate: ->
    console.info "deactivate()"

    @subscriptions.dispose()
    @harookitView?.deactivate()
    @harookitView = null

  serialize: ->
    console.log "serialize()"
    if @harookitView?
      @harookitView.serialize()
    else
      @state

  getAccessToken: ->
    @harookitToken = atom.config.get('harookit-account-token')

  createView: ->
    console.info "createView()"
    if @harookitToken
      @subscriptions.add atom.commands.add('atom-workspace', {
        'harookit:list-show': => @createView().show()
        'harookit:list-toggle': => @createView().toggle()
        'harookit:toggle-side': => @createView().toggleSide()
        'harookit:sign-out': => @signOut()
      })
      @harookitView = new RepositoryView(@state)
      @harookitView
    else
      @subscriptions.add atom.commands.add('atom-workspace', {
        'harookit:list-toggle': => @signIn()
        'harookit:sign-in': => @signIn()
        'harookit:sign-up': => @signUp()
      })

  shouldAttach: ->
    console.log "shouldAttach()", atom.workspace.getActivePaneItem()
    if atom.workspace.getActivePaneItem()
      false
    else
      true

  signIn: ->
    console.log "account sign in", @harookitView
    @harookitView = AccountView.activate()
    @harookitView.toggle()
    console.log 'go sign in'

  signUp: ->

  signOut: ->
