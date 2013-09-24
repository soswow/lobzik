class app.ResultView extends Backbone.View
  el: "#result"

  render: ->
    app.mainView.stopTimer()
    $("#loggedin-user").show().find(".email").text app.user.get('email')