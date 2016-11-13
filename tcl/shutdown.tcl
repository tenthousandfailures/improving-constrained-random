#! /usr/bin/tclsh

set server 127.0.0.1
set sockChan [socket $server 9000]

puts $sockChan "SHUTDOWN";
flush $sockChan;

gets $sockChan line;
puts "SERVER RESPONSE $line"

close $sockChan
