require("babel-register")({ presets: ['es2015'] });
require("babel-polyfill");

module.exports.handler = require('./dist/index').handler