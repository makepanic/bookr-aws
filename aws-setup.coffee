# commandline handling
optimist = require('optimist')
  .usage('Bootstraps AWS environment for bookr components.')
  .describe('db', 'prepare and launch database server')
  .describe('api', 'prepare and launch api server')
  .describe('web', 'prepare and launch web app server')
  .describe('all', 'prepare and launch database, api and web app server')

argv = optimist.argv;
promises = []

# stop if help option
if argv.help
  console.log optimist.help()
  return

RSVP = require 'rsvp'

# aws sdk setup
AWS = require 'aws-sdk'
AWS.config.loadFromPath './aws-credentials.json'

# bookr components setups
awsMongo = require './lib/bookr-mongo'
awsApi = require './lib/bookr-api'
awsWeb = require './lib/bookr-web'

awsMongo.config {
  AWS: AWS
}
awsApi.config {
  AWS: AWS
}
awsWeb.config {
  AWS: AWS
}

# set flags
if argv.hasOwnProperty('all')
  setupDb = setupApi = setupWeb = true
else
  setupDb = argv.hasOwnProperty 'db'
  setupApi = argv.hasOwnProperty 'api'
  setupWeb = argv.hasOwnProperty 'web'

if setupDb
  promises.push awsMongo.run

if setupApi
  promises.push awsApi.run

if setupWeb
  promises.push awsWeb.run

if promises.length
  chain = null
  promises.forEach (promise) =>
    chain = if chain then chain.then(promise) else promise()