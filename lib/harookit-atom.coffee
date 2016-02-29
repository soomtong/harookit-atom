RepositoryView = require './repository-view' # can swap repository or account view
AccountView = require './account-view' # can swap sign-in or sign-up view
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

# tier 1 #
  activate: (state) ->
    # each called in activated
    console.info "activate()", state

    @subscriptions = new CompositeDisposable

    @harookitView.repository = new RepositoryView(state)

    @subscriptions.add atom.commands.add 'atom-workspace',
      'harookit:list-show': => @showRepository()
      'harookit:list-toggle': => @toggleRepository()
      'harookit:toggle-side': => @togglePanelSide()

    @harookitView.account = new AccountView()

    @subscriptions.add atom.commands.add 'atom-workspace',
      'harookit:sign-out': => @signOut()
      'harookit:sign-in': => @signIn()
      'harookit:sign-up': => @signUp()
      'core:cancel': => @harookitView.account.close()

    @subscriptions.add @harookitView.account.submitForm.on 'click', =>
      @submitLink()
    @subscriptions.add atom.commands.add @harookitView.account.miniEditorID.element, 'core:confirm', =>
      @submitLink()
    @subscriptions.add atom.commands.add @harookitView.account.miniEditorPassword.element, 'core:confirm', =>
      @submitLink()

  deactivate: ->
    console.info "deactivate()"

    @subscriptions.dispose()

  serialize: ->
    console.log "serialize()"

# tier 2 #
  submitLink: ->
    userID = @harookitView.account.miniEditorID.getText().trim()
    userPassword = @harookitView.account.miniEditorPassword.getText().trim()

    @harookitView.account.close()

    notifier = Notify "Harookit"

    console.info @harookitView.account.harookitConfig, userID, userPassword

    if @harookitView.account.panelTitle.text() == linkMessage.in
      #url = @harookitConfig.host + '/api/account/login'
      url = 'http://localhost:3030/api/account/login'
      op = linkMessage.in
    else
      #url = @harookitConfig.host + '/api/account/create'
      url = 'http://localhost:3030/api/account/create'
      op = linkMessage.up

    Request.post url
    .set 'x-access-host', 'harookit-atom'
    .send
        email: userID
        password: userPassword
    .end (err, result) =>
      console.info err, result
      if !err and result.statusCode == 200
        notifier.addSuccess op + "operation Succeed", timeOut: 2000
        atom.config.set('harookit-atom.harooCloudUserId', userID)
        atom.config.set('harookit-atom.harooCloudUserPassword', userPassword)
        @harookitToken = result.body.data.access_token
        @saveAccessToken(@harookitToken)
      else
        notifier.addError op + "operation Failed", dismissable: false

  getAccessToken: ->
    @harookitToken = atom.config.get('harookit-atom.harooCloudAccessToken') || ''

  deleteAccountToken: ->
    atom.config.set('harookit-atom.harooCloudAccessToken', null)

  saveAccessToken: (token) ->
    console.log 'saveAccessToken()', token
    atom.config.set('harookit-atom.harooCloudAccessToken', token)

  signIn: ->
    console.log "account sign in", @harookitView
    @harookitView.account.showSignIn()

  signUp: ->
    console.log "account sign up", @harookitView
    @harookitView.account.showSignUp()

  signOut: ->
    console.log "account sign out", @harookitView
    @harookitToken = null
    @harookitView.repository.hide()
    @deleteAccountToken()

  toggleRepository: ->
    @harookitView.repository.toggle()

  togglePanelSide: ->
    @harookitView.repository.toggleSide()

  showRepository: ->
    @harookitView.repository.show()
