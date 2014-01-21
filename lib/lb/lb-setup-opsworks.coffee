RSVP = require 'rsvp'
createInstance = require '../sdk/createInstance'
AWS = null
nconf = null

exports.config = (opts) =>
  {AWS, nconf} = opts


createHALayer = (opsworks, stackId) =>
  new RSVP.Promise (resolve, reject) =>
    opsworks.createLayer({
      StackId: stackId
      Type: 'lb'
      Name: 'HAProxy Layer'
      Attributes: {
        HaproxyStatsUser: 'ha-bookr-user'
        HaproxyStatsPassword: 'bookr-ha-pw'
        HaproxyStatsUrl: '/ha-stats?stats'
        HaproxyHealthCheckUrl: '/'
        HaproxyHealthCheckMethod: 'GET'
        EnableHaproxyStats: 'true'
      }
      Shortname: 'lb-layer'
    }, (err, data) =>
      if err
        console.log 'rejecting promise'
        reject err
      else
        resolve data
    )

HAProxylayerAndInstanceSetup = (opsworks, stackId) =>
  createHALayer(opsworks, stackId).then((layerResult) =>
    layerId = layerResult.LayerId
    console.log 'layerId', layerResult
    createInstance({
      hostname: 'bookr-lb'
      opsworks: opsworks
      stackId: stackId
      layerId: layerId
      size: nconf.get('size:lb')
    }).then((instanceId) =>
      console.log 'instanceId', instanceId
      {
        layerId: layerResult.LayerId
        instanceId: instanceId
      }
    )
  )

exports.run = () =>
  opsworks = new AWS.OpsWorks({
    region: 'us-east-1'
  })

  new RSVP.Promise (resolve, reject) =>
    # lb on api stack
    stackId = nconf.get('opsworks:api:stackId')
    parallel = [
      HAProxylayerAndInstanceSetup(opsworks, stackId)
    ]

    RSVP.all(parallel).then((result) =>
      # update config
      layerInstanceData = result[0];
      nconf.set('opsworks:lb:instanceId', layerInstanceData.instanceId)
      nconf.set('opsworks:lb:layerId', layerInstanceData.layerId)
      nconf.save((err)=>
        if err
          reject err
        else
          resolve result
      )
    )
