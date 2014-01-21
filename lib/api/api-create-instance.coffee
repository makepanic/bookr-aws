RSVP = require 'rsvp'
createInstance = require '../sdk/createInstance'
AWS = null
nconf = null


exports.config = (opts) =>
  {AWS, nconf} = opts

exports.run = () =>
  opsworks = new AWS.OpsWorks({
    region: 'us-east-1'
  })

  new RSVP.Promise (resolve, reject) =>
    createInstance({
      hostname: 'bookr-api-' + Date.now()
      opsworks: opsworks
      stackId: nconf.get('opsworks:api:stackId')
      layerId: nconf.get('opsworks:api:layerId')
      size: nconf.get('size:api')
    }).then((instanceId) =>
      # update config
      nconf.set('opsworks:api:instanceId', instanceId)
      nconf.save((err)=>
        if err
          reject err
        else
          resolve instanceId
      )
    ).catch((err) =>
      reject err
    )
