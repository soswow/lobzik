class app.User extends Backbone.Model
  modelName: 'user'

  url: '/api/user'

  parse: (data, options) ->
    data.startedAt = moment(data.startedAt)
    super data, options

app.user = new app.User()