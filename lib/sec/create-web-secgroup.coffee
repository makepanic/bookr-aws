RSVP = require 'rsvp'
AWS = null
nconf = null


createSecurityGroup = (ec2) =>
  new RSVP.Promise (resolve, reject) =>
    ec2.createSecurityGroup({
      GroupName: 'bookr-web'
      Description: 'Security Group for web access'
    }, (err, data) =>
      if err
        reject err
      else
        resolve data.GroupId
    )

exports.config = (opts) =>
  {AWS, nconf} = opts

exports.run = () =>
  ec2 = new AWS.EC2()

  new RSVP.Promise (resolve, reject) =>
    createSecurityGroup(ec2).then (groupId) =>
      nconf.set('secGroup:web', groupId)
      nconf.save((err) =>
        if err
          console.warn err
          reject err
        else
          resolve groupId
      )