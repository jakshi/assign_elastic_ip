#!/usr/bin/ruby
# This is a script that assign Elastic IP to current instance.
# Usage:
# You need to fill out config_eip.json config file:
# {
# "aws_access_key": "aws_access_key",
# "aws_secret_key": "aws_secret_key",
# "eip": "x.x.x.x",
# }
#
# Config file should be in the same dir as a script
# then, start script:
# assign_eip.rb
# This will assign x.x.x.x Elastic IP to current instance.

require "rubygems"
require "json"
require "net/http"
require "fog"

# Read config
CONFIG = JSON.parse(IO.read(File.join(File.dirname(__FILE__), 'assign_eip.json')))

# Here we need to get server.id
INSTANCE_HOST = '169.254.169.254'
INSTANCE_ID_URL = '/latest/meta-data/instance-id'
INSTANCE_REGION_URL = '/latest/meta-data/placement/availability-zone'

httpcall = Net::HTTP.new(INSTANCE_HOST)
resp, instance_id = httpcall.get2(INSTANCE_ID_URL)
resp, region = httpcall.get2(INSTANCE_REGION_URL)

# Cut out availability zone marker.
# For example if region == "us-east-1c" after cutting out it will be
# "us-east-1"

region = region[0..-2]

# First we get a connection object from amazon, region is
# required if your instances are in other zone than the
# gem's default one (us-east-1).

c = Fog::Compute.new(
                     :provider => 'AWS',
                     :aws_access_key_id => CONFIG['aws_access_key'],
                     :aws_secret_access_key => CONFIG['aws_secret_key'],
                     :region => region )

# Then we get Fog::Compute::AWS::Address to get allocation_id of
# Elastic IP.
# For some reason I failed to make it work with IP address directly.
# if I use Elastic IP instead of allocation id it always returns 400
# Bad Request.

eip = c.addresses.get(CONFIG['eip'])

# Then we accociate Elastic IP with current node.

c.associate_address(instance_id,nil,nil,eip.allocation_id)
