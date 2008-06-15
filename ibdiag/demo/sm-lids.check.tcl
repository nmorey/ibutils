# This is the checker for SM lid assignment checks

##############################################################################
#
# Start up the test applications
# This is the default flow that will start OpenSM only in 0x43 verbosity
# Return a list of process ids it started (to be killed on exit)
#
proc runner {simDir osmPath osmPortGuid} {
   global simCtrlSock
   global env
   global lmc

   set osmStdOutLog [file join $simDir osm.stdout.log]
   set osmLog [file join $simDir osm.log]

   set lmc 1
   fconfigure $simCtrlSock -blocking 1 -buffering line

	puts "---------------------------------------------------------------------"
	puts " Starting the SM\n"

   set osmCmd "$osmPath -l $lmc -d2 -f $osmLog -g $osmPortGuid"
	puts "-I- Starting: $osmCmd"
   set osmPid [eval "exec $osmCmd > $osmStdOutLog &"]

   # start a tracker on the log file and process:
   startOsmLogAnalyzer $osmLog

   return $osmPid
}

##############################################################################
#
# Check for the test results: make sure we got a "SUBNET UP"
# Return the exit code
proc checker {simDir osmPath osmPortGuid} {
   global env
   global simCtrlSock
   global lmc
   set osmLog [file join $simDir osm.log]

   if {[osmWaitForUpOrDeadWithTimeout $osmLog 1000000]} {
      return 1
   }

	puts "---------------------------------------------------------------------"
	puts " OpemSM brought up the network"
	puts " Randomizing some LIDs ... "

	# randomize lid errors:
	puts $simCtrlSock "setLidAssignmentErrors \$fabric $lmc"
	puts "SIM: [gets $simCtrlSock]"
	
	puts "---------------------------------------------------------------------"
	puts " SUBNET READY FOR DIAGNOSTICS"
	puts "\nCut and paste the following in a new window then run ibdiagnet:"
	puts "cd $simDir"
	puts "setenv IBMGTSIM_DIR  $simDir"
	puts "setenv OSM_CACHE_DIR $simDir"
	puts "setenv OSM_TMP_DIR   $simDir"
	puts " "
	puts " press Enter when done"
	gets stdin	
   return 0
}
