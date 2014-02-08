Q    = require 'q'
http = require 'http'

_get = (title) ->
  d = Q.defer()
  # Yes, /xml but json=1
  http.get "http://www.imdb.com/xml/find?json=1&nr=1&tt=on&q=#{encodeURIComponent title}", (res) ->
    body = ''
    res.on 'data', (data) -> body += data.toString('ascii')
    res.on 'end', -> d.resolve JSON.parse(body)
    res.on 'error', (err) -> d.reject err
  return d.promise

module.exports.getId = (title) ->
  _get(title)
  .then (body) -> console.log body
