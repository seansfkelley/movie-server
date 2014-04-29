require 'coffee-errors'
require 'coffee-script/register'

Q       = require 'q'
_       = require 'lodash'
_.str   = require 'underscore.string'
winston = require 'winston'

argv = require 'optimist'
  .usage 'Usage: $0 directories...'
  .boolean [ 'debug', 'verbose', 'h' ]
  .options 'f', {
    alias    : 'file'
    default  : 'movies.html'
    describe : 'output HTML filename'
  }
  .options 'h', {
    alias    : 'help'
    describe : 'show this message'
  }
  .options 'v', {
    alias    : 'verbose'
    describe : 'enable verbose logging'
  }
  .options 'd', {
    alias    : 'debug'
    describe : 'enable debug logging'
  }
  .argv

if argv.help or argv._.length == 0
  require('optimist').showHelp()
  return

traverser = require './traverse-folders'
imdb      = require './imdb'
client    = require './client'

if argv.debug
  winston.remove winston.transports.Console
  winston.add winston.transports.Console, { level : 'debug' }
else if argv.verbose
  winston.remove winston.transports.Console
  winston.add winston.transports.Console, { level : 'verbose' }

Q.longStackSupport = true

Q()
.then ->
  winston.info 'attempting to load from cache file'
  return imdb.loadCache()
.then ->
  movies = traverser.findMoviesIn argv._...
  winston.info "found #{movies.length} possible movies"
  formattedMovies = _.map(movies, (m) -> "  #{_.str.rpad m.sanitized, 30} (from #{m.basename})").join '\n'
  winston.verbose "movies are:\n#{formattedMovies}"
  return movies
.then (movies) ->
  winston.info "querying ids for #{movies.length} titles"
  return Q.all _.map(_.pluck(movies, 'sanitized'), imdb.idForTitle)
  .then (ids) ->
    infos = _.chain movies
      .zip ids
      .map ([ movie, id ]) -> _.extend { id }, movie
      .filter ({ id }) -> !!id
      .value()
    winston.info "querying information for #{infos.length} ids"
    return Q.all _.map(infos, ({ id }) -> imdb.informationForId(id))
    .then (imdbInfos) ->
      return _.map imdbInfos, (imdbInfo, i) -> _.extend { Filename : infos[i].basename }, imdbInfo
.then (infos) ->
  winston.info 'rendering static page'
  return client.render infos, argv.file
.then ->
  winston.info 'saving cache to disk'
  return imdb.saveCache()
.then ->
  winston.info 'done'
.done()
