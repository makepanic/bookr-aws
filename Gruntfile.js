module.exports = function(grunt) {
    // Grunt configuration.
    var gruntCfg = {
        pkg: grunt.file.readJSON('package.json'),

        // use if you don't have file watchers to generate coffeescript files
        coffee: {
            dist: {
                files: [{
                    expand: true,
                    cwd: 'lib',
                    src: ['{,*/}*.coffee'],
                    dest: 'lib',
                    rename: function(dest, src) {
                        return dest + '/' + src.replace(/\.coffee$/, '.js');
                    }
                }, {
                    'aws-setup.js': 'aws-setup.coffee'
                }]
            }
        },

    };

    grunt.initConfig(gruntCfg);

    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.registerTask('default', ['coffee']);

};
