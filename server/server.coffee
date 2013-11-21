"use strict"

bugsnag = require("bugsnag")
bugsnag.register("764cddd764b961bbd41e20c081501ccf")
express = require("express")
http = require("http")
path = require("path")
_ = require("underscore")
request = require('request')

authConfig = require('./config')

if authConfig.campfire
  Campfire = require('smores')
  campfire = new Campfire(ssl: true, token: authConfig.campfire.apiToken, account: authConfig.campfire.account)

quizConfig = require('./quiz-config')
env =
  maxDuration: quizConfig.maxDuration




# Mangoose / Models
# ------------------------------
#
mongoose = require("mongoose")
mongoose.connect authConfig.mongoUrl
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

#  userSchema.statics.findByEmail = (email, cb) -> @findOne { email: email }, cb
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

userSchema.statics.findOrCreateUser = (cb, userInfo) ->
  @findOne { $or: [{email: userInfo.email}, {url: userInfo.url}] }, (err, user) ->
    if err or not user
      console.log 'Not found. Creating.'
      user = User.create userInfo
    else
      console.log 'Found. Reading.'
      if user.email isnt userInfo.email
        user.email = userInfo.email
        console.log "Found by url. Rewriting: #{user.url} -> #{user.email}"

    user.save (err, user) ->
      return cb(err) if err
      cb null, user

userSchema.methods.publicJSON = ->
  omitFields = ['__v', '_id', 'testIndecies', 'codeAsignIndecies']
  omitFields = omitFields.concat if @finished
    ['codeSolutions', 'testAnswers']
  else
    ['result', 'resultPercent']

  userObj = _.omit @toObject(), omitFields...

  unless @finished
    userObj.codeSolutions = {}
    for name, solutions of @codeSolutions
      userObj.codeSolutions[name] = _.last solutions

  JSON.stringify userObj

userSchema.methods.checkIfFinished = (cb) ->
  if @durationLeft <= 0 and not @finished
    @finishUser()
    @durationTook = env.maxDuration
    @save cb
    return true
  else
    cb null, this
    return false

userSchema.methods.finishUser = ->
  @durationTook = env.maxDuration - @durationLeft * 1000
  @finished = true

  # My personal formula. I think it works the best
  scoreFormula = (answeredRight, answeredWrong, totalRight, totalWrong) ->
    answeredRight/totalRight - answeredWrong/(totalWrong + 1)

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
  totalPercent = Math.round ((rightSolutions/@codeAsignIndecies.length) + @result.test.normScore) * 100/2

  campfire?.join authConfig.campfire.roomId, (err, room) =>
    return console.error(err) if err and not room
    room.paste """#{@name} (#{@email}) just finished test with #{totalPercent}% of success. Details:
                  - test: #{totalRightAnswers} right answers, #{totalWrongAnswers} wrong answers, #{notGivenRightAnswers} not given right answers
                  - coding: #{rightSolutions} right solutions, #{wrongSolutions} wrong solutions
               """

userSchema.virtual('resultPercent').get ->
  Math.round ((@result.coding.rightSolutions/@codeAsignIndecies.length) + @result.test.normScore) * 100/2

userSchema.virtual('durationLeft').get ->
  res = Math.ceil (env.maxDuration - (Date.now() - @startedAt.getTime())) / 1000
  res = 0 if res < 0
  res

userSchema.virtual('isAdmin').get -> @email in authConfig.admins

User = mongoose.model 'User', userSchema




# Passport Strategies
# ------------------------------
#
passport = require('passport')
LinkedInStrategy = require('passport-linkedin-oauth2').Strategy
GitHubStrategy = require('passport-github').Strategy

passport.use new LinkedInStrategy {
    clientID: authConfig.linkedIn.consumerKey,
    clientSecret: authConfig.linkedIn.consumerSecret
    callbackURL: '/auth/linkedin/callback'
    scope: ['r_emailaddress', 'r_basicprofile']
    profileFields: ['id','picture-url','first-name','last-name','email-address','public-profile-url']
  },
  (accessToken, refreshToken, profile, done) ->
    profile = profile._json
    User.findOrCreateUser done,
      email: profile.emailAddress or profile.publicProfileUrl
      avatar: profile.pictureUrl
      url: profile.publicProfileUrl
      name: profile.firstName + ' ' + profile.lastName
      authType: 'linkedin'

passport.use new GitHubStrategy {
    clientID: authConfig.github.appId,
    clientSecret: authConfig.github.appSecret,
    callbackURL: "/auth/github/callback"
    scope: ['user:email']
  },
  (accessToken, refreshToken, profile, done) ->
    profile = profile._json
    next = ->
      console.log 'findOrCreateUser', profile
      User.findOrCreateUser done,
        email: profile.email or profile.html_url
        avatar: profile.avatar_url
        url: profile.url
        name: profile.name
        authType: 'github'

    if profile.email
      next()
    else
      url = "https://api.github.com/user/emails?access_token=#{accessToken}"
      request url, (error, response, body) ->
        if !error && response.statusCode == 200
          emails = JSON.parse(body)
          console.log 'emails:', emails
          for email in emails
            if email.indexOf('noreply.github.com') is -1
              profile.email = email
              break

        return next()

passport.serializeUser (user, done) ->
  done null, user.id

passport.deserializeUser (id, done) ->
  User.findById id, (err, user) ->
    done err, user




# Express configuration
# ------------------------------
#
app = express()

#app.configure 'development', ->
#  app.use require('connect-livereload')(
#    port: 35729
#    excludeList: ['/logout', '/auth', '.js', '.css', '.svg', '.ico', '.woff', '.png', '.jpg', '.jpeg']
#  )

app.use express.json()
app.use express.urlencoded()
app.use express.cookieParser()
app.use express.session secret: authConfig.sessionKey
app.configure 'development', ->
  app.use express.static path.resolve __dirname, '../../app'
  app.use express.static path.resolve __dirname, '..'
app.use passport.initialize()
app.use passport.session()
app.set "port", process.env.PORT or 3000

# simple log
app.use (req, res, next) ->
  console.log "%s %s", req.method, req.url
  next()

app.get '/auth/linkedin',
  passport.authenticate 'linkedin',
    scope: ['r_emailaddress', 'r_basicprofile']
    state: authConfig.linkedIn.state

app.get '/auth/github', passport.authenticate 'github'

app.get '/logout', (req, res) ->
  req.logout()
  res.redirect('/')

#    callbackURL: "http://127.0.0.1:3000/auth/linkedin/callback"

app.get '/auth/linkedin/callback',
  passport.authenticate('linkedin', {successRedirect: '/', failureRedirect: '/'})

app.get '/auth/github/callback',
  passport.authenticate('github', {failureRedirect: '/' }),
  (req, res) ->
    res.redirect('/')

app.configure 'development', ->
  app.get '/', (req, res) ->
    res.sendfile path.join __dirname, '../../app/index.html'

app.all '/api/user', (req, res, next) ->
  if req.user
    next()
  else
    res.send(403, 'Not logged in')

app.get "/api/user", (req, res) ->
  user = req.user
  user.checkIfFinished ->
    res.send user.publicJSON()

app.put "/api/user", (req, res) ->
  user = req.user

  if user.finished
    return res.send 403, 'Already finished'

  finished = user.checkIfFinished ->
    if user.finished
      res.send 403, 'Already finished'
  return if finished

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
    return res.send(400, err) if err
    res.send user.publicJSON()

app.get "/api/env", (req, res) ->
  userEnv = _.clone env
  user = req.user
  if user?.isAdmin
    userEnv = _.clone quizConfig
    userEnv.codeAssignments.forEach (codeTest) ->
      codeTest.testCase = codeTest.testCase?.toString()
    res.send userEnv
    return

  if user and not user.finished
    userEnv.testQuestions = user.testIndecies.map (i) -> _.omit quizConfig.testQuestions[i], 'rightAnswers'
    userEnv.codeAssignments = user.codeAsignIndecies.map (i) ->
      question = _.clone quizConfig.codeAssignments[i]
      question.testCase = question.testCase?.toString()
      question
    userEnv.creativeCodeAssignment = quizConfig.creativeCodeAssignment

  res.send userEnv

app.all '/api/admin*', (req, res, next) ->
  if req.user?.isAdmin
    next()
  else
    res.send(403, 'Not an admin')

app.get '/api/admin/users', (req, res) ->
  res.contentType('json')
  simpleData = (user) ->
    userData = _.pick user, 'id', 'name', 'email', 'result', 'resultPercent', 'avatar', 'url'
    JSON.stringify(userData)

  User.find()
    .stream(transform: simpleData)
    .pipe(new UserArrayFormatter()).pipe(res)

app.get '/api/admin/users/:id', (req, res) ->
  res.contentType('json')
  User.findById req.params.id, (err, doc) ->
    res.send JSON.stringify(doc)


Stream = require('stream').Stream
class UserArrayFormatter extends Stream
  writable: true
  _done: false

  write: (doc) ->
    unless @_hasWritten
      @_hasWritten = true
      @emit 'data', '{ "data": [' +  doc
    else
      @emit 'data', ',' + doc
    return true

  destroy: ->
    return if @_done
    User.count {}, (err, count) =>
      @_done = true
      @emit 'data', '], "total":' + count + '}'
      @emit 'end'

  end: @::destroy




# Run everything
# ------------------------------
#
db = mongoose.connection
db.on 'error', console.error.bind console, 'connection error:'
db.once 'open', ->
  # start server
  http.createServer(app).listen app.get("port"), ->
    console.log "Express App started on #{app.get('port')} in #{process.env.NODE_ENV} env"
