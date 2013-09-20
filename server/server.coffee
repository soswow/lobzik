"use strict"

express = require("express")
http = require("http")
path = require("path")
everyauth = require("everyauth")
_ = require("underscore")
mongoose = require("mongoose")
mongoose.connect 'mongodb://localhost/test'
quizConfig = require('./quiz-config')

db = mongoose.connection
db.on 'error', console.error.bind console, 'connection error:'
db.once 'open', ->

  env =
    maxDuration: quizConfig.maxDuration

  schemaOptions =
    toObject:
      virtuals: true
    toJSON:
      virtuals: true

  userSchema = mongoose.Schema(
    {
      email: String
      name: String
      startedAt: Date
      finished:
        type: Boolean
        'default': false
      testIndecies: [Number]
      codeAsignIndecies: [Number]
      codeSolutions: mongoose.Schema.Types.Mixed
    }, schemaOptions
  )


  userSchema.methods.checkIfFinished = (cb) ->
    if @durationLeft <= 0
      @finished = true
      @save cb
    else
      cb null, this

  userSchema.statics.findByEmail = (email, cb) -> @findOne { email: email }, cb
  userSchema.statics.create = (data) ->
    data.startedAt = new Date()
    data.testIndecies = _.shuffle([0...quizConfig.testQuestions.length])[...quizConfig.testQuestionsToShow]
    data.codeAsignIndecies = _.shuffle([0...quizConfig.codeAssignments.length])[...quizConfig.codeAssignmentsToShow]
    data.codeSolutions = {}
    for idx in data.codeAsignIndecies
      name = quizConfig.codeAssignments[idx].name
      data.codeSolutions[name] = []
    new User(data)

  userSchema.virtual('durationLeft').get ->
    res = Math.ceil (env.maxDuration - (Date.now() - @startedAt.getTime())) / 1000
    res = 0 if res < 0
    res

  User = mongoose.model 'User', userSchema

  everyauth.github.configure
    appId: '8f64e8b2199608057be4'
    entryPath: '/auth/github'
    callbackPath: '/auth/github/callback'
    appSecret: 'a306648c84c087d7bcdab64bca185c72ffc931bd'
    scope: ''
    userPkey: '_id'
    findOrCreateUser: (session, accessToken, accessTokenExtra, githubUserMetadata) ->
      promise = @Promise()
      authEmail = githubUserMetadata.email
      User.findByEmail authEmail, (err, user) ->
        if err or not user
          user = User.create email: authEmail
          user.save (err, user) ->
            return promise.fail(err) if err
            promise.fulfill(user)
        else
          promise.fulfill(user)
      return promise
    redirectPath: '/'

  everyauth.everymodule.findUserById (userId, callback) ->
    User.findById userId, (err, user) ->
      return callback(null) if err or not user
      user.checkIfFinished callback

  app = express()

  app.configure 'development', ->
    app.use require('connect-livereload')(
      port: 35729
      excludeList: ['/auth', '.js', '.css', '.svg', '.ico', '.woff', '.png', '.jpg', '.jpeg']
    )

  app.use express.json()
  app.use express.urlencoded()
  app.use express.cookieParser()
  app.use express.session secret: 'as8df7a76d5f67sd'
  app.use express.static path.resolve __dirname, '../../app'
  app.use express.static path.resolve __dirname, '..'
  app.use everyauth.middleware()
  app.set "port", process.env.PORT or 3000

  # simple log
  app.use (req, res, next) ->
    console.log "%s %s", req.method, req.url
    next()

  app.get '/', (req, res) ->
    res.sendfile path.join( __dirname, '../../app/index.html')

  sendUserJSON = (user, res) ->
    userObj = _.omit user.toObject(), '__v', '_id', 'testIndecies', 'codeAsignIndecies'
    userObj.codeSolutions = {}
    for name, solutions of user.codeSolutions
      userObj.codeSolutions[name] = _.last solutions
    res.send JSON.stringify(userObj)

  app.get "/api/user", (req, res) ->
    user = req.user
    if user
      sendUserJSON user, res
    else
      res.send 403, 'Not logged in'

  app.put "/api/user", (req, res) ->
    codeSolutions = req.body?.codeSolutions or {}
    console.log codeSolutions
    for name, {code:code, pass:pass} of codeSolutions
      console.log name, code, pass
      lastSolution = _.last req.user.codeSolutions[name]
      console.log lastSolution
      console.log not lastSolution or lastSolution.code isnt code
      if not lastSolution or lastSolution.code isnt code
        req.user.codeSolutions[name].push code:code, pass:pass
        req.user.markModified('codeSolutions')
#    req.user.codeSol
    req.user.save ->
      sendUserJSON req.user, res

  app.get "/api/env", (req, res) ->
    userEnv = _.clone env
    user = req.user
    if user and not user.finished
      userEnv.testQuestions = user.testIndecies.map (i) -> _.omit quizConfig.testQuestions[i], 'rightAnswer'
      userEnv.codeAssignments = user.codeAsignIndecies.map (i) ->
        question = _.clone quizConfig.codeAssignments[i]
        question.testCase = question.testCase?.toString()
        question
      userEnv.creativeCodeAssignment = quizConfig.creativeCodeAssignment

    res.send userEnv

  # start server
  http.createServer(app).listen app.get("port"), ->
    console.log "Express App started!"
