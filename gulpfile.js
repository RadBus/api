'use strict';

var gulp = require('gulp'),
    mocha = require('gulp-mocha'),
    jshint = require('gulp-jshint'),
    coffeelint = require('gulp-coffeelint'),
    jshintStylish = require('jshint-stylish');

//
// fail builds if jshint reports an error
gulp.task('jshint', function () {
    gulp.src(['**/*.js', '!node_modules/**/*.js'])
        .pipe(jshint())
        .pipe(jshint.reporter(jshintStylish))
        .pipe(jshint.reporter('fail'));
});

//
// fail builds if coffeelint reports an error
gulp.task('coffeelint', function () {
    gulp.src(['**/*.coffee', '!node_modules/**/*.coffee'])
        .pipe(coffeelint())
        .pipe(coffeelint.reporter())
        .pipe(coffeelint.reporter('fail'));
});

//
// fail mocha builds for test failures
// the .on event handler is to overcome an unknown bug with gulp/supertest/mocha
gulp.task('test', function () {
    require('coffee-script/register');
    return gulp.src(['test/**/test-*.coffee'], { read: false })
        .pipe(mocha({
            reporter: 'spec',
            timeout: 2000
        }))
        .on('end', function () {
            process.exit(0);
        })
        .on('error', function (err) {
            var errorMessage = err.stack || err.toString();
            console.log(errorMessage);
            process.exit(1);
        });
});

//The default task (called when you run `gulp`)
gulp.task('default', ['test', 'jshint']);
