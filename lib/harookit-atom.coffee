RepositoryView = require './repository-view'  # can swap repository or account view
AccountView = require './account-view'  # can swap sign-in or sign-up view

{CompositeDisposable} = require 'atom'

module.exports = 
  subscriptions: null
  harookitView:
    account: null
    repository: null
  harookitToken: null

  ### methods ###
  activate: (state) ->
    # each called in activated
    console.info "activate()", state

    @subscriptions = new CompositeDisposable

    # check up access token, is this async?
    @harookitToken = state.accessToken = @getAccessToken()

    if @harookitToken
      @harookitView = new RepositoryView(state)
      @subscriptions.add atom.commands.add 'atom-workspace',
        'harookit:list-show': => @createView().show()
        'harookit:list-toggle': => @createView().toggle()
        'harookit:toggle-side': => @createView().toggleSide()
        'harookit:sign-out': => @signOut()
      @harookitView
    else
      @harookitView.account = new AccountView(state)
      @subscriptions.add atom.commands.add 'atom-workspace',
        'harookit:list-toggle': => @signIn()
        'harookit:sign-in': => @signIn()
        'harookit:sign-up': => @signUp()
        'core:cancel': => @harookitView.account.close()
      @harookitView

  deactivate: ->
    console.info "deactivate()"

    @subscriptions.dispose()
    @harookitView?.deactivate()
    @harookitView = null
    @harookitToken?.deactivate()
    @harookitToken = null

  serialize: ->
    console.log "serialize()"
    if @harookitView?
      @harookitView.serialize()
    else
      @state

  ### methods ###
  getAccessToken: ->
    @harookitToken = atom.config.get('harookit-account-token')

  deleteAccountToken: ->
    atom.config.set('harookit-account-token', null)

  signIn: ->
    console.log "account sign in", @harookitView
    @harookitView.account.showSignIn()

  signUp: ->
    console.log "account sign up", @harookitView
    @harookitView.account.showSignUp()

  signOut: ->
    console.log "account sign out", @harookitView
    @harookitToken = null


  toggleRepository: ->

  togglePanelSide: ->

  showRepository: ->

