RSVP = require 'rsvp'
AWS = null

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

      console.log 'run mongo ami result', data

      resolve data
    )


exports.config = (opts) =>
  {AWS} = opts


exports.run = () =>
  ec2 = new AWS.EC2()

  new RSVP.Promise (resolve, reject) =>
    console.log 'bookr-mongo called'
    resolve 'done'
    findAmi(ec2).then (data) =>
      runMongoAmi(ec2, data.Images[0].ImageId).then (data) =>
        resolve data