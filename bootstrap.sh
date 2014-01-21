#!/usr/bin/env bash

# update ubuntu package repo
apt-get update > /dev/null

# install nodejs requirements (say yes to all)
apt-get install -y python-software-properties python g++ make git
add-apt-repository -y ppa:chris-lea/node.js
apt-get update > /dev/null
apt-get -y install nodejs

# create tmux session with teamocil webdev config
cd /vagrant/
npm install