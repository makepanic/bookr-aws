RSVP = require 'rsvp'
AWS = null
nconf = null

findAmi = (ec2) =>
  new RSVP.Promise (resolve, reject) =>
    ec2.describeImages({
        Filters: [{
          Name: 'description'
          Values: [
            '*amazon-linux-64-mongodb'
          ]
        }]
    }, (err, data) =>
      if err
        reject err

      if data.Images.length != 1
        reject 'Bookr Mongodb AMI wurde nicht gefunden :('
      else
        console.log 'found bookr mongodb ami'

      resolve data
    );

runMongoAmi = (ec2, imageId) =>
  new RSVP.Promise (resolve, reject) =>
    console.log "starting mongo ami id: #{imageId}"
    ec2.runInstances({
      ImageId: imageId,
      MinCount: 1,
      MaxCount: 1,
      KeyName: 'rndm',
      SecurityGroupIds: ['sg-f4aae983']
      InstanceType: 't1.micro'
      BlockDeviceMappings: [{
        DeviceName: '/dev/sdb'
        Ebs: {
          SnapshotId: 'snap-61ca9d70'
          VolumeSize: 30
          DeleteOnTermination: true
          VolumeType: 'standard'
        }
      }]
      Monitoring: {
        Enabled: false
      }
      DisableApiTermination: true
      InstanceInitiatedShutdownBehavior: 'stop'
    }, (err, data) =>
      if err
        reject err
      else
        console.log 'runInstances', data
        if data.Instances.length == 1
          launchedInstance = data.Instances[0]

          # check every 5 secs if instance is running
          intervalId = setInterval(()=>
            waitTillInstanceIsRunning(ec2, launchedInstance.InstanceId).then((result) =>
              # instance ready
              clearInterval(intervalId)
              resolve result
            ).catch((err)=>
              if err.notEqualOne
                clearInterval(intervalId)
                reject result
              # instance not ready
            )
          , 5000)

        else
          reject "it should've launched 1 instance but launched #{data.Instances.length}"
    )

waitTillInstanceIsRunning = (ec2, instanceId) =>
  new RSVP.Promise (resolve, reject) =>
    ec2.describeInstances({
      InstanceIds: [instanceId]
    }, (err, data) =>
      if err
        reject err
      else
        # check if state is on 'online'
        reservations = data.Reservations
        if reservations && reservations.length == 1 && reservations[0].Instances.length == 1
          launchingInstance = reservations[0].Instances[0]
          console.log 'launchingInstance', launchingInstance
          if launchingInstance.State.Name == 'running'
            resolve data
          else
            reject ''
        else
          # amount of found instances is wrong
          reject ({
            notEqualOne: true
          })
    )



exports.config = (opts) =>
  {AWS, nconf} = opts


exports.run = () =>
  ec2 = new AWS.EC2()

  new RSVP.Promise (resolve, reject) =>
    console.log 'bookr-mongo called'
    resolve 'done'
    findAmi(ec2).then (data) =>
      runMongoAmi(ec2, data.Images[0].ImageId).then (data) =>
        resolve data