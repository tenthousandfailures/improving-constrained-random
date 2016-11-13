package provide rclass_network 1.0

namespace eval ::rclass_network {

    # equal to negative to allow for grabbing first value of 0
    set objective_function [expr -1]
    set simtime [expr -1]
    set runname ""
    set seed_table [dict create]
    set proposed_count 0
    set existing_count 0
    set accepted_count 0
    set rejected_count 0
}


proc ::rclass_network::CurrentSeed {channel clientaddr clientport} {
    variable objective_function
    variable simtime
    variable seed_table
    variable proposed_count
    variable existing_count
    variable accepted_count
    variable rejected_count

    # puts "DEBUG Connection from $clientaddr on $clientport registered"

    # PROPOSED_SEED TIME SEED OBJECTIVE_FUNCTION RUNNAME
    gets $channel line
    set values [split $line]

    puts "--"
    puts "RECEIVED: from ${clientaddr}:${clientport} #${channel} ${line}"
    # puts "RECEIVED $proposed_simtime $proposed_seed $proposed_objective_function $runname"

    # TODO for minor performance reorder this decision tree
    if { [string equal [lindex $values 0] "SUMMARY"] } {
        puts "SUMMARY"
        puts $channel "SUMMARY: proposed_count: ${proposed_count} existing_count: ${existing_count} accepted_count: ${accepted_count} rejected_count: ${rejected_count} seed_table: $seed_table"
    } elseif { [string equal [lindex $values 0] "SHUTDOWN" ]} {
        puts "SHUTTING DOWN NOW"
        puts $channel "SHUTTING DOWN NOW"
        close $channel
        exit
    } elseif { [expr [llength $values] != 6] } {
        puts "  WARNING not given correct args ignoring - $values - [llength $values]"
        puts $channel "INCORRECT ARGUMENTS - PROPOSED_SEED TIME SEED OBJECTIVE_FUNCTION RUNNAME"
    } else {
        set proposed_time [lindex $values 1]
        set proposed_time_unit [lindex $values 2]

        # DICT CANT HANDLE SPACES
        set proposed_simtime "$proposed_time"
        set proposed_seed [lindex $values 3]
        set proposed_objective_function [lindex $values 4]
        set client_index [lindex $values 5]
        incr proposed_count

        # DEBUG
        # puts [dict info $seed_table]

        if {[dict exists $seed_table $proposed_simtime]} {
            puts $channel "EXISTING $proposed_simtime [dict get $seed_table $proposed_simtime]"
            puts "  EXISTING $proposed_simtime [dict get $seed_table $proposed_simtime] - from ${client_index}"
            incr existing_count
        } else {
            if { [expr $proposed_objective_function > $objective_function] } {
                # puts "DEBUG - $line"
                if { [expr {$proposed_simtime > $simtime}] } {
                    dict set seed_table "$proposed_simtime" $proposed_seed
                    set objective_function $proposed_objective_function
                    puts "  ACCEPTED $proposed_seed $proposed_simtime - from ${client_index}"
                    puts $channel "ACCEPTED $proposed_seed $proposed_simtime"
                    incr accepted_count
                };
            } else {
                # is case if client is just send all seeds - even bad ones up
                # puts "  REJECTED"
                puts "  REJECTED $proposed_simtime $proposed_seed - from ${client_index}"
                puts $channel "REJECTED $proposed_simtime $proposed_seed"
                incr rejected_count
            }
        }
    };
    close $channel
}
