assert = require "assert"
crypto = require "crypto"
fs = require "fs"
bodyParser = require "body-parser"
express = require "express"

app = express()
expressWs = require('express-ws')(app)

app.use(express.static('public'))

app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

# CORS
app.use (req, res, next) ->
  res.header("Access-Control-Allow-Origin", "*")
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
  next()

# Logging
app.use (req, res, next) ->
  console.log(req.method, req.path, req.body)
  next()

# Thoughts
# - Subscribe to multiple rooms
# - DM an account regardless of room

# Rooms group people to share broadcast info
rooms = {}
accounts = {}

sendMessage = (socket, sender, message) ->
  Object.assign message,
    accountId: sender.accountId
    clientId: sender.clientId

  try
    socket.send JSON.stringify message
  catch e
    console.error e

broadcast = (sockets, sender, message) ->
  sockets.forEach (socket) ->
    sendMessage socket, sender, message

systemSource =
  clientId: "system"
  accountId: "system"

app.ws "/r/:id", (ws, req) ->
  {id} = req.params
  {accountId} = req.query

  rooms[id] ||= []
  room = rooms[id]

  room.push ws

  accounts[accountId] ||= []
  accountConnections = accounts[accountId]

  accountConnections.push ws

  # Generate a random client id
  ws.clientId = crypto.randomBytes(8).toString('hex')
  # TODO: Register/Authenticate account id
  ws.accountId = accountId

  sendMessage ws, ws,
    type: "meta"
    status: "connect"
    room: id

  broadcast room, ws,
    type: "connect"

  ws.on "message", (data, flags) ->
    console.log "message", data

    try
      message = JSON.parse(data)
    catch e
      console.log "error", e
      sendMessage ws, ws,
        type: "error"
        error: e.message

      return

    # Broadcast to all in room
    switch message.type
      when "broadcast"
        broadcast room, ws,
          type: "broadcast"
          clientId: ws.clientId
          message: message.message
      when "dm"
        broadcast accounts[message.recipient] or [], ws,
          type: "dm"
          message: message.message
          clientId: ws.clientId
          accountId: ws.accountId

  ws.on "close", ->
    console.log "close client:", id, ws.clientId, ws.accountId
    # Remove on close
    remove room, ws
    remove accountConnections, ws

    broadcast room, ws,
      type: "disconnect"

listener = app.listen process.env.PORT, ->
  console.log('Your app is listening on port ' + listener.address().port)

remove = (array, item) ->
  position = array.indexOf item

  if position != -1
    array.splice(position, 1)
