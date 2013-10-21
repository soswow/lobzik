class app.AdminView extends Backbone.View
  el: '#admin'

  template: _.template $("#admin-user").html()

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

    html = "<h2 class='group'>#{groups[0].length} users who got &gt; 60% =)</h2>"
    html += groups[0].join("")
    html += "<h2 class='group'>#{groups[1].length} users who got&lt; 60% =(</h2>"
    html += groups[1].join("")

    @$('.users').html html