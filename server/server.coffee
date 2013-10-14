"use strict"

bugsnag = require("bugsnag")
bugsnag.register("764cddd764b961bbd41e20c081501ccf")
express = require("express")
http = require("http")
path = require("path")
everyauth = require("everyauth")
_ = require("underscore")
mongoose = require("mongoose")
mongoose.connect 'mongodb://localhost/test'
quizConfig = require('./quiz-config')
authConfig = require('./config')

Campfire = require('smores')
campfire = new Campfire(ssl: true, token: authConfig.campfire.apiToken, account: authConfig.campfire.account)

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
      avatar: String
      url: String
      authType: String
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
      rightGivenAnswersNumber = rightGivenAnswers.length
      rightNotGivenAnswersNumber = rightAnswersNumber - rightGivenAnswersNumber

      [wrongGivenAnswersNumber, wrongAnswersNumber] = if question.cloze
        [rightAnswersNumber - rightGivenAnswersNumber,
         rightAnswersNumber]
      else
        wrongAnswers = _.difference [0...question.options.length], question.rightAnswers
        wrongGivenAnswers = _.intersection givenAnswers, wrongAnswers
        [wrongGivenAnswers.length, wrongAnswers.length]

      score = scoreFormula rightGivenAnswersNumber,
        wrongGivenAnswersNumber,
        rightAnswersNumber,
        wrongAnswersNumber

      totalScore += score
      totalRightAnswers += rightGivenAnswersNumber
      totalWrongAnswers += wrongGivenAnswersNumber
      notGivenRightAnswers += rightNotGivenAnswersNumber
      score = rightGivenAnswersNumber = wrongGivenAnswersNumber = rightNotGivenAnswersNumber = 0

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
    totalPercent = Math.round ((rightSolutions/@codeAsignIndecies.length) + @result.test.normScore) * 100
    campfire.join authConfig.campfire.roomId, (err, room) =>
      return console.error(err) if err and not room
      room.paste """#{@email} just finished test with following result:
      - test: #{totalRightAnswers} right answers, #{totalWrongAnswers} wrong answers, #{notGivenRightAnswers} not given right answers
      - scores: total score = #{@result.test.totalScore}, normilized score = #{@result.test.normScore}
      - coding: #{rightSolutions} right solutions, #{wrongSolutions} wrong solutions
      - Total percent: #{totalPercent}
      """


  userSchema.virtual('durationLeft').get ->
    res = Math.ceil (env.maxDuration - (Date.now() - @startedAt.getTime())) / 1000
    res = 0 if res < 0
    res

  User = mongoose.model 'User', userSchema

  findOrCreateUser = (userInfo) ->
    promise = @Promise()
    User.findByEmail userInfo.email, (err, user) ->
      if err or not user
        user = User.create userInfo
        user.save (err, user) ->
          return promise.fail(err) if err
          promise.fulfill(user)
      else
        promise.fulfill(user)
    return promise

  everyauth.github.configure
    appId: authConfig.github.appId
    appSecret: authConfig.github.appSecret
    entryPath: '/auth/github'
    callbackPath: '/auth/github/callback'
    scope: ''
    userPkey: '_id'
    findOrCreateUser: (session, accessToken, accessTokenExtra, githubUserMetadata) ->
      findOrCreateUser.call this,
        email: githubUserMetadata.email or githubUserMetadata.url
        avatar: githubUserMetadata.avatar_url
        url: githubUserMetadata.url
        name: githubUserMetadata.name
        authType: 'github'
    redirectPath: '/'


  everyauth.linkedin.configure
    consumerKey: authConfig.linkedIn.consumerKey
    consumerSecret: authConfig.linkedIn.consumerSecret
    entryPath: '/auth/linkedin'
    callbackPath: '/auth/linkedin/callback'
    userPkey: '_id'
#    fields: 'id,first-name,last-name,email-address,public-profile-url'
    findOrCreateUser: (session, accessToken, accessTokenExtra, userMetadata) ->
      findOrCreateUser.call this,
        email: userMetadata.emailAddress or userMetadata.publicProfileUrl
        avatar: userMetadata.pictureUrl
        url: userMetadata.publicProfileUrl
        name: userMetadata.firstName + ' ' + userMetadata.lastName
        authType: 'linkedin'
    fetchOAuthUser: (accessToken, accessTokenSecret) ->
      promise = @Promise()
      fields = 'id,picture-url,first-name,last-name,email-address,public-profile-url'
      @oauth.get "#{@apiHost()}/people/~:(#{fields})", accessToken, accessTokenSecret, (err, data, res) ->
        if err
          err.extra = data: data, res: res
          return promise.fail(err)
        oauthUser = JSON.parse(data)
        promise.fulfill(oauthUser)
      promise
    redirectPath:'/'

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
  app.configure 'development', ->
    app.use express.static path.resolve __dirname, '../../app'
    app.use express.static path.resolve __dirname, '..'
#    app.use express.static path.resolve __dirname, '../../dist'
  app.use everyauth.middleware()
  app.set "port", process.env.PORT or 3000

  # simple log
  app.use (req, res, next) ->
    console.log "%s %s", req.method, req.url
    next()

  app.configure 'development', ->
    app.get '/', (req, res) ->
      res.sendfile path.join( __dirname, '../../app/index.html')
#      res.sendfile path.join( __dirname, '../../dist/index.html')

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
    console.log "Express App started on #{app.get('port')} in #{process.env.NODE_ENV} env"
