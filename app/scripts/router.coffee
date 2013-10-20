class app.Router extends Backbone.Router
  routes:
    'page/login': 'login'
    'page/test': 'test'
    'page/coding': 'coding'
    'page/result': 'result'
    'page/admin': 'admin'
    '*path':  'login'

  goto: (page) -> @navigate page, trigger: true

  securedPage: (cb) ->
    unless app.user.id
      app.mainView.showLoader()
      app.user.fetch
        success: ->
          app.mainView.hideLoader()
          cb()
        error: =>
          app.mainView.show 'login'
          @navigate 'page/login'
          app.mainView.hideLoader()
    else
      cb()

  testAndCoding: (page) ->
    @securedPage =>
      unless app.user.get('finished')
        app.mainView.addMenuLinks()
        app.mainView.showSidebar()
        app.mainView.show page
        @navigate 'page/' + page
      else
        @goto 'page/result'

  login: -> @testAndCoding 'test'
  test: -> @testAndCoding 'test'
  coding: -> @testAndCoding 'coding'

  result: ->
    @securedPage =>
      if app.user.get('finished')
        app.mainView.removeMenuLinks()
        app.mainView.showSidebar()
        app.mainView.show 'result'
      else
        @goto 'test'

  admin: ->
    @securedPage =>
      if app.user?.get('isAdmin')
        app.mainView.show 'admin'

app.router = new app.Router()