RepositoryView = require './repository-view'  # can swap repository or account view
AccountView = require './account-view'  # can swap sign-in or sign-up view
{linkMessage} = require './common'
{CompositeDisposable} = require 'atom'

Request = require 'superagent'
Notify = require 'atom-notify'

module.exports = 
  subscriptions: null
  harookitView:
    account: null
    repository: null
  harookitToken: null
  harookitConfig: null

  ### methods ###
  activate: (state) ->
    # each called in activated
    console.info "activate()", state

    @subscriptions = new CompositeDisposable

    # check up access token, is this async?
    @harookitToken = state.accessToken = @getAccessToken()
    @harookitConfig = state.harookitConfig = @refreshConfig()

    if @harookitToken
      @harookitView.repository = new RepositoryView(state)
      @subscriptions.add atom.commands.add 'atom-workspace',
        'harookit:list-show': => @showRepository()
        'harookit:list-toggle': => @toggleRepository()
        'harookit:toggle-side': => @togglePanelSide()
        'harookit:sign-out': => @signOut()
      @harookitView
    else
      @harookitView.account = new AccountView(state)
      @subscriptions.add atom.commands.add 'atom-workspace',
        'harookit:list-toggle': => @signIn()
        'harookit:sign-in': => @signIn()
        'harookit:sign-up': => @signUp()
        'core:cancel': => @harookitView.account.close()
        @subscriptions.add @harookitView.account.submitForm.on 'click', => @submitLink()
        @subscriptions.add atom.commands.add @harookitView.account.miniEditorID.element, 'core:confirm', => @submitLink()
        @subscriptions.add atom.commands.add @harookitView.account.miniEditorPassword.element, 'core:confirm', => @submitLink()

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

  refreshConfig: ->
    console.log 'get config data'
    @harookitConfig =
      apiHost: atom.config.get('harooCloudHost')
      userID: atom.config.get('harooCloudUserId')
      userPassword: atom.config.get('harooCloudUserPassword')

  ### methods ###
  submitLink: ->
    userID = @harookitView.account.miniEditorID.getText()
    userPassword = @harookitView.account.miniEditorPassword.getText()

    @harookitView.account.close()

    notifier = Notify "Harookit"

    console.info @harookitView.account.harookitConfig.host, userID, userPassword

    if @harookitView.account.panelTitle.text() == linkMessage.in
      #url = @harookitConfig.host + '/api/account/login'
      url = 'http://localhost:3030/api/account/login'
    else
      #url = @harookitConfig.host + '/api/account/create'
      url = 'http://localhost:3030/api/account/create'

    Request.post url
    .set 'x-access-host', 'harookit-atom'
    .send
        email: userID
        password: userPassword
    .end (err, result) =>
      console.info err, result
      if !err and result.statusCode == 200
        @harookitToken = result.body.data.access_token
        notifier.addSuccess "Sign in operation Succeed", timeOut: 2000
        @saveAccessToken(@harookitToken)
      else
        notifier.addError "Sign in operation Failed", dismissable: false

  getAccessToken: ->
    @harookitToken = atom.config.get('harookit-account-token')

  deleteAccountToken: ->
    atom.config.set('harookit-account-token', null)

  saveAccessToken: (token) ->
    console.log 'saveAccessToken()'
    atom.config.set('harookit-account-token', token)

  signIn: ->
    console.log "account sign in", @harookitView
    @harookitView.account.showSignIn()

  signUp: ->
    console.log "account sign up", @harookitView
    @harookitView.account.showSignUp()

  signOut: ->
    console.log "account sign out", @harookitView
    @deleteAccountToken()
    @harookitToken = null

  toggleRepository: ->
    @harookitView.repository.toggle()

  togglePanelSide: ->
    @harookitView.repository.toggleSide()

  showRepository: ->
    @harookitView.repository.show()

