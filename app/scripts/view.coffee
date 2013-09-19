class app.LoginView extends Backbone.View
  el: "#login"

  events:
    'click .btn': 'clickButton'

  render: ->

  clickButton: (e) ->
    app.mainView.showLoader()


class app.TestView extends Backbone.View
  el: "#test"

  render: ->
    app.mainView.startTimer()
    $("#loggedin-user").show().find(".email").text app.user.get('email')


class app.ResultView extends Backbone.View
  el: "#result"

  render: ->
    app.mainView.stopTimer()
    $("#loggedin-user").show().find(".email").text app.user.get('email')


class app.MainView extends Backbone.View

  el: "body > .container"

  initialize: ->
    @$breadcrumb = @$('.breadcrumb')
    @views =
      login: new app.LoginView()
      test: new app.TestView()
      result: new app.ResultView()

  startTimer: ->
    $time = @$breadcrumb.find(".time").show()
    clearInterval @timerInterval if @timerInterval
    maxDuration = 30 * 60 * 1000
    padZero = (num) -> (num < 10 and "0" or "") + num
    boldStart = "<span class='bold'>"
    @timerInterval = setInterval ( ->
      diff = maxDuration - moment().diff app.user.get 'startedAt'
      diff = 0 if diff <= 0
      dur = moment.duration diff
      time = [padZero(dur.hours()), (dur.minutes() > 0 and boldStart or "") +
              padZero(dur.minutes()), (dur.minutes() is 0 and boldStart or "") +
              padZero(dur.seconds()) + "</span>"].join(":")
      $time.html time
      clearInterval @timerInterval if dur is 0
    ), 200

  stopTimer: ->
    clearInterval @timerInterval if @timerInterval
    @$breadcrumb.find(".time").hide()

  showLoader: ->
    $("#loader").addClass 'show'

  hideLoader: ->
    $("#loader").removeClass 'show'

  show: (viewName) ->
#    @currentView = viewName
    @$breadcrumb.find(".step").removeClass("active").filter(".#{viewName}").addClass("active")
#    @$breadcrumb.find(".step.#{viewName} span").wrap("<a href='#'></a>")
    for name, view of @views
      if name is viewName
        view.render()
        view.$el.show()
      else
        view.$el.hide()

