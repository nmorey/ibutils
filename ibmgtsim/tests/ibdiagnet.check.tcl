# This is the checker for that setup a network with OpenSM and then calls 
# the ibdiag on the full fabric
# Intended to run with a set of sim flows - each causing some other errors

##############################################################################
# 
# Start up the test applications
# This is the default flow that will start OpenSM only in 0x43 verbosity
# Return a list of process ids it started (to be killed on exit)
#
proc runner {simDir osmPath osmPortGuid} { 
   set osmStdOutLog [file join $simDir osm.stdout.log]
   set osmLog [file join $simDir osm.log]
   puts "-I- Starting: $osmPath -V -s 0 -g $osmPortGuid ..."
   set osmPid [exec $osmPath -d2 -V -s 0 -f $osmLog -g $osmPortGuid > $osmStdOutLog &]
   
   # start a tracker on the log file and process:
   startOsmLogAnalyzer $osmLog
     
   return $osmPid
}

##############################################################################
#
# Check for the test results: make sure we got a "SUBNET UP"
# Return the exit code
proc checker {simDir osmPath osmPortGuid} {
   global env simCtrlSock topologyFile
   set osmLog [file join $simDir osm.log]

   puts "-I- Waiting max time of 100sec...."

   if {[osmWaitForUpOrDeadWithTimeout $osmLog 1000000]} {
      return 1
   }

   # Invoke a simulation flow specific checker:
   puts $simCtrlSock "postSmSettings \$fabric"
   puts "SIM: [gets $simCtrlSock]"

   set ibdiagnetLog [file join $simDir ibdiagnet.stdout.log]
   set cmd "ibdiagnet -v -r -o $simDir -t $topologyFile"

   puts "-I- Invoking $cmd "
   if {[catch {set res [eval "exec $cmd > $ibdiagnetLog"]} e]} {
      puts "-E- ibdiagnet failed with error:$e"
      return 1
   }

   # Invoke a simulation flow specific checker:
   puts $simCtrlSock "verifyDiagRes \$fabric $ibdiagnetLog"
   set res [gets $simCtrlSock]
   puts "SIM: $res"
   if {$res == 0} {return 0} 

   # make sure directory is not remoevd
   return 1
}
