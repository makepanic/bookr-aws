header = "\n
        _/                            _/                                        _/  _/\n
       _/_/_/      _/_/      _/_/    _/  _/    _/  _/_/                _/_/_/  _/     \n
      _/    _/  _/    _/  _/    _/  _/_/      _/_/      _/_/_/_/_/  _/        _/  _/  \n
     _/    _/  _/    _/  _/    _/  _/  _/    _/                    _/        _/  _/   \n
    _/_/_/      _/_/      _/_/    _/    _/  _/                      _/_/_/  _/  _/    \n\n

    Bootstraps AWS environment for bookr components. Version 1.0
"


# required modules in correct order
modules = [
  ['create-db-sec',   'sec/create-db-secgroup',  'creates the database security group']
  ['create-web-sec',  'sec/create-web-secgroup', 'creates the web security group']
  ['launch-db',       'db/db-launch-instance',   'launches database instance']
  ['ops-api',         'api/api-setup-opsworks',  'adds opsworks configuration for api stack, layer']
  ['ops-api-instance','api/api-create-instance', 'adds opsworks configuration for api instance']
  ['lb-api',          'lb/lb-setup-opsworks',    'adds opsworks HAProxy configuration for api']
  ['launch-api',      'api/api-launch-instance', 'launches api instance']
  ['launch-lb',       'lb/lb-launch-instance',   'launches loadbalancer instance']
  ['add-api-db-sec',  'sec/add-api-db-secgroup', 'adds the api ip to database security group']
  ['deploy-api',      'api/api-deploy-app',      'deployes api application to api instance']
  ['ops-web',         'web/web-setup-opsworks',  'adds opsworks configuration for webclient']
  ['launch-web',      'web/web-launch-instance', 'launches web instance']
  ['deploy-web',      'web/web-deploy-app',      'deployes web application to web instance']
]

# load required npm modules
log4js = require 'log4js'
nconf = require 'nconf'
RSVP = require 'rsvp'
AWS = require 'aws-sdk'
optimist = require('optimist').usage(header).describe('all', 'run all tasks');

# log4js setup
log4js.configure({
  appenders: [
    {type:'console'},
    {type:'file', filename:'aws-setup.log'}
  ]
});
log4js.replaceConsole();

# add optimist descriptions
modules.forEach((module) =>
  optimist.describe(module[0], module[2])
)

# get cmdling values
argv = optimist.argv;
promises = []

# stop if help option
if argv.help
  console.log optimist.help()
  return

# load config file
nconf.file {
  file: './aws-setup.json'
}

# aws sdk setup
AWS.config.loadFromPath './aws-credentials.json'

# load modules if cmdline has cmdKey
modules.forEach((mod) ->
  if argv.hasOwnProperty('all') or argv.hasOwnProperty mod[0]
    console.log "adding module #{mod[0]}"
    module = require "./lib/#{mod[1]}"
    # config module
    module.config { AWS: AWS, nconf: nconf }
    # push run promise
    promises.push module.run
)

# run each promise after eachother
if promises.length
  chain = null
  promises.forEach (promise, index) =>
    chain = if chain then chain.then(promise) else promise()
    if index == promises.length - 1
      # append catch after last then
      chain.catch (err) =>
        console.warn "caugth error #{index}", err
