class app.TestView extends Backbone.View
  el: "#test"

  events:
    'click .pagination a.page': 'changeQuestionPage'
    'click .pagination a.next': 'nextQuestion'
    'click .question .options input': 'selectAnswer'
    'keyup .question input.cloze': 'typeAnswer'

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
    for name, answers of app.user.get('testAnswers')
      for answer, idx in answers
        if app.env.questionsByName(name)?.cloze
          @$(".question.#{name} input.cloze.#{idx}").val answer
        else
          @$(".question.#{name} input.index-#{index}").prop "checked", true

  renderUser: ->
    app.mainView.startTimer()
    safeEmail = app.user.escape 'email'
    authProvider = app.user.get 'authProvider'
    $("#loggedin-user").show().find(".email").html "<i class='icon-#{authProvider}-sign'></i> #{safeEmail}"
    unless app.user.get 'finished'
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
      if question.cloze
        question.cloze = question.cloze.replace /\{(\d+)\}/ig, """
          <input type="text" class="form-control cloze $1" data-index="$1" value="" placeholder="???" />
          """
      $questions.append @questionTemplate _.extend {options: null, cloze: null},
        question,
        answers: app.user.testAnswers?[question.name] or []
    @showCurrentQuestion()
    SyntaxHighlighter.defaults['tab-size'] = 2;
    SyntaxHighlighter.defaults['smart-tabs'] = false;
    SyntaxHighlighter.all()

  selectAnswer: (e) ->
    $question = $(e.currentTarget).parents(".question")
    $checkboxes = $question.find("input:checkbox:checked")
    name = $question.data "name"
    indecies = $checkboxes.map (idx, el) -> $(el).data("index")
    testAnswers = _.clone app.user.get("testAnswers")
    testAnswers[name] = indecies.get()
    app.user.save testAnswers: testAnswers

  typingAnswer: false
  typeAnswer: (e) ->
    $question = $(e.currentTarget).parents(".question")
    name = $question.data "name"
    $clozes = $question.find("input.cloze")
    testAnswers = _.clone app.user.get("testAnswers")
    testAnswers[name] = $clozes.map((idx, el) -> $(el).val()).get()
    clearTimeout @typingAnswer if @typingAnswer
    @typingAnswer = setTimeout ( ->
      app.user.save testAnswers: testAnswers
    ), 200
