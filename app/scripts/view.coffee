class app.LoginView extends Backbone.View
  el: "#login-screen"

  events:
    'click .btn': 'clickButton'

  render: ->
    @$el.show()

  clickButton: (e) ->
    app.mainView.showLoader()


class app.TestingView extends Backbone.View
  el: "#logged-in-screen"

  render: ->
    @$(".email").text app.user.get('email')
    @$el.show()


class app.MainView extends Backbone.View

  el: "body > .container"

  initialize: ->
    @views =
      login: new app.LoginView()
      testing: new app.TestingView()

  showLoader: ->
    $("#loader").addClass 'show'

  hideLoader: ->
    $("#loader").removeClass 'show'

  show: (viewName) ->
#    @currentView = viewName
    for name, view of @views
      if name is viewName
        view.render()
      else
        view.$el.hide()

