var path = require('path'),
    gulp = require('gulp'),
    coffee = require('gulp-coffee'); // Препроцессор JS Coffee Script

gulp.task('default', ['src'],function(){});
gulp.task('src', ['src'],function(){});

var lib = path.join(__dirname, './lib'),
    src = path.join(__dirname, './src/');

/**
 * SRC NODE JS
 */
gulp.task('src', function () {
    return gulp.src(lib + '/**/*.coffee')
        .pipe(coffee({bare: true}))
        .pipe(gulp.dest(src));
});

gulp.task('watch', function () {
    gulp.watch(lib + '/**/*.coffee', ['src']);
});