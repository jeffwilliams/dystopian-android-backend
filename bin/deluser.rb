#!/usr/bin/env ruby
require 'lib/authentication.rb'
require 'lib/const.rb'

if ARGV.size == 0
  puts "Usage: #{$0} <username>"
  exit 1
end
user = ARGV[0]
auth = Authentication.new(PASSWD_FILE)
auth.del_account(user)

