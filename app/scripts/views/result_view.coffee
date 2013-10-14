class app.ResultView extends Backbone.View
  el: "#result"

  writeResultPercent: (percent) ->
    percent = 0 if percent < 0
    clazz = if percent > 70
      'text-success'
    else if percent > 40
      'text-warning'
    else
      'text-danger'
    @$(".total-score").text("#{percent}%").addClass(clazz)

  render: ->
    app.mainView.stopTimer()
    $("#finish-button").hide()
    app.mainView.renderUser()
    result = app.user.get('result')
    testResult = result.test
    @$('.rightAnswers').text testResult.rightAnswers
    @$('.wrongAnswers').text testResult.wrongAnswers
    @$('.missedRightAnswers').text testResult.notGivenRightAnswers
    @$('.totalRightAnswers').text testResult.rightAnswers + testResult.notGivenRightAnswers
    testPercent = Math.round(testResult.normScore * 100)
    codingResult = result.coding
    totalSolutions = codingResult.rightSolutions + codingResult.wrongSolutions
    codingPercent = Math.round(codingResult.rightSolutions / totalSolutions * 100)
    totalPercent = Math.round((testPercent + codingPercent) / 2)
    @writeResultPercent totalPercent
    messageBox =
      if totalPercent <= 59
        @$(".bad.message")
      else if 59 < totalPercent < 75
        @$(".ok.message")
      else
        @$(".good.message")
    messageBox.removeClass 'hide'


    @$('.doneSolutions').text codingResult.rightSolutions
    @$('.totalSolutions').text totalSolutions

    dur = moment.duration(app.user.get('durationTook'), 'milliseconds')
    @$(".took-time").text "#{Math.round(dur.asMinutes())} minutes"