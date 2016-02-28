#!/usr/bin/expect

set PW "vagrant"

spawn   ssh root@centos1
expect  "password"
send    "$PW\n"
expect  "#"
send    "hostname\n"
expect  "#"
exit
