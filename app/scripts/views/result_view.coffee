class app.ResultView extends Backbone.View
  el: "#result"

  writeResultPercent: (part, percent) ->
    percent = 0 if percent < 0
    clazz = if percent > 70
      'text-success'
    else if percent > 40
      'text-warning'
    else
      'text-danger'
    @$(".#{part}-total-score").text("#{percent}%").addClass(clazz)

  render: ->
    app.mainView.stopTimer()
    $("#finish-button").hide()
    app.mainView.renderUser()
    result = app.user.get('result')
    testResult = result.test
    @$('.rightAnswers').text testResult.rightAnswers
    @$('.wrongAnswers').text testResult.wrongAnswers
    @$('.missedRightAnswers').text testResult.notGivenRightAnswers
    testPercent = Math.round(testResult.normScore * 100)
    @writeResultPercent 'test', testPercent

    codingResult = result.coding
    totalSolutions = codingResult.rightSolutions + codingResult.wrongSolutions
    codingPercent = Math.round(codingResult.rightSolutions / totalSolutions * 100)
    @$('.doneSolutions').text codingResult.rightSolutions
    @$('.totalSolutions').text totalSolutions
    @writeResultPercent 'coding', codingPercent