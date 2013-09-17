class app.User extends Backbone.Model
  modelName: 'user'

  url: '/api/user'

app.user = new app.User()