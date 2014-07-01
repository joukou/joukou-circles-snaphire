###*
Copyright 2014 Joukou Ltd

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
###

gulp      = require( 'gulp' )
plugins   = require( 'gulp-load-plugins' )( lazy: false )
lazypipe  = require( 'lazypipe' )

paths =
  src:
    dir: 'src'
    coffee: 'src/**/*.coffee'
  dist:
    dir: 'dist'
    js: 'dist/**/*.js'
  test:
    coffee: 'test/**/*.coffee'
  coverage:
    dir: 'coverage'
    lcov: 'coverage/lcov.info'

coffee = lazypipe()
  .pipe( plugins.sourcemaps.init )
  .pipe( plugins.coffee, bare: true )
  .pipe( plugins.sourcemaps.write )
  .pipe( gulp.dest, paths.dist.dir )

mocha = lazypipe()
  .pipe( plugins.mocha,
    ui: 'bdd'
    reporter: 'spec'
    colors: true
    compilers: 'coffee:coffee-script/register'
  )

#
# Build related tasks.
#

gulp.task( 'sloc:build', ->
  gulp.src( paths.src.coffee )
    .pipe( plugins.sloc() )
    .on( 'error', plugins.util.log )
)

gulp.task( 'clean:build', ->
  gulp.src( paths.dist.dir, read: false )
    .pipe( plugins.clean( force: true ) )
    .on( 'error', plugins.util.log )
)

gulp.task( 'coffeelint:build', ->
  gulp.src( paths.src.coffee )
    .pipe( plugins.coffeelint( optFile: 'coffeelint.json' ) )
    .pipe( plugins.coffeelint.reporter() )
    .pipe( plugins.coffeelint.reporter( 'fail' ) )
    .on( 'error', plugins.util.log )
)

gulp.task( 'coffee:build', [ 'clean:build' ], ->
  gulp.src( paths.src.coffee )
    .pipe( coffee() )
    .on( 'error', plugins.util.log )
)

gulp.task( 'build', [ 'sloc:build', 'coffeelint:build', 'coffee:build' ] )
gulp.task( 'default', [ 'build' ] )

#
# Test related tasks.
#

gulp.task( 'cover:test', [ 'build' ], ->
  gulp.src( paths.dist.js )
    .pipe( plugins.istanbul() )
    .on( 'error', plugins.util.log )
)

gulp.task( 'mocha:test', [ 'cover:test' ], ->
  gulp.src( paths.test.coffee )
    .pipe( mocha() )
    .pipe( plugins.istanbul.writeReports( paths.coverage.dir ) )
)

gulp.task( 'coveralls:test', [ 'mocha:test' ], ->
  gulp.src( paths.coverage.lcov )
    .pipe( plugins.coveralls() )
)

gulp.task( 'test', [ 'mocha:test' ] )

gulp.task( 'ci', [ 'coveralls:test' ] )

#
# Develop related tasks.
#

gulp.task( 'coffee:watch', [ 'build' ], ->
  changes = gulp.src( paths.src.coffee, read: false )
    .pipe( plugins.watch() )
    .pipe( plugins.plumber() )

  changes
    .pipe( coffee() )

  changes
    .pipe( plugins.coffeelint( optFile: 'coffeelint.json' ) )
    .pipe( plugins.coffeelint.reporter( ) )
)

gulp.task( 'mocha:watch', [ 'build' ], ->
  gulp.src( [
    paths.dist.js
    paths.test.coffee
  ], read: false )
  .pipe( plugins.watch( emit: 'all', ( changes ) ->
    changes
      .pipe( plugins.grepStream( '**/test/**/*.coffee' ) )
      .pipe( mocha() )
      .on( 'error', plugins.util.log )
  ) )
)

gulp.task( 'develop', [ 'coffee:watch', 'mocha:watch' ] )