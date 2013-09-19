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
    if app.env.has 'testQuestions'
      @renderQuestions()
    else
      app.env.on 'change:testQuestions', =>
        @renderQuestions()

    app.user.on 'change:id', =>
      @renderUser()

  renderUser: ->
    app.mainView.startTimer()
    $("#loggedin-user").show().find(".email").text app.user.get('email')

  renderPaginator: ->
    @$('.pagination-js').html @paginatorTemplate
      max: @questions.length
      current: @currentQuestion
      labels: []
      nextLabel: 'Next'

  changeQuestionPage: (e) ->
    @currentQuestion = $(e.currentTarget).data "index"
    @renderPaginator()
    @showCurrentQuestion()
    return false

  nextQuestion: ->
    if @currentQuestion is @questions.length
      app.router.navigate 'coding', trigger: true
    else
      @currentQuestion += 1
      @renderPaginator()
      @showCurrentQuestion()
    return false

  showCurrentQuestion: ->
    @$(".questions .question").hide().filter("." + @questions[@currentQuestion-1].name).show()

  renderQuestions: ->
    @questions = app.env.get('testQuestions')
    @renderPaginator()
    $questions = @$(".questions").empty()
    for question in @questions
      $questions.append @questionTemplate question
    @showCurrentQuestion()


class app.TestQuestionView extends Backbone.View

  render: ->


class app.CodingView extends Backbone.View

  el: "#coding"

  events:
    'click .pagination a.page': 'changeQuestionPage'
    'click .pagination a.next': 'nextQuestion'
    'click .assignment button.test-code': 'testCode'

  paginatorTemplate: _.template $("#pagination-tmpl").html()
  assignmentTemplate: _.template $("#code-assignment-tmpl").html()

  initialize: ->
    @currentAssignment = 1
    if app.env.has 'codeAssignments'
      @renderAssignments()
    else
      app.env.on 'change:codeAssignments', =>
        @renderAssignments()

  testCode: (e) ->
    $assignment = $(e.currentTarget).parents(".assignment")
    name = $assignment.data "name"
    assignment = _.find @codeAssignments, (as) -> as.name is name
    coffeeScriptCode = @codeMirrors[name].getValue()
    try
      javascript = CoffeeScript.compile coffeeScriptCode, {bare:true}
      assignment.userFun = eval(javascript)
      assignment.testCase()
    catch error
      app.mainView.alert(error, "danger")
    @codeMirrors[name].save()

  changeQuestionPage: (e) ->
    @currentAssignment = $(e.currentTarget).data "index"
    @renderPaginator()
    @showCurrentAssignment()
    return false

  nextQuestion: ->
    if @currentAssignment is @codeAssignments.length
      app.router.navigate 'result', trigger: true
    else
      @currentAssignment += 1
      @renderPaginator()
      @showCurrentAssignment()
    return false

  renderPaginator: ->
    @$('.pagination-js').html @paginatorTemplate
      max: @codeAssignments.length
      current: @currentAssignment
      labels: ['Easy', 'Hard', 'Creative']
      nextLabel: 'Next'

  showCurrentAssignment: ->
    @$(".assignments .assignment").hide().filter("." + @codeAssignments[@currentAssignment-1].name).show()
    @render()

  renderAssignments: ->
    @codeAssignments = app.env.get('codeAssignments').concat app.env.get('creativeCodeAssignment')
    @renderPaginator()
    $assignments = @$(".assignments").empty()
    @codeMirrors = {}
    for assignment in @codeAssignments
      $assignment = $ @assignmentTemplate assignment
      $assignments.append $assignment
      @codeMirrors[assignment.name] = CodeMirror.fromTextArea $assignment.find("textarea").get(0),
          value: assignment.placeholderCode
          mode: 'coffeescript'
          tabSize: 2
          lineNumbers: true
    @showCurrentAssignment()

  render: ->
    for codeMirror in _.values @codeMirrors
      codeMirror.refresh()


class app.ResultView extends Backbone.View
  el: "#result"

  render: ->
    app.mainView.stopTimer()
    $("#loggedin-user").show().find(".email").text app.user.get('email')


class app.MainView extends Backbone.View

  el: "body > .container"

  events:
    'click .alert .close': 'closeAlert'

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
    $box = $(".container > .alert")
      .removeClass('alert-danger alert-info alert-success')
      .addClass("alert-#{type} show")
      .find(".msg").html(msg)
    unless type is 'danger'
      setTimeout (-> $box.removeClass("show")), 4000

  closeAlert: ->
    $(".container > .alert").removeClass("show")
    return false

  show: (viewName) ->
    @$breadcrumb.find(".step").removeClass("active").filter(".#{viewName}").addClass("active")
    for name, view of @views
      if name is viewName
        view.$el.show()
        view.render()
      else
        view.$el.hide()

