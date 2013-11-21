class app.AdminView extends Backbone.View
  el: '#admin'

  events:
    'click .js-show-details': (e) -> @showDetails $(e.currentTarget).data 'id'
    'click .code-solution-index': 'showSolution'

  template: _.template $("#admin-user").html()
  detailsTemplate: _.template $("#admin-user-detailed").html()

  initialize: ->
    _.bindAll @, 'renderOne', 'render'
    @users = []
    app.user.on 'change:id', =>
      if app.user.get('isAdmin')
        $.getJSON '/api/admin/users', (data) =>
          @users = data.data
          @users.sort (a, b) -> b.resultPercent - a.resultPercent
          @trigger 'users:loaded'

  renderOne: (user) ->
    @template
      id: user.id
      name: user.name
      email: user.email
      avatar: user.avatar
      percent: user.resultPercent
      url: user.url

  render: ->
    if @users.length is 0
      return @on 'users:loaded', @render

    groupIndex = 0
    groups = [[], []]
    for user in @users
      groups[groupIndex].push @renderOne user
      if groupIndex is 0 and user.resultPercent < 60
        groupIndex = 1

    html = "<h2 class='group'><i class='icon-thumbs-up pull-right'></i> #{groups[0].length} users &gt; 60%</h2><ul class='list-group good'>"
    html += groups[0].join("")
    html += "</ul><h2 class='group'><i class='icon-thumbs-down pull-right'></i> #{groups[1].length} users &lt; 60%</h2><ul class='list-group bad'>"
    html += groups[1].join("")
    html += "</ul>"

    @$('.users').html html

  showDetails: (id) ->
    $.getJSON "/api/admin/users/#{id}", (userData) =>
      tests =
        for testName, userAnswers of userData.testAnswers
          test = app.env.questionsByName(testName)
          if test.cloze
            $cloze = $(test.cloze)
            for answer, i in test.rightAnswers
              $cloze.find(".cloze[data-index=#{i}]").attr('value', userAnswers[i]).addClass(
                userAnswers[i] is answer and "correct" or "incorrect"
              )
            name: test.name
            cloze: $cloze.map((cloz)->$(this).html()).get().join()
          else
            name: test.name
            options:
              for option, i in test.options
                text: option
                currentAnswer: i in test.rightAnswers
                userChecked: i in userAnswers
      codes =
        for codeName, solutions of userData.codeSolutions
          name: codeName
          solutions: solutions
      @$(".details.id-#{id}").html @detailsTemplate
        tests: tests
        codes: codes

  showSolution: (e) ->
    index = $(e.currentTarget).data 'index'
    $(e.currentTarget).siblings("pre").hide().filter("[data-index=#{index}]").show()
