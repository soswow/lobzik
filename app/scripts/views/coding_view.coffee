class app.CodingView extends Backbone.View

  el: "#coding"

  events:
    'click .pagination a.page': 'changeQuestionPage'
    'click .pagination a.next': 'nextQuestion'
    'click .assignment button.test-code': 'testCode'

  paginatorTemplate: _.template $("#pagination-tmpl").html()
  assignmentTemplate: _.template $("#code-assignment-tmpl").html()

  initialize: ->
    _.bindAll @, 'renderAssignments'
    @currentAssignment = 0

#    if app.env.has('codeAssignments') and app.user.has('preferedLanguage')
#      @renderAssignments()

    app.user.on 'change:codeSolutions', =>
      # Means we alreadt have 'preferedLanguage'
      @renderAssignments() unless @codeMirrors
      @fillMirrors()

  fillMirrors: ->
    for name, {code:code} of app.user.get('codeSolutions')
      @codeMirrors[name].setValue(code)
      @renderPaginator()

  checkPreferedLanguage: (cb) ->
    if app.user.get('preferedLanguage')
      cb()
    else
      $modal = $("#language-chooser-modal")
      $modal.modal(
        keyboard: false
      ).on 'hide.bs.modal', ->
        return false unless app.user.get('preferedLanguage')

      $buttons = $('#language-chooser-modal .modal-footer button')
      $buttons.on 'click', (e) ->
        app.user.save preferedLanguage: $(e.currentTarget).data 'lang'
        $buttons.off 'click'
        $modal.modal('hide')
        cb()

  testCode: (e) ->
    $assignment = $(e.currentTarget).parents(".assignment")
    name = $assignment.data "name"
    assignment = _.find @codeAssignments, (as) -> as.name is name
    codeText = @codeMirrors[name].getValue()
    pass = false
    try
      javascript =
        if app.user.get('preferedLanguage') is 'javascript'
          "(" + codeText + ")"
        else
          CoffeeScript.compile codeText, bare:true
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
    if @currentAssignment is @codeAssignments.length - 1
      $("#finish-button").focus()
      app.mainView.alert 'Click Finish Test if you fill so. ;-)', 'info'
    else
      @currentAssignment += 1
      @renderPaginator()
      @showCurrentAssignment()
    return false

  renderPaginator: ->
    @$('.pagination-js').html @paginatorTemplate
      questions: @codeAssignments
      doneClass: (question) ->
        app.user.get('codeSolutions')?[question.name]?.pass and 'done' or ''
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
      data = _.pick assignment, 'name', 'description'
      data.solution = app.user.get('codeSolutions')[assignment.name]
      data.placeholderCode = assignment.placeholderCode[app.user.get('preferedLanguage')]
      $assignment = $ @assignmentTemplate data
      $assignments.append $assignment
      @codeMirrors[assignment.name] = CodeMirror.fromTextArea $assignment.find("textarea").get(0),
#        value: assignment.placeholderCode
        mode: app.user.get('preferedLanguage')
        tabSize: 2
        indentUnit: 2
        indentWithTabs: true
        lineNumbers: true
    @showCurrentAssignment()

  refreshMirrors: ->
    for codeMirror in _.values @codeMirrors
      codeMirror.refresh()

  render: ->
    unless @codeMirrors
      @checkPreferedLanguage =>
        @renderAssignments()
        @refreshMirrors()
    else
      @refreshMirrors()
