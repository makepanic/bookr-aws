# commandline handling
optimist = require('optimist')
  .usage('Bootstraps AWS environment for bookr components.')
  .describe('db', 'prepare and launch database server')
  .describe('api', 'prepare and launch api server')
  .describe('web', 'prepare and launch web app server')
  .describe('all', 'prepare and launch database, api and web app server')
  .describe('ops-api', 'opsworks-api')

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

awsMongo.config { AWS: AWS, nconf: nconf }
awsApi.config { AWS: AWS, nconf: nconf }
awsWeb.config { AWS: AWS, nconf: nconf }
opsWorksApi.config {AWS: AWS, nconf: nconf }

# set flags
if argv.hasOwnProperty('all')
  setupDb = setupApi = setupWeb = opsworksApi = true
else
  setupDb = argv.hasOwnProperty 'db'
  setupApi = argv.hasOwnProperty 'api'
  setupWeb = argv.hasOwnProperty 'web'
  opsworksApi = argv.hasOwnProperty 'ops-api'

if opsworksApi
  promises.push opsWorksApi.run

if setupDb
  promises.push awsMongo.run

if setupApi
  promises.push awsApi.run

if setupWeb
  promises.push awsWeb.run

# run each promise after eachother
if promises.length
  chain = null
  promises.forEach (promise, index) =>
    chain = if chain then chain.then(promise) else promise()
    if index == promises.length - 1
      chain.catch (err) =>
        console.log "caugth error #{index}", err
