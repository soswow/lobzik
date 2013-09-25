class app.CodingView extends Backbone.View

  el: "#coding"

  events:
    'click .pagination a.page': 'changeQuestionPage'
    'click .pagination a.next': 'nextQuestion'
    'click .assignment button.test-code': 'testCode'

  paginatorTemplate: _.template $("#pagination-tmpl").html()
  assignmentTemplate: _.template $("#code-assignment-tmpl").html()

  initialize: ->
    @currentAssignment = 0
    app.user.on 'change:codeSolutions', =>
      for name, {code:code} of app.user.get('codeSolutions')
        @codeMirrors[name].setValue(code)
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
    pass = false
    try
      javascript = CoffeeScript.compile coffeeScriptCode, {bare:true}
      assignment.userFun = eval(javascript)
      if assignment.testCase
        assignment.testCase()
        app.mainView.alert "It works! Cool!", "success"
      pass = true
    catch error
      message =
        if error.message
          lineInfo = "line: #{error.location?.first_line} col: #{error.location?.first_column}" if error.location
          error.message + (lineInfo or "")
        else
          error
      app.mainView.alert message, "danger"
    @codeMirrors[name].save()
    app.user.updateCodeSolution name, @codeMirrors[name].getValue(), pass

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
      questions: @codeAssignments
      doneClass: (question) -> app.user.get('codeSolutions')?[question.name]?.length > 0 and 'done' or ''
      current: @currentAssignment
      labels: []
      nextLabel: 'Next'

  showCurrentAssignment: ->
    @$(".assignments .assignment").hide().filter("." + @codeAssignments[@currentAssignment].name).show()
    @render()

  renderAssignments: ->
    @codeAssignments = app.env.get('codeAssignments').concat app.env.get('creativeCodeAssignment')
    @renderPaginator()
    $assignments = @$(".assignments").empty()
    @codeMirrors = {}
    for assignment in @codeAssignments
      $assignment = $ @assignmentTemplate _.extend assignment,
        solution: app.user.get('codeSolutions')[assignment.name]
      $assignments.append $assignment
      @codeMirrors[assignment.name] = CodeMirror.fromTextArea $assignment.find("textarea").get(0),
        value: assignment.placeholderCode
        mode: 'coffeescript'
        tabSize: 2
        indentUnit: 2
        indentWithTabs: true
        lineNumbers: true
    @showCurrentAssignment()

  render: ->
    for codeMirror in _.values @codeMirrors
      codeMirror.refresh()