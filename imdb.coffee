Q    = require 'q'
_    = require 'lodash'

fs   = require 'fs'
http = require 'http'

_cache = null
loadCache = ->
  return Q.ninvoke fs, 'readFile', './cache.json'
  .then (contents) ->
    _cache = JSON.parse contents.toString('utf-8')
    return # don't leak
  .fail ->
    _cache = {}
    return # don't leak

saveCache = ->
  return Q.ninvoke fs, 'writeFile', 'cache.json', JSON.stringify(_cache)

_getJson = (url) ->
  d = Q.defer()
  http.get url, (res) ->
    body = ''
    res.on 'data', (data) -> body += data.toString('ascii')
    res.on 'end', -> d.resolve JSON.parse(body)
    res.on 'error', (err) -> d.reject err
  return d.promise

idForTitle = (title) ->
  # Yes, /xml but json=1
  return _getJson "http://www.imdb.com/xml/find?json=1&nr=1&tt=on&q=#{encodeURIComponent title}"
    .then (results) ->
      return _.chain([ 'title_popular', 'title_approx', 'title_substring' ])
        .map (type) -> results[type]
        .filter _.identity
        .first() # Get the first of the title_* above which has results.
        .first() # Get the first of that result set.
        .value()

informationForId = (id) ->
  if _cache[id]
    return Q _cache[id]
  else
    _getJson "http://www.omdbapi.com/?i=#{id}"
    .then (results) ->
      _cache[id] = results
      return results

module.exports = { loadCache, saveCache, idForTitle, informationForId }
