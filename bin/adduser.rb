#!/usr/bin/env ruby
require 'lib/authentication.rb'

PASSWD_FILE = "etc/passwd"

if ARGV.size == 0
  puts "Usage: #{$0} <username>"
  exit 1
end

system "stty -echo"
begin
  user = ARGV[0]
  print "Password: "
  $stdout.flush
  passwd1 = $stdin.gets.strip
  puts
  print "Password again: "
  $stdout.flush
  passwd2 = $stdin.gets.strip
  puts
rescue
  puts "Exception: #{$!}"
end
system "stty echo"

if passwd1 != passwd2
  puts "Passwords don't match"
  exit 1
end

auth = Authentication.new(PASSWD_FILE)
auth.add_account(user, passwd1)
