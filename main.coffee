require 'coffee-errors'

traverser = require './traverse-folders'

argv = require('optimist').argv

movies = traverser.findMoviesIn argv._...

console.log movies
