require 'coffee-errors'
require 'coffee-script/register'
argv = require('optimist').argv

traverser = require './traverse-folders'
imdb      = require './imdb'

movies = traverser.findMoviesIn argv._...

console.log movies

imdb.getId movies[0]
  .done (id) -> console.log id
