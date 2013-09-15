"use strict"

express = require("express")
http = require("http")
path = require("path")
everyauth = require("everyauth")

users = {}

everyauth.github
  .appId('8f64e8b2199608057be4')
  .entryPath('/auth/github')
  .callbackPath('/auth/github/callback')
  .appSecret('a306648c84c087d7bcdab64bca185c72ffc931bd')
  .scope('')
  .findOrCreateUser( (session, accessToken, accessTokenExtra, githubUserMetadata) ->
    session.oauth = accessToken
    session.user = githubUserMetadata
    return session.uid = githubUserMetadata.login
  )
  .redirectPath('/')

#everyauth.everymodule.findUserById (userId, callback) ->
#  console.log "findUserById", userId
#  callback({})

app = express()
app.configure ->
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session secret: 'as8df7a76d5f67sd'
  app.use everyauth.middleware()
  app.set "port", process.env.PORT or 3000

# simple log
app.use (req, res, next) ->
  console.log "%s %s", req.method, req.url
  next()

app.get "/test", (req, res) ->
  res.send "Hello Alex 3"

app.get "/", (req, res) ->
  name = req.session?.user?.name or "Unknown"
  res.send "Hello #{name} 1 <a href='/auth/github'>Login</a>"

# start server
http.createServer(app).listen app.get("port"), ->
  console.log "Express App started!"
