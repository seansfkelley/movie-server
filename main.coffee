require 'coffee-errors'
argv = require('optimist').argv

traverser = require './traverse-folders'
imdb      = require './imdb'

movies = traverser.findMoviesIn argv._...

console.log movies

imdb.getId movies[0]
