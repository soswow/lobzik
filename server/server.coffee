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
      durationTook: Number
      finished:
        type: Boolean
        'default': false
      testIndecies: [Number]
      codeAsignIndecies: [Number]
      codeSolutions: mongoose.Schema.Types.Mixed
      testAnswers: mongoose.Schema.Types.Mixed
      result:
        test:
          totalScore: Number
          normScore: Number
          rightAnswers: Number
          notGivenRightAnswers: Number
          wrongAnswers: Number
        coding:
          rightSolutions: Number
          wrongSolutions: Number
      preferedLanguage:
        type: String
        'enum': ['javascript', 'coffeescript']
    }, schemaOptions
  )


  userSchema.methods.checkIfFinished = (cb) ->
    if @durationLeft <= 0 and not @finished
      @finishUser()
      @durationTook = env.maxDuration
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
    data.codeSolutions[quizConfig.creativeCodeAssignment.name] = []

    data.testAnswers = {}
    for idx in data.testIndecies
      name = quizConfig.testQuestions[idx].name
      data.testAnswers[name] = []
    new User(data)

  # My personal formula. I think it works the best
  scoreFormula = (answeredRight, answeredWrong, totalRight, totalWrong) ->
    console.log "Score", answeredRight/totalRight, '-', answeredWrong/(totalWrong + 1)
    answeredRight/totalRight - answeredWrong/(totalWrong + 1)

  userSchema.methods.finishUser = ->
    @durationTook = env.maxDuration - @durationLeft * 1000
    @finished = true

    # Making TEST results
    totalScore = 0
    totalRightAnswers = 0
    totalWrongAnswers = 0
    notGivenRightAnswers = 0
    for idx in @testIndecies
      question = quizConfig.testQuestions[idx]
      name = question.name
      rightAnswersNumber = question.rightAnswers.length
      givenAnswers = @testAnswers[name]
      rightGivenAnswers = _.intersection givenAnswers, question.rightAnswers
      console.log name, givenAnswers, rightGivenAnswers, question.rightAnswers
      rightGivenAnswersNumber = rightGivenAnswers.length
      rightNotGivenAnswersNumber = rightAnswersNumber - rightGivenAnswersNumber

      [wrongGivenAnswersNumber, wrongAnswersNumber] = if question.cloze
        [rightAnswersNumber - rightGivenAnswersNumber,
         rightAnswersNumber]
      else
        wrongAnswers = _.difference [0...question.options.length], question.rightAnswers
        wrongGivenAnswers = _.intersection givenAnswers, wrongAnswers
        console.log wrongAnswers, wrongGivenAnswers
        [wrongGivenAnswers.length, wrongAnswers.length]


      console.log "rightGiAnNum=" + rightGivenAnswersNumber,
        "rightAnNum=" + rightAnswersNumber,
        "wrongGiAnNumr=" + wrongGivenAnswersNumber,
        "wrongAnNum=" + wrongAnswersNumber,
        "notGiRightAn=" + notGivenRightAnswers

      score = scoreFormula rightGivenAnswersNumber,
        wrongGivenAnswersNumber,
        rightAnswersNumber,
        wrongAnswersNumber

      totalScore += score
      totalRightAnswers += rightGivenAnswersNumber
      totalWrongAnswers += wrongGivenAnswersNumber
      notGivenRightAnswers += rightNotGivenAnswersNumber

    @result.test =
      totalScore: totalScore
      normScore: totalScore / @testIndecies.length #Normilized (Average) score. From -xx to 1
      rightAnswers: totalRightAnswers
      wrongAnswers: totalWrongAnswers
      notGivenRightAnswers: notGivenRightAnswers

    #make Coding result
    rightSolutions = 0
    for idx in @codeAsignIndecies
      codeAssignment = quizConfig.codeAssignments[idx]
      name = codeAssignment.name
      goodSolution = _.findWhere @codeSolutions[name], pass: true
      rightSolutions += 1 if goodSolution
    wrongSolutions = @codeAsignIndecies.length - rightSolutions

    @result.coding =
      rightSolutions: rightSolutions
      wrongSolutions: wrongSolutions

    @markModified('result')

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
#
#  everyauth.everymodule.logoutRedirectPath '/'

  app = express()

  app.configure 'development', ->
    app.use require('connect-livereload')(
      port: 35729
      excludeList: ['/logout', '/auth', '.js', '.css', '.svg', '.ico', '.woff', '.png', '.jpg', '.jpeg']
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
    omitFields = ['__v', '_id', 'testIndecies', 'codeAsignIndecies']
    omitFields = omitFields.concat if user.finished
      ['codeSolutions', 'testAnswers']
    else
      ['result']

    userObj = _.omit user.toObject(), omitFields...

    unless user.finished
      userObj.codeSolutions = {}
      for name, solutions of user.codeSolutions
        userObj.codeSolutions[name] = _.last solutions

    res.send JSON.stringify(userObj)

  app.all '/api/user', (req, res, next) ->
    if req.user
      next()
    else
      res.send(403, 'Not logged in')


  app.get "/api/user", (req, res) ->
    user = req.user
    sendUserJSON user, res

  app.put "/api/user", (req, res) ->
    user = req.user
    codeSolutions = req.body?.codeSolutions or {}
    for name, {code:code, pass:pass} of codeSolutions
      lastSolution = _.last user.codeSolutions[name]
      if not lastSolution or lastSolution.code isnt code
        user.codeSolutions[name].push code:code, pass:pass
        user.markModified('codeSolutions')

    testAnswers = req.body?.testAnswers or {}
    for name, answers of testAnswers
      user.testAnswers[name] = answers
      user.markModified 'testAnswers'

    if req.body?.finished and not user.finished
      console.log "finishUser"
      user.finishUser()

    user.preferedLanguage = req.body?.preferedLanguage

    user.save (err, user) ->
      return res.send 400, err if err
      sendUserJSON user, res

  app.get "/api/env", (req, res) ->
    userEnv = _.clone env
    user = req.user
    if user and not user.finished
      userEnv.testQuestions = user.testIndecies.map (i) -> _.omit quizConfig.testQuestions[i], 'rightAnswers'
      userEnv.codeAssignments = user.codeAsignIndecies.map (i) ->
        question = _.clone quizConfig.codeAssignments[i]
        question.testCase = question.testCase?.toString()
        question
      userEnv.creativeCodeAssignment = quizConfig.creativeCodeAssignment

    res.send userEnv

  # start server
  http.createServer(app).listen app.get("port"), ->
    console.log "Express App started!"
