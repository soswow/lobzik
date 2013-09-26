class app.ResultView extends Backbone.View
  el: "#result"

  render: ->
    app.mainView.stopTimer()
    $("#finish-button").hide()
    $("#loggedin-user").show().find(".email").text app.user.get('email')
    #'text-success
    testResult = app.user.get('result').test
    @$('.rightAnswers').text testResult.rightAnswers
    @$('.wrongAnswers').text testResult.wrongAnswers
    @$('.missedRightAnswers').text testResult.notGivenRightAnswers
    percent = Math.round(testResult.normScore * 100)
    percent = 0 if percent < 0
    clazz = if percent > 70
        'text-success'
      else if percent > 40
        'text-warning'
      else
        'text-danger'

    @$('.total-score').text("#{percent}%").addClass(clazz)