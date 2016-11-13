#! /usr/bin/tclsh

lappend auto_path [file join [pwd] "tcl/rclass"]

package require rclass_network 1.0

puts "starting server"
socket -server ::rclass_network::CurrentSeed 9000
# optional
# -myaddr 127.0.0.1

vwait forever
