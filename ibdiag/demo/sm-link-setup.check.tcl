# This is the checker for SM LINK SETUP flow

##############################################################################
#
# Start up the test applications
# This is the default flow that will start OpenSM only in 0x43 verbosity
# Return a list of process ids it started (to be killed on exit)
#
proc runner {simDir osmPath osmPortGuid} {
   global simCtrlSock
   global env

   set osmStdOutLog [file join $simDir osm.stdout.log]
   set osmLog [file join $simDir osm.log]

   fconfigure $simCtrlSock -blocking 1 -buffering line

   # start the SM
	puts "---------------------------------------------------------------------"
	puts " Starting the SM\n"
   set valgrind "/usr/bin/valgrind --tool=memcheck"
   set osmCmd "$osmPath -D 0x43 -d2 -t 4000 -f $osmLog -g $osmPortGuid"
   puts "-I- Starting: $osmCmd"
   set osmPid [eval "exec $osmCmd > $osmStdOutLog &"]

   # start a tracker on the log file and process:
   startOsmLogAnalyzer $osmLog

   return $osmPid
}

##############################################################################
#
# Check for the test results
# Return the exit code
proc checker {simDir osmPath osmPortGuid} {
   global env
   global simCtrlSock
   global nodePortGroupList
	global GROUP_HOSTS
		
   # wait for the SM up or dead
   set osmLog [file join $simDir osm.log]
   if {[osmWaitForUpOrDead $osmLog]} {
      return 1
   }

	# make sure /proc is updated ...
	puts $simCtrlSock "updateProcFSForNode \$fabric $simDir H-1/U1 H-1/U1 1"
   set res [gets $simCtrlSock]
   puts "SIM: Updated H-1 proc file:$res"

	puts "---------------------------------------------------------------------"
	puts " OpemSM brought up the network\n"
	puts " Making some changes:"
	puts $simCtrlSock "setPortMTU \$fabric SL2-1/U1 1 256"
   puts "SIM: [gets $simCtrlSock]"
	puts $simCtrlSock "setPortOpVLs \$fabric SL2-3/U1 1 2"
   puts "SIM: [gets $simCtrlSock]"
	puts $simCtrlSock "setPortWidth \$fabric SL2-1/U1 4 1x"
   puts "SIM: [gets $simCtrlSock]"
	puts $simCtrlSock "setPortSpeed \$fabric SL2-4/U1 3 2.5"
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
