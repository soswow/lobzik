class app.ResultView extends Backbone.View
  el: "#result"

  render: ->
    app.mainView.stopTimer()
    $("#finish-button").hide()
    $("#loggedin-user").show().find(".email").text app.user.get('email')