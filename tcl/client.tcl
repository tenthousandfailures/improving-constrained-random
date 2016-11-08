#! /usr/bin/tclsh

set simtime 0
set target_function 0

while {1} {

    set server 127.0.0.1
    set sockChan [socket $server 9900]

    # client sends in its proposed time and seed
    puts $sockChan "PROPOSED_SEED $simtime ns [expr $simtime * 2] $target_function RUNX";
    flush $sockChan;

    incr target_function
    incr simtime

    # server evaluates the PROPOSED_SEED and responds with CURRENT_SEED
    gets $sockChan line
    puts "SERVER RESPONSE $line"

    close $sockChan
    after 50;

}
