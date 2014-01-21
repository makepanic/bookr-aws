RSVP = require 'rsvp'
AWS = null
nconf = null

authorizeWeb = (opts) =>
  {ec2, groupId} = opts
  new RSVP.Promise (resolve, reject) =>
    ec2.authorizeSecurityGroupIngress({
      GroupId: groupId,
      IpPermissions: [{
        IpProtocol: 'tcp'
        FromPort: 80
        ToPort: 80
        IpRanges: [{
          CidrIp: '0.0.0.0/0'
        }]
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
      console.log 'created web security group'
      nconf.set('secGroup:web', groupId)
      nconf.save((err) =>
        if err
          console.warn err
          reject err
        else
          authorizeWeb({
            ec2: ec2,
            groupId: groupId
          }).then () =>
            console.log 'authorized web ip/port on web secgroup'
            resolve groupId
      )