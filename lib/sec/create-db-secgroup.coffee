RSVP = require 'rsvp'
AWS = null
nconf = null

createSecurityGroup = (ec2) =>
  new RSVP.Promise (resolve, reject) =>
    ec2.createSecurityGroup({
      GroupName: 'bookr-database'
      Description: 'Security Group for database access'
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
      console.log 'created db security group'
      nconf.set('secGroup:db', groupId)
      nconf.save((err) =>
        if err
          reject err
        else
          resolve groupId
      )