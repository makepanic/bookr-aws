RSVP = require 'rsvp'
AWS = null
nconf = null

setSecurityParams = (opts) =>
  {groupId, ec2} = opts
  new RSVP.Promise (resolve, reject) =>
    ec2.authorizeSecurityGroupIngress({
      GroupId: groupId,
      ec2: ec2
      IpPermissions: [{
        IpProtocol: 'tcp'
        FromPort: 10102
        ToPort: 10102
      }]
    }, (err, data) =>
      if err
        reject err
      else
        resolve ''
    )


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
      nconf.set('secGroup:db', groupId)
      nconf.save((err) =>
        if err
          reject err
        else
          resolve groupId
      )