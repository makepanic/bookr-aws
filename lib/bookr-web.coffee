RSVP = require 'rsvp'
AWS = null
nconf = null

exports.config = (opts) =>
  {AWS, nconf} = opts

exports.run = () =>
  new RSVP.Promise (resolve, reject) =>
    setTimeout (() =>
      resolve 'done'
    ), 100