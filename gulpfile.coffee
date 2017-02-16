gulp    = require 'gulp'
coffee  = require 'gulp-coffee'
clean   = require 'gulp-clean'

# Default task compiles everything
gulp.task 'default', ['compile']

# Compile project to JS
gulp.task 'compile', ['copy-config'], ->
    gulp.src './src/**/*.coffee'
        .pipe coffee {bare: true}
        .pipe gulp.dest './dist'

# Copy config file
gulp.task 'copy-config', ->
    gulp.src './src/*.json'
        .pipe gulp.dest './dist'


# Clean dist directory
gulp.task 'clean', ->
    gulp.src './dist/*.js', {read: false}
        .pipe clean()

