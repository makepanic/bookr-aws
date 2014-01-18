RSVP = require 'rsvp'
AWS = null

exports.config = (opts) =>
  {AWS} = opts

exports.run = () =>
  new RSVP.Promise (resolve, reject) =>
    setTimeout (() =>
      resolve 'done'
    ), 1500