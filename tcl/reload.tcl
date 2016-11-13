lappend auto_path [file join [pwd] "tcl/rclass"]

package require rclass 1.0

# need to run to end of time zero to initialize everything
run 0

# setup the trigger to evaluate on
stop -quiet -change {top.rseed_interface.trigger} -command {rclass::reload_loop;} -continue
stop -quiet -change {top.rseed_interface.final_report} -command {rclass::final_report; } -continue

# add logging
# dump -add top -depth 0 -aggregates

# start main function
rclass::reload_main
run

puts "INFO STATUS : TCL : DONE"
