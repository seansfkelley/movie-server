require 'coffee-errors'
require 'coffee-script/register'

Q       = require 'q'
_       = require 'lodash'
winston = require 'winston'

argv = require('optimist').argv

traverser = require './traverse-folders'
imdb      = require './imdb'

if argv.debug
  winston.remove winston.transports.Console
  winston.add winston.transports.Console, { level : 'debug' }
else if argv.verbose
  winston.remove winston.transports.Console
  winston.add winston.transports.Console, { level : 'verbose' }

Q.longStackSupport = true

movies = traverser.findMoviesIn argv._...

Q()
.then ->
  winston.verbose "found #{movies.length} possible movies:\n#{JSON.stringify movies, null, 2}"
.then ->
  winston.info 'attempting to load from cache file'
  imdb.loadCache()
.then ->
  winston.info "querying ids for #{movies.length} titles"
  Q.all _.map(movies, imdb.idForTitle)
.then _.compact
.then (ids) ->
  winston.info "querying information for #{ids.length} ids"
  Q.all _.map(ids, imdb.informationForId)
.then ->
  winston.info 'saving cache to disk'
  imdb.saveCache()
.then ->
  winston.info 'done'
.done()
