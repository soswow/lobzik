class app.MainView extends Backbone.View

  el: "body > .container"

  events:
    'click .alert .close': 'closeAlert'
    'click #finish-button': 'finishTest'

  initialize: ->
    _.bindAll @, 'drawTimeLeft'
    @$breadcrumb = @$('.breadcrumb')
    @views =
      login: new app.LoginView()
      test: new app.TestView()
      coding: new app.CodingView()
      result: new app.ResultView()
    @$time = @$breadcrumb.find(".time").show()

  startTimer: ->
    app.user.on 'change:durationLeft', @drawTimeLeft, this

  drawTimeLeft: ->
    boldStart = "<span class='bold'>"
    dur = moment.duration app.user.get('durationLeft') * 1000
    if dur is 60
      @alert "One minute left! When it's gone all unsaved data will be lost!", "warning"
    if dur is 0
      @alert "Time's up!", "info"
      return app.router.navigate 'result', trigger: true
    padZero = (num) -> (num < 10 and "0" or "") + num
    time = [padZero(dur.hours()), (dur.minutes() > 0 and boldStart or "") +
    padZero(dur.minutes()), (dur.minutes() is 0 and boldStart or "") +
            padZero(dur.seconds()) + "</span>"].join(":")
    @$time.html time

  stopTimer: ->
    @$breadcrumb.find(".time").hide()
    app.user.off 'change:durationLeft', this

  showLoader: ->
    $("#loader").addClass 'show'

  hideLoader: ->
    $("#loader").removeClass 'show'

  alert: (msg, type) ->
    $(".alert")
      .removeClass('alert-danger alert-info alert-success')
      .addClass("alert-#{type} show")
      .find(".msg").html(msg)
    unless type is 'danger'
      setTimeout @closeAlert, 4000

  closeAlert: ->
    $(".alert").removeClass("show")
    return false

  show: (viewName) ->
    console.log viewName
    app.env.fetch() unless app.env.has 'testQuestions'
    @$breadcrumb.find(".step").removeClass("active").filter(".#{viewName}").addClass("active")
    for name, view of @views
      if name is viewName
        view.$el.show()
        view.render()
      else
        view.$el.hide()

  addMenuLinks: ->
    unless @$breadcrumb.find('a').length
      @$breadcrumb.find('.test span').wrap $("<a href='#test'></a>")
      @$breadcrumb.find('.coding span').wrap $("<a href='#coding'></a>")

  removeMenuLinks: ->
    if @$breadcrumb.find('a').length
      @$breadcrumb.find('.test span, .coding span').unwrap()

  finishTest: ->
    if confirm("There is no way back. Are you sure you are ready?")
      app.mainView.showLoader()
      app.user.save finished: true