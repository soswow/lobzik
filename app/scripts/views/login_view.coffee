class app.LoginView extends Backbone.View
  el: "#login"

  events:
    'click .btn': 'clickButton'

  render: ->

  clickButton: ->
    app.mainView.showLoader()