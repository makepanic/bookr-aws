RSVP = require 'rsvp'
AWS = null
nconf = null

exports.config = (opts) =>
  {AWS, nconf} = opts

createStack = (opsworks) =>
  new RSVP.Promise (resolve, reject) =>
    opsworks.createStack({
      Name: 'bookr-web-' + Date.now()
      Region: 'eu-west-1'
      HostnameTheme: 'Wild_Cats'
      DefaultOs: 'Amazon Linux'
      UseCustomCookbooks: true
      ServiceRoleArn: nconf.get('opsworks:web:service-role-arn')
      DefaultInstanceProfileArn: nconf.get('opsworks:web:default-instance-profile-arn')
      CustomCookbooksSource: {
        Type: 'git'
        Url: 'https://github.com/makepanic/opsworks-cookbooks'
        Revision: 'bookr'
      }
      ConfigurationManager: {
        Name: 'Chef'
        Version: '11.4'
      }
      DefaultSshKeyName: 'rndm'
      DefaultRootDeviceType: 'instance-store'
      CustomJson: JSON.stringify nconf.get('opsworks:customChef')
    }, (err, data) =>
      if err
        console.log 'rejecting promise'
        reject err
      else
        resolve data
    )

createLayer = (opsworks, stackId) =>
  new RSVP.Promise (resolve, reject) =>
    opsworks.createLayer({
        StackId: stackId
        Type: 'nodejs-app'
        Name: 'Nodejs API Layer'
        Attributes: {
          NodejsVersion: '0.10.11'
        }
        Shortname: 'nodejs-layer'
        CustomSecurityGroupIds: [nconf.get('secGroup:web')]
        EnableAutoHealing: true
        CustomRecipes: {
          Deploy: ['bookr::configure-web-client', 'bookr::grunt']
        }
    }, (err, data) =>
      if err
        console.log 'rejecting promise'
        reject err
      else
        resolve data
    )

createInstance = (opsworks, stackId, layerId) =>
  new RSVP.Promise (resolve, reject) =>
    opsworks.createInstance({
      StackId: stackId
      LayerIds: [layerId]
      InstanceType: 't1.micro'
      Hostname: 'bookr-web'
      Os: 'Amazon Linux'
      SshKeyName: 'rndm'
      Architecture: 'x86_64'
      RootDeviceType: 'ebs'
    }, (err, data) =>
      if err
        console.log 'rejecting promise'
        reject err
      else
        resolve data
    )

layerAndInstanceSetup = (opsworks, stackId) =>
  createLayer(opsworks, stackId).then((layerResult) =>
    layerId = layerResult.LayerId
    console.log 'layerId', layerResult
    createInstance(opsworks, stackId, layerId).then((instanceResult) =>
      console.log 'instanceId', instanceResult
      {
        layerId: layerResult.LayerId
        instanceId: instanceResult.InstanceId
      }
    )
  )

appSetup = (opsworks, stackId) =>
  new RSVP.Promise (resolve, reject) =>
    opsworks.createApp({
      StackId: stackId
      Shortname: 'bookr-web-app'
      Name: 'Bookr Webclient application'
      Description: 'Bookr webclient nodejs application'
      Type: 'nodejs'
      AppSource: {
        Type: 'git'
        Url: 'https://github.com/makepanic/bookr-web.git'
        Revision: 'master'
      }
    }, (err, data) =>
      if err
        console.log 'rejecting promise'
        reject err
      else
        resolve data.AppId
    )


exports.run = () =>
  opsworks = new AWS.OpsWorks({
    region: 'us-east-1'
  })

  new RSVP.Promise (resolve, reject) =>
    createStack(opsworks).then((stackResult) =>
      stackId = stackResult.StackId

      parallel = [
        layerAndInstanceSetup(opsworks, stackId),
        appSetup(opsworks, stackId)
      ]

      RSVP.all(parallel).then((result) =>
        # update config
        layerInstanceData = result[0];
        appId = result[1];
        nconf.set('opsworks:web:appId', appId)
        nconf.set('opsworks:web:stackId', stackId)
        nconf.set('opsworks:web:instanceId', layerInstanceData.instanceId)
        nconf.set('opsworks:web:layerId', layerInstanceData.layerId)
        nconf.save((err)=>
          if err
            reject err
          else
            resolve result
        )
      )
    ).catch((err) =>
      reject err
    )
