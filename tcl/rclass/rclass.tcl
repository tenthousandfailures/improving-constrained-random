package provide rclass 1.0

package require rclass_network 1.0

# TODO keep delta checkpoints to go faster
# TODO coordinate with other simulation

namespace eval ::rclass {

    set server "rclass_localhost"
    set port 99

    set ctime [senv time]

    set old_objective [expr -1];
    set new_objective 0.0;

    # file name handle number of report file
    set replicate_id 0

    set ptime "0 ns"

    set last_seed 0

    set ptline "";

    set check_id "";

    set max_objective 100.0;

    # time value of last EXISTING processed
    set p_existing [expr -1]

    set iteration_count 0;
}

proc ::rclass::final_report {} {
    variable iteration_count
    puts "INFO STATUS : TCL : ITERATIONS TOTAL = ${iteration_count}"
    puts "INFO STATUS : TCL : final_report END"
}

proc ::rclass::reload_loop {} {

    variable ctime
    variable old_objective
    variable new_objective
    variable ptime
    variable last_seed
    variable ptline
    variable check_id
    variable iteration_count
    variable max_objective
    variable replicate_id

    set ctime [senv time];

    # puts "INFO STATUS : TCL : ctime is $ctime : ptime is $ptime"

    set reload_data [read $replicate_id]
    seek $replicate_id 0
    # close $reload_id

    foreach line [split $reload_data "\n"] {
        set a [lindex [split $line " "] 0]
        set b [lindex [split $line " "] 1]
        set c "$a $b"
        # puts "DEBUG $line"
        # puts [join [lindex $line {0 1}] " "]
        if {$c == $ctime} {
            set seed [lindex [split $line " "] end]
            call top.rseed_interface.set_seed(32'd${seed})
            puts "INFO STATUS : TCL : MANUALLY SETTING seed: $seed at ctime: $ctime"
        };
    };

    # set ptime [senv time];

};


proc ::rclass::send_progress {} {

    variable server
    variable port

    variable ptime
    variable old_objective
    variable new_objective
    variable last_seed

    # set server 127.0.0.1
    set sockChan [socket $server 9900]

    # client sends in its proposed time and seed
    puts $sockChan "PROPOSED_SEED $ptime $last_seed $new_objective RUNX";
    flush $sockChan;

    # server evaluates the PROPOSED_SEED and responds with CURRENT_SEED
    gets $sockChan line
    puts "SERVER RESPONSE $line"

    close $sockChan
    return $line
}

proc ::rclass::eval_loop {} {
    variable server
    variable port

    variable ctime
    variable old_objective
    variable new_objective
    variable replicate_id
    variable ptime
    variable last_seed
    variable ptline
    variable check_id
    variable iteration_count
    variable max_objective

    variable p_existing

    puts "------------------------- START eval_loop"

    # increment the iteration_count
    incr iteration_count
    set ctime [senv time];

    puts "DEBUG current simulation time is ctime : $ctime"

    # set tseed 0

    set line ""

    # DEBUG
    # puts "ITERATION: ${iteration_count}"

    set new_objective [get top.rseed_interface.coverage_value -radix decimal]
    set last_seed [format %u $last_seed]
    # set new_objective [call top.get_coverage_value()]

    if { [string equal $server "none"] } {
        set line "LOCAL"
    } else {
        set line [send_progress];
    }

    # puts " DEBUG ctime: $ctime line: $line"

    set status [lindex $line 0]
    if { [string equal $status "EXISTING"] } {

        # puts "INFO STATUS : TCL : SERVER EXISTING seed: $last_seed to be used at time: $ptime"

        puts "ptime: $ptime : $old_objective -> $new_objective : seed $last_seed"
        puts $replicate_id "$ptime : $old_objective -> $new_objective : seed $last_seed"

        # DONT REWIND TO TIME 0
        if { [string equal $ptime "0 ns"] } {
            puts "DEBUG TIME ZERO NO REWIND"
            set ptime [senv time];
            set old_objective "$new_objective"

            set last_seed [format %u [lindex $line end]]
            call top.rseed_interface.set_seed(32'd${last_seed})

            checkpoint -kill 0;
            set check_id [checkpoint -add "check"]
        } else {

            # IF YOU ALREADY REWOUND WITH THE RECOMMENDED SEED LET IT FLOW THROUGH
            if { [string equal $p_existing $ptime] } {
                puts "DEBUG DO NOT REWIND"
                set ptime [senv time]
                # set p_existing $ptime
                set old_objective "$new_objective"

                puts "DEBUG STATUS : TCL : EXISTING SEED PREVIOUS used of [lindex $line end] for $ptime"
                set last_seed [format %u [lindex $line end]]
                call top.rseed_interface.set_seed(32'd${last_seed})

                checkpoint -kill 0;
                set check_id [checkpoint -add "check"]
            } else {
                # IF EXISTING REWIND TO PREVIOUS TIME AND SET SEED
                # set ptime [senv time];
                set p_existing $ptime

                checkpoint -join "$check_id" -keep

                puts "DEBUG STATUS : TCL : EXISTING SEED FIRST TIME used of [lindex $line end] for $ptime"
                set last_seed [format %u [lindex $line end]]
                call top.rseed_interface.set_seed(32'd${last_seed})

            }

        }


    } elseif { [string equal $status "ACCEPTED"] } {

        puts "INFO STATUS : TCL : SERVER ACCEPTED seed: $last_seed at time: $ptime"

        puts $replicate_id "$ptime : $old_objective -> $new_objective : seed $last_seed"
        flush $replicate_id;

        puts "INFO STATUS : TCL : $ctime : GOOD : $new_objective > $old_objective"
        set old_objective "$new_objective"; #

        # print out times and seed values used
        set ptime [senv time];
        # puts "DEBUG old_objective is now $old_objective and ptime is $ptime"

        checkpoint -kill 0;
        set check_id [checkpoint -add "check"]
        # puts "DEBUG check_id is $check_id";
        # checkpoint -list

    } elseif { [string equal $status "REJECTED"] } {
        puts "INFO STATUS : TCL : SERVER REJECTED seed: $last_seed at time: $ptime"

        # DEBUG
        puts "INFO STATUS : TCL : $ctime : NO PROGRESS : false: $new_objective > $old_objective REWINDING TO CHECKPOINT {$check_id} at $ptime"; #
        checkpoint -join "$check_id" -keep;
        # checkpoint -list

        # TODO which is necessary
        # THIS WORKS
        # force top.dif.seed 32'd[expr {int(rand()*4294967294+1)}] -deposit

        # THESE DO NOT WORK
        # call top.set_seed(32'd${tseed})

        set last_seed [expr {int(rand()*4294967294+1)}]

        call top.rseed_interface.set_seed(32'd${last_seed})
        # puts "DEBUG redoing with $last_seed at $ptime"

    } elseif { [string equal $status "LOCAL"] } {

        if { [expr "$new_objective" > "$old_objective"] || [expr "$new_objective" >= ${max_objective}] } {
            puts "INFO STATUS : TCL : LOCAL ACCEPTED seed: $last_seed at time: $ptime"
            puts $replicate_id "$ptime : $old_objective -> $new_objective : seed $last_seed"
            flush $replicate_id;

            puts "INFO STATUS : TCL : $ctime : GOOD : $new_objective > $old_objective"
            set old_objective "$new_objective"; #

            # print out times and seed values used
            set ptime [senv time];
            # puts "DEBUG old_objective is now $old_objective and ptime is $ptime"

            checkpoint -kill 0;
            set check_id [checkpoint -add "check"]
            # puts "DEBUG check_id is $check_id";
            # checkpoint -list
        } else {
            puts "INFO STATUS : TCL : LOCAL REJECTED seed: $last_seed at time: $ptime"

            # DEBUG
            puts "INFO STATUS : TCL : $ctime : NO PROGRESS : false: $new_objective > $old_objective REWINDING TO CHECKPOINT {$check_id} at $ptime"; #
            checkpoint -join "$check_id" -keep;
            # checkpoint -list

            # TODO which is necessary
            # THIS WORKS
            # force top.dif.seed 32'd[expr {int(rand()*4294967294+1)}] -deposit

            # THESE DO NOT WORK
            # call top.set_seed(32'd${tseed})

            set last_seed [expr {int(rand()*4294967294+1)}]

            call top.rseed_interface.set_seed(32'd${last_seed})
            # puts "DEBUG redoing with $last_seed at $ptime"
        }

    } else {
        puts "INFO STATUS : TCL : SERVER ERROR SHOULD NOT GET HERE at time ctime: $ctime - $line"
    }

    if {[expr "$new_objective" >= "${max_objective}"]} {
        puts "INFO STATUS : TCL : MET OBJECTIVE!"
    }

    # TODO DEBUG ONLY WAIT
    # after 50;

    puts "------------------------- END eval_loop"

};

proc ::rclass::reload_main {} {
    variable replicate_id

    set replicate_id [open "replicate" "r"]
}

proc ::rclass::main {} {
    variable replicate_id

    variable server
    variable port
    variable max_objective
    variable last_seed

    set replicate_id [open "replicate" "w"]

    # puts $replicate_id "$ctime : 0.0 : seed $last_seed"
    # flush $replicate_id

    # call top.get_instance()
    set server [get top.rseed_interface.server]
    set port [get top.rseed_interface.port]
    set max_objective [get top.rseed_interface.max_objective]
    set last_seed [format %u [get top.rseed_interface.seed]]

    puts "DEBUG last_seed : $last_seed"

    puts "DEBUG server: $server and port: $port"
    if { $server == "none" } {
        puts "DEBUG since server is set to none - only running locally"
    }

    set check_id [checkpoint -add "check"]

};
