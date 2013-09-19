class app.LoginView extends Backbone.View
  el: "#login"

  events:
    'click .btn': 'clickButton'

  render: ->

  clickButton: ->
    app.mainView.showLoader()


class app.TestView extends Backbone.View
  el: "#test"

  events:
    'click .pagination a.page': 'changeQuestionPage'
    'click .pagination a.next': 'nextQuestion'

  paginatorTemplate: _.template $("#pagination-tmpl").html()
  questionTemplate: _.template $("#test-question-tmpl").html()

  questions: []
  initialize: ->
    @currentQuestion = 1
    app.env.on 'sync', =>
      if app.env.get('testQuestions')
        @questions = app.env.get('testQuestions')
        @renderQuestions()
    app.user.on 'sync', =>
      if app.user.id
        @renderUser()

  renderUser: ->
    app.mainView.startTimer()
    $("#loggedin-user").show().find(".email").text app.user.get('email')

  renderPaginator: ->
    @$('.pagination-js').html @paginatorTemplate max: @questions.length, current: @currentQuestion

  changeQuestionPage: (e) ->
    @currentQuestion = $(e.currentTarget).data "index"
    @renderPaginator()
    @showCurrentQuestion()

  nextQuestion: (e) ->
    if @currentQuestion is @questions.length
      #Open Code assignments
    else
      @currentQuestion += 1
      @renderPaginator()
      @showCurrentQuestion()

  showCurrentQuestion: ->
    @$(".questions .question").hide().filter("." + @questions[@currentQuestion-1].name).show()

  renderQuestions: ->
    @renderPaginator()
    $questions = @$(".questions").empty()
    for question in @questions
      $questions.append @questionTemplate question
    @showCurrentQuestion()


class app.TestQuestionView extends Backbone.View

  render: ->


class app.ResultView extends Backbone.View
  el: "#result"

  render: ->
    app.mainView.stopTimer()
    $("#loggedin-user").show().find(".email").text app.user.get('email')


class app.MainView extends Backbone.View

  el: "body > .container"

  initialize: ->
    _.bindAll @, 'drawTimeLeft'
    @$breadcrumb = @$('.breadcrumb')
    @views =
      login: new app.LoginView()
      test: new app.TestView()
      result: new app.ResultView()
    @$time = @$breadcrumb.find(".time").show()

  startTimer: ->
    app.user.on 'change:durationLeft', @drawTimeLeft, this

  drawTimeLeft: ->
    boldStart = "<span class='bold'>"
    dur = moment.duration app.user.get('durationLeft') * 1000
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

