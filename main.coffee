require 'coffee-errors'
require 'coffee-script/register'

Q    = require 'q'
_    = require 'lodash'
argv = require('optimist').argv

traverser = require './traverse-folders'
imdb      = require './imdb'

Q.longStackSupport = true

movies = traverser.findMoviesIn argv._...

console.log movies

Q()
.then ->
  imdb.loadCache()
.then ->
  Q.all _.map(movies, imdb.idForTitle)
.then _.compact
.then (ids) ->
  Q.all _.map(ids, imdb.informationForId)
.then ->
  imdb.saveCache()
.done()
