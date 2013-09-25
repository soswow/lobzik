class app.LoginView extends Backbone.View
  el: "#login"

  events:
    'click .btn': 'clickButton'

  render: ->
    app.mainView.hideSidebar()

  clickButton: ->
    app.mainView.showLoader()