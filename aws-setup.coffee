# commandline handling
optimist = require('optimist')
  .usage('Bootstraps AWS environment for bookr components.')
  .describe('db', 'prepare and launch the database server')
  .describe('api', 'prepare and launch the api server. This option requires the opsworks-api config')
  .describe('web', 'prepare and launch the webclient server. This option requires the opsworks-web config')
  .describe('ops-api', 'setup config for the api on opsworks')
  .describe('ops-web', 'setup config for the webclient on opsworks')
  .describe('deploy-api', 'deploys webclient application on opsworks')
  .describe('deploy-web', 'deploys api application on opsworks')
  .describe('all', 'prepare, setup and launch all the things')

argv = optimist.argv;
promises = []

# stop if help option
if argv.help
  console.log optimist.help()
  return

nconf = require 'nconf'
RSVP = require 'rsvp'

# load config file
nconf.file {
  file: './aws-setup.json'
}

# aws sdk setup
AWS = require 'aws-sdk'
AWS.config.loadFromPath './aws-credentials.json'

# load modules
dbLaunchInstance = require './lib/db/db-launch-instance'
apiSetupOpsworks = require './lib/api/api-setup-opsworks'
apiLaunchInstance = require './lib/api/api-launch-instance'
apiDeployApp = require './lib/api/api-deploy-app'
webSetupOpsworks = require './lib/web/web-setup-opsworks'
webLaunchInstance = require './lib/web/web-launch-instance'

dbLaunchInstance.config { AWS: AWS, nconf: nconf }
apiSetupOpsworks.config {AWS: AWS, nconf: nconf }
apiLaunchInstance.config { AWS: AWS, nconf: nconf }
webSetupOpsworks.config {AWS: AWS, nconf: nconf }
webLaunchInstance.config { AWS: AWS, nconf: nconf }

# set flags
if argv.hasOwnProperty('all')
  setupDb = setupApi = setupWeb = opsworksApi = opsworksWeb = deployApi = true
else
  setupDb = argv.hasOwnProperty 'db'
  setupApi = argv.hasOwnProperty 'api'
  setupWeb = argv.hasOwnProperty 'web'
  opsworksApi = argv.hasOwnProperty 'ops-api'
  opsworksWeb = argv.hasOwnProperty 'ops-web'
  deployApi = argv.hasOwnProperty 'deploy-api'


if setupDb
  promises.push dbLaunchInstance.run

if opsworksApi
  promises.push apiSetupOpsworks.run

if setupApi
  promises.push apiLaunchInstance.run

if deployApi
  promises.push apiDeployApp.run

if opsworksWeb
  # after awsApi because we can use the api ip in chef
  promises.push webSetupOpsworks.run

if setupWeb
  promises.push webLaunchInstance.run

# run each promise after eachother
if promises.length
  chain = null
  promises.forEach (promise, index) =>
    chain = if chain then chain.then(promise) else promise()
    if index == promises.length - 1
      # append catch after last then
      chain.catch (err) =>
        console.log "caugth error #{index}", err
