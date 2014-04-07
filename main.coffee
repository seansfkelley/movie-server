require 'coffee-errors'
require 'coffee-script/register'

Q       = require 'q'
_       = require 'lodash'
winston = require 'winston'

argv = require('optimist').argv

traverser = require './traverse-folders'
imdb      = require './imdb'
client    = require './client'

if argv.debug
  winston.remove winston.transports.Console
  winston.add winston.transports.Console, { level : 'debug' }
else if argv.verbose
  winston.remove winston.transports.Console
  winston.add winston.transports.Console, { level : 'verbose' }

output = argv.f ? 'static.html'

Q.longStackSupport = true

Q()
.then ->
  winston.info 'attempting to load from cache file'
  return imdb.loadCache()
.then ->
  movies = traverser.findMoviesIn argv._...
  winston.info "found #{movies.length} possible movies"
  winston.verbose "movies are:\n#{JSON.stringify movies, null, 2}"
  return movies
.then (movies) ->
  winston.info "querying ids for #{movies.length} titles"
  return Q.all _.map(movies, imdb.idForTitle)
.then (ids) ->
  return _.compact ids
.then (ids) ->
  winston.info "querying information for #{ids.length} ids"
  return Q.all _.map(ids, imdb.informationForId)
.then (infos) ->
  winston.info 'rendering static page'
  return client.render infos, output
.then ->
  winston.info 'saving cache to disk'
  return imdb.saveCache()
.then ->
  winston.info 'done'
.done()
