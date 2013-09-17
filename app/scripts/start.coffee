$ ->
  app.mainView = new app.MainView()

  Backbone.history.start() #pushState: true
  app.router.navigate '/', trigger: true