"use strict"

express = require("express")
http = require("http")
path = require("path")

app = express()
app.configure ->
  app.set "port", process.env.PORT or 3000

# simple log
app.use (req, res, next) ->
  console.log "%s %s", req.method, req.url
  next()

app.get "/test", (req, res) ->
  res.send "Hello Alex 3"

# start server
http.createServer(app).listen app.get("port"), ->
  console.log "Express App started!"
