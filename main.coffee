require 'coffee-errors'
require 'coffee-script/register'

Q    = require 'q'
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
  imdb.idForTitle movies[0]
.then ({ id }) ->
  imdb.informationForId id
.then (stuff) ->
  console.log stuff
.then ->
  imdb.saveCache()
.done()
