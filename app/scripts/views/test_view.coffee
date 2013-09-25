class app.TestView extends Backbone.View
  el: "#test"

  events:
    'click .pagination a.page': 'changeQuestionPage'
    'click .pagination a.next': 'nextQuestion'
    'click .question .options input': 'giveAnswer'

  paginatorTemplate: _.template $("#pagination-tmpl").html()
  questionTemplate: _.template $("#test-question-tmpl").html()

  questions: []
  initialize: ->
    @currentQuestion = 0
    if app.env.has 'testQuestions'
      @renderQuestions()
    else
      app.env.on 'change:testQuestions', =>
        @renderQuestions()

    app.user.on 'change:id', =>
      @renderUser()
      @putAnswers()

    app.user.on 'change:testAnswers', =>
      @renderPaginator()

  putAnswers: ->
    for name, indicies of app.user.get('testAnswers')
      for index in indicies
        @$(".question.#{name} input.index-#{index}").prop "checked", true

  renderUser: ->
    app.mainView.startTimer()
    safeEmail = app.user.escape 'email'
    authProvider = app.user.get 'authProvider'
    $("#loggedin-user").show().find(".email").html "<i class='icon-#{authProvider}-sign'></i> #{safeEmail}"
    $("#finish-button").show()

  renderPaginator: ->
    @$('.pagination-js').html @paginatorTemplate
      questions: @questions
      doneClass: (question) -> app.user.get('testAnswers')?[question.name]?.length > 0 and 'done' or ''
      current: @currentQuestion
      labels: []
      nextLabel: 'Next'

  changeQuestionPage: (e) ->
    @currentQuestion = $(e.currentTarget).data "index"
    @renderPaginator()
    @showCurrentQuestion()
    return false

  nextQuestion: ->
    if @currentQuestion is @questions.length - 1
      app.router.navigate 'coding', trigger: true
    else
      @currentQuestion += 1
      @renderPaginator()
      @showCurrentQuestion()
    return false

  showCurrentQuestion: ->
    @$(".questions .question").hide().filter("." + @questions[@currentQuestion].name).show()

  renderQuestions: ->
    @questions = app.env.get('testQuestions')
    @renderPaginator()
    $questions = @$(".questions").empty()
    for question in @questions
      $questions.append @questionTemplate _.extend question, answers: app.user.testAnswers?[question.name] or []
    @showCurrentQuestion()

  giveAnswer: (e) ->
    $question = $(e.currentTarget).parents(".question")
    $checkboxes = $question.find("input:checkbox:checked")
    name = $question.data "name"
    indecies = $checkboxes.map (idx, el) -> $(el).data("index")
    testAnswers = _.clone app.user.get("testAnswers")
    testAnswers[name] = indecies.get()
    app.user.save testAnswers: testAnswers