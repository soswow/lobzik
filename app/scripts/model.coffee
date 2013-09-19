class app.User extends Backbone.Model
  modelName: 'user'

  url: '/api/user'

  initialize: ->
    _.bindAll @, 'updateDurLeft'
    @on 'sync', @updateDurLeft
    app.env.on 'sync', @updateDurLeft

  updateDurLeft: ->
    return unless @id
    clearTimeout(@durLeftTimer) if @durLeftTimer
    newDurLeft = Math.ceil (app.env.get('maxDuration') - (Date.now() - @get('startedAt').getTime())) / 1000
    newDurLeft = 0 if newDurLeft <= 0
    if @get('durationLeft') isnt newDurLeft
      @set {durationLeft: newDurLeft}, {trigger: true}
    @durLeftTimer = setTimeout(@updateDurLeft, 100) unless newDurLeft <= 0

  parse: (data, options) ->
    data.startedAt = new Date(data.startedAt)
    super data, options

class app.Environment extends Backbone.Model
  modelName: 'user'

  defaults:
    maxDuration: 0

  url: '/api/env'

app.env = new app.Environment()
app.env.fetch()
app.user = new app.User()
