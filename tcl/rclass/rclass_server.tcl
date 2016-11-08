package provide rclass_network 1.0

namespace eval ::rclass_network {

    # equal to negative to allow for grabbing first value of 0
    set target_function [expr -1]
    set simtime [expr -1]
    set runname ""
    set seed_table [dict create]
}


proc ::rclass_network::CurrentSeed {channel clientaddr clientport} {
    variable target_function
    variable simtime
    variable seed_table

    # puts "DEBUG Connection from $clientaddr on $clientport registered"

    # PROPOSED_SEED TIME SEED TARGET_FUNCTION RUNNAME
    gets $channel line
    set values [split $line]

    puts "--"
    puts "RECEIVED: $line"
    # puts "RECEIVED $proposed_simtime $proposed_seed $proposed_target_function $runname"

    if { [string equal [lindex $values 0] "SUMMARY"] } {
        puts "SUMMARY"
        puts $channel "SUMMARY: $seed_table"
    } elseif { [expr [llength $values] != 6] } {
        puts "  WARNING not given correct args ignoring - $values - [llength $values]"
        puts $channel "INCORRECT ARGUMENTS - PROPOSED_SEED TIME SEED TARGET_FUNCTION RUNNAME"
    } else {
        set proposed_time [lindex $values 1]
        set proposed_time_unit [lindex $values 2]

        # DICT CANT HANDLE SPACES
        set proposed_simtime "$proposed_time"
        set proposed_seed [lindex $values 3]
        set proposed_target_function [lindex $values 4]
        set runname [lindex $values 5]

        # DEBUG
        # puts [dict info $seed_table]

        if {[dict exists $seed_table $proposed_simtime]} {
            puts $channel "EXISTING $proposed_simtime [dict get $seed_table $proposed_simtime]"
            puts "  EXISTING"
        } else {
            if { [expr $proposed_target_function > $target_function] } {
                # puts "DEBUG - $line"
                if { [expr {$proposed_simtime > $simtime}] } {
                    dict set seed_table "$proposed_simtime" $proposed_seed
                    set target_function $proposed_target_function;
                    puts "  ACCEPTED $proposed_seed $proposed_simtime";
                    puts $channel "ACCEPTED $proposed_seed $proposed_simtime";
                };
            } else {
                # is case if client is just send all seeds - even bad ones up
                puts "  REJECTED"
                puts $channel "REJECTED $proposed_simtime $proposed_seed"
            }
        }
    };
    close $channel
}
