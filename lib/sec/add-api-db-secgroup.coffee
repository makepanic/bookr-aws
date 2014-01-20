RSVP = require 'rsvp'
AWS = null
nconf = null

authorizeIp = (opts) =>
  {instanceIp, ec2, groupId} = opts
  new RSVP.Promise (resolve, reject) =>
    ec2.authorizeSecurityGroupIngress({
      GroupId: groupId,
      IpPermissions: [{
        IpProtocol: 'tcp'
        FromPort: 10102
        ToPort: 10102
        IpRanges: [{
          CidrIp: instanceIp + '/32'
        }]
      }]
    }, (err, data) =>
      if err
        reject err
      else
        resolve ''
    )

exports.config = (opts) =>
  {AWS, nconf} = opts

exports.run = () =>
  ec2 = new AWS.EC2()
  new RSVP.Promise (resolve, reject) =>
    authorizeIp({
      ec2: ec2,
      groupId: nconf.get('secGroup:db')
      instanceIp: nconf.get('opsworks:api:instanceIp')
    }).then (groupId) =>
      console.log 'authorized api ip on db secgroup'
      resolve groupId