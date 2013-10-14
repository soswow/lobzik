Bugsnag.beforeNotify = (error) ->
  match = error.file.match(/main\.js|vendor\.js/i)
  return match && match[0].length > 0

$(document).ajaxError (event, jqXHR, ajaxSettings, thrownError) ->
  if jqXHR.status is 403 and app.user.id
    alert "You've been logged out. Redirecting you on login page."
    app.user = new app.User()
    app.router.navigate 'page/login', trigger: true

$ ->
  app.mainView = new app.MainView()
  Backbone.history.start() #pushState: true