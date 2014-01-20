# commandline handling
optimist = require('optimist')
  .usage('Bootstraps AWS environment for bookr components.')
  .describe('db', 'prepare and launch the database server')
  .describe('api', 'prepare and launch the api server. This option requires the opsworks-api config')
  .describe('web', 'prepare and launch the webclient server. This option requires the opsworks-web config')
  .describe('ops-api', 'setup config for the api on opsworks')
  .describe('ops-web', 'setup config for the webclient on opsworks')
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

# bookr components setups
awsMongo = require './lib/bookr-mongo'
awsApi = require './lib/bookr-api'
awsWeb = require './lib/bookr-web'
opsWorksApi = require './lib/api/opsworks-api-setup'
opsWorksWeb = require './lib/api/opsworks-web-setup'

awsMongo.config { AWS: AWS, nconf: nconf }
awsApi.config { AWS: AWS, nconf: nconf }
awsWeb.config { AWS: AWS, nconf: nconf }
opsWorksApi.config {AWS: AWS, nconf: nconf }
opsWorksWeb.config {AWS: AWS, nconf: nconf }

# set flags
if argv.hasOwnProperty('all')
  setupDb = setupApi = setupWeb = opsworksApi = opsworksWeb = true
else
  setupDb = argv.hasOwnProperty 'db'
  setupApi = argv.hasOwnProperty 'api'
  setupWeb = argv.hasOwnProperty 'web'
  opsworksApi = argv.hasOwnProperty 'ops-api'
  opsworksWeb = argv.hasOwnProperty 'ops-web'


if setupDb
  promises.push awsMongo.run

if opsworksApi
  promises.push opsWorksApi.run

if setupApi
  promises.push awsApi.run

if opsworksWeb
  # after awsApi because we can use the api ip in chef
  promises.push opsWorksWeb.run

if setupWeb
  promises.push awsWeb.run

# run each promise after eachother
if promises.length
  chain = null
  promises.forEach (promise, index) =>
    chain = if chain then chain.then(promise) else promise()
    if index == promises.length - 1
      # append catch after last then
      chain.catch (err) =>
        console.log "caugth error #{index}", err
