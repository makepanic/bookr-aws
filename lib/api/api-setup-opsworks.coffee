RSVP = require 'rsvp'
AWS = null
nconf = null

exports.config = (opts) =>
  {AWS, nconf} = opts

createStack = (opsworks) =>
  new RSVP.Promise (resolve, reject) =>
    opsworks.createStack({
      Name: 'bookr-api-' + Date.now()
      Region: 'eu-west-1'
      HostnameTheme: 'Wild_Cats'
      DefaultOs: 'Amazon Linux'
      UseCustomCookbooks: true
      ServiceRoleArn: nconf.get('opsworks:api:service-role-arn')
      DefaultInstanceProfileArn: nconf.get('opsworks:api:default-instance-profile-arn')
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
          Deploy: ['bookr::configure']
        }
    }, (err, data) =>
      if err
        console.log 'rejecting promise'
        reject err
      else
        resolve data.LayerId
    )

appSetup = (opsworks, stackId) =>
  new RSVP.Promise (resolve, reject) =>
    opsworks.createApp({
      StackId: stackId
      Shortname: 'bookr-api-app'
      Name: 'Bookr API application'
      Description: 'Bookr api nodejs application'
      Type: 'nodejs'
      AppSource: {
        Type: 'git'
        Url: 'https://github.com/makepanic/bookr.git'
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
        createLayer(opsworks, stackId),
        appSetup(opsworks, stackId)
      ]

      RSVP.all(parallel).then((result) =>
        # update config
        layerId = result[0];
        appId = result[1];
        nconf.set('opsworks:api:appId', appId)
        nconf.set('opsworks:api:stackId', stackId)
        nconf.set('opsworks:api:layerId', layerId)
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
