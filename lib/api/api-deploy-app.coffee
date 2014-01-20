RSVP = require 'rsvp'
AWS = null
nconf = null

exports.config = (opts) =>
  {AWS, nconf} = opts


waitTillInstanceIsRunning = (opts) =>
  {opsworks, stackId, appId, deploymentId} = opts
  new RSVP.Promise (resolve, reject) =>
    opsworks.describeDeployments({
        DeploymentIds: [deploymentId]
      }, (err, data) =>
        if err
          reject err
        else
          # check if state is on 'online'
          instances = data.Instances
          if instances && instances.length == 1
            launchingInstance = instances[0]
            if launchingInstance.Status == 'online'
              console.log "instance #{instanceId} is online"
              resolve launchingInstance.PublicIp
            else
              console.log "instance #{instanceId} status is #{launchingInstance.Status}"
              reject launchingInstance.Status
          else
            # amount of found instances is wrong
            reject ({
              notEqualOne: true
            })
    )

deployApp = (opts) =>
  {opsworks, stackId, instanceIds, appId, customChef} = opts

  new RSVP.Promise (resolve, reject) =>
    opsworks.createDeployment({
      StackId: stackId
      AppId: appId
      InstanceIds: instanceIds
      Comment: 'deploy api application'
      CustomJson: customChef
      Command: {
        Name: 'deploy'
      }
    }, (err, data) =>
      if err
        reject err
      else
        console.log 'startInstance', data
        deploymentId = data.DeploymentId
        intervalWait = 20

        # check every intervalWait secs if instance is running
        intervalId = setInterval(()=>
          waitTillInstanceIsRunning({
            opsworks: opsworks
            stackId: stackId
            appId: appId
            deploymentId: deploymentId
          }).then(() =>
            # instance ready
            clearInterval(intervalId)
            resolve deploymentId
          ).catch((err)=>
            if err.notEqualOne
              console.warn 'launched more/less than 1 instance, aborting'
              clearInterval(intervalId)
              reject result
            else
              console.warn "instance isnt running (is #{err}), waiting #{intervalWait}sec"
          );
        , intervalWait * 1000)
    )

exports.run = () =>
  opsworks = new AWS.OpsWorks({
    region: 'us-east-1'
  })

  new RSVP.Promise (resolve, reject) =>
    deployApp({
      opsworks: opsworks,
      stackId: nconf.get('opsworks:api:stackId'),
      instanceIds: [nconf.get('opsworks:api:instanceId')],
      appId: nconf.get('opsworks:api:appId')
      customChef: JSON.stringify nconf.get('opsworks:customChef')
    }).then((apiPublicIp)=>
      console.log "bookr api server available at http://#{apiPublicIp}/"
      nconf.set('opsworks:api:latestDeploymentId', "http://#{apiPublicIp}/")
      nconf.save((err) =>
        if err
          reject err
        else
          resolve apiPublicIp
      )
    ).catch((err) =>
      reject err
    )