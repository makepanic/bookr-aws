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
          deployements = data.Deployments

          if deployements && deployements.length == 1
            deployment = deployements[0]
            if deployment.Status != 'running'
              console.log "deployment #{deploymentId} was #{deployment.Status}"
              resolve deploymentId
            else
              reject deployment.Status
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
      Comment: 'deploy web application'
      CustomJson: customChef
      Command: {
        Name: 'deploy'
      }
    }, (err, data) =>
      if err
        reject err
      else
        deploymentId = data.DeploymentId
        intervalWait = 60

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
              console.warn 'found more/less than 1 deployment, aborting'
              clearInterval(intervalId)
              reject result
            else
              console.warn "deployment is running, waiting #{intervalWait}sec"
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
      stackId: nconf.get('opsworks:web:stackId'),
      instanceIds: [nconf.get('opsworks:web:instanceId')],
      appId: nconf.get('opsworks:web:appId')
      customChef: JSON.stringify nconf.get('opsworks:customChef')
    }).then((deploymentId)=>
      nconf.set('opsworks:web:latestDeploymentId', deploymentId)
      nconf.save((err) =>
        if err
          reject err
        else
          resolve deploymentId
      )
    ).catch((err) =>
      reject err
    )