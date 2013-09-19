class app.Router extends Backbone.Router
  routes:
#    "search/:query":  "index"
#    "search/:query/p:page": "index"
#    "login":  "login"
#    "test":  "test"
#    "result":  "result"
    "*path":  "redirect"

  redirectUser: (page) ->
    if app.user.get('finished')
      @navigate 'result'
      app.mainView.show 'result'
    else
      @navigate 'test'
      app.mainView.show 'test'

  redirect: (page) ->
    if app.user.id
      @redirectUser page
    else
      app.mainView.showLoader()
      app.user.fetch
        success: =>
          app.mainView.hideLoader()
          @redirectUser page
        error: =>
          app.mainView.hideLoader()
          @navigate 'login'
          app.mainView.show 'login'

app.router = new app.Router()