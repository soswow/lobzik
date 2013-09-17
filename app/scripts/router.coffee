class app.Router extends Backbone.Router
  routes:
    "search/:query":  "index"
    "search/:query/p:page": "index"
    "*path":  "index"

  index: ->
    console.log "index"
    unless app.user.id
      app.mainView.showLoader()
      app.user.fetch
        success: ->
          app.mainView.hideLoader()
          app.mainView.show 'testing'
#          $("#logged-in-screen").show().find('.email').text(data.email)
        error: ->
          app.mainView.hideLoader()
          app.mainView.show 'login'

app.router = new app.Router()