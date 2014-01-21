RSVP = require 'rsvp'

module.exports = (opts) =>
  {opsworks, stackId, layerId, size, hostname} = opts
  new RSVP.Promise (resolve, reject) =>
    opsworks.createInstance({
      StackId: stackId
      LayerIds: [layerId]
      InstanceType: size
      Hostname: hostname
      Os: 'Amazon Linux'
      SshKeyName: 'rndm'
      Architecture: 'x86_64'
      RootDeviceType: 'ebs'
    }, (err, data) =>
      if err
        reject err
      else
        resolve data.InstanceId
    )