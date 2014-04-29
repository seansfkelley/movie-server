Q       = require 'q'
_       = require 'lodash'
winston = require 'winston'

fs   = require 'fs'
http = require 'http'

_cache = null
loadCache = ->
  return Q.ninvoke fs, 'readFile', './cache.json'
    .then (contents) ->
      _cache = JSON.parse contents.toString('utf-8')
      winston.info 'loaded from cache file'
    .fail ->
      winston.info 'failed to load cache file, starting anew'
      _cache = {}
    .then ->
      _cache.titleToId ?= {}
      _cache.idToInformation ?= {}
      _cache.unknownTitles ?= {}
      return # don't leak

saveCache = ->
  return Q.ninvoke fs, 'writeFile', 'cache.json', JSON.stringify(_cache)

_getJson = (url) ->
  d = Q.defer()
  http.get url, (res) ->
    body = ''
    res.on 'data', (data) -> body += data.toString('utf-8')
    res.on 'end', -> d.resolve JSON.parse(body)
    res.on 'error', (err) -> d.reject err
  return d.promise

idForTitle = (title) ->
  if _cache.titleToId[title]
    winston.verbose "hit cache for title '#{title}' -> id '#{_cache.titleToId[title]}'"
    return Q _cache.titleToId[title]
  else if _cache.unknownTitles[title]
    winston.verbose "skipping known-unknown title '#{title}'"
    return Q null
  else
    winston.verbose "querying imdb for title '#{title}'"
    # Yes, /xml but json=1
    return _getJson "http://www.imdb.com/xml/find?json=1&nr=1&tt=on&q=#{encodeURIComponent title}"
      .then (results) ->
        winston.debug "imdb results for title '#{title}':\n#{JSON.stringify results, null, 2}"
        return _.chain [ 'title_popular', 'title_exact', 'title_approx', 'title_substring' ]
          .map (type) -> results[type]
          .compact()
          .first() # Get the first of the title_* above which has results.
          .first() # Get the first of that result set.
          .value()
      .then (info) ->
        if not info?.id
          winston.verbose "flagging known-unknown title '#{title}'"
          _cache.unknownTitles[title] = true
          return
        else
          winston.verbose "caching title '#{title}' -> id '#{info.id}'"
          _cache.titleToId[title] = info.id
          return info.id

informationForId = (id) ->
  if _cache.idToInformation[id]
    winston.verbose "hit cache for id '#{id}' -> information"
    return Q _cache.idToInformation[id]
  else
    winston.verbose "querying omdbapi for id '#{id}'"
    return _getJson "http://www.omdbapi.com/?i=#{id}"
      .then (results) ->
        winston.debug "omdbapi results for id '#{id}':\n#{JSON.stringify results}"
        _cache.idToInformation[id] = results
        return results

module.exports = { loadCache, saveCache, idForTitle, informationForId }
