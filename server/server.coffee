"use strict"

express = require("express")
http = require("http")
path = require("path")
everyauth = require("everyauth")
mongoose = require("mongoose")
mongoose.connect 'mongodb://localhost/test'

db = mongoose.connection
db.on 'error', console.error.bind console, 'connection error:'
db.once 'open', ->

  userSchema = mongoose.Schema
    email: String
    name: String
  userSchema.statics.findByEmail = (email, cb) -> @findOne { email: email }, cb

  User = mongoose.model 'User', userSchema

  everyauth.github.configure
    appId: '8f64e8b2199608057be4'
    entryPath: '/auth/github'
    callbackPath: '/auth/github/callback'
    appSecret: 'a306648c84c087d7bcdab64bca185c72ffc931bd'
    scope: ''
    userPkey: '_id'
    findOrCreateUser: (session, accessToken, accessTokenExtra, githubUserMetadata) ->
      console.log "findOrCreateUser"
      promise = @Promise()
      authEmail = githubUserMetadata.email
      User.findByEmail authEmail, (err, user) ->
        if err or not user
          user = new User(email: authEmail)
          user.save (err, user) ->
            return promise.fail(err) if err
            promise.fulfill(user)
        else
          promise.fulfill(user)
      return promise
    redirectPath: '/'

  everyauth.everymodule.findUserById (userId, callback) ->
    User.findById userId, callback

  app = express()

  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session secret: 'as8df7a76d5f67sd'
  app.use everyauth.middleware()
  app.set "port", process.env.PORT or 3000

  app.configure 'development', ->
    console.log "dev"
    app.use require('connect-livereload')(
      port: 35729
    )

  app.use express.static path.join( __dirname, '../../app')
  app.use express.static path.join( __dirname, '..')



  # simple log
  app.use (req, res, next) ->
    console.log "%s %s", req.method, req.url
    next()

  app.get "/test", (req, res) ->
    res.send "Hello Alex 3"

  app.get '/', (req, res) ->
    res.sendfile path.join( __dirname, '../../app/index.html')

  app.get "/api/user", (req, res) ->
    user = req.user
    if user
      res.send user
    else
      res.send 403, 'Not logged in'

  # start server
  http.createServer(app).listen app.get("port"), ->
    console.log "Express App started!"
