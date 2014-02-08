require 'coffee-errors'
require 'coffee-script/register'
argv = require('optimist').argv

traverser = require './traverse-folders'
imdb      = require './imdb'

movies = traverser.findMoviesIn argv._...

console.log movies

imdb.idForTitle movies[0]
  .then ({ id }) -> imdb.informationForId id
  .done (stuff) -> console.log stuff
