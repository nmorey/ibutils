# This is the checker for for a simple 16 node test with opensm and osmtest

##############################################################################
# 
# Start up the test applications
# This is the default flow that will start OpenSM only in 0x43 verbosity
# Return a list of process ids it started (to be killed on exit)
#
proc runner {simDir osmPath osmPortGuid} { 
   set osmStdOutLog [file join $simDir osm.stdout.log]
   set osmLog [file join $simDir osm.log]
   puts "-I- Starting: $osmPath -u -V -g $osmPortGuid ..."
   set osmPid [exec $osmPath -u -V -f $osmLog -g $osmPortGuid > $osmStdOutLog &]
   
   # start a tracker on the log file and process:
   startOsmLogAnalyzer $osmLog
     
   return $osmPid
}

# wait for the SM with the given log to be either dead or in subnet up
# also support 
proc osmWaitForUpOrDeadWithTimeout {osmLog timeout_ms} {
   global osmUpOrDeadEvents osmUpOrDeadLogLen
   global osmLogCallbacks
   
   # wait for OpenSM to complete setting up the fabric
   set osmUpOrDeadLogLen 0
   set osmLogCallbacks($osmLog) \
      "{waitForOsmEvent osmUpOrDeadEvents osmUpOrDeadLogLen $osmLog}"
   
   after $timeout_ms [list set osmUpOrDeadEvents {exit 0 {}}]
   puts "-I- Waiting for OpenSM subnet up ..."
   set done 0
   while {$done == 0} {
      vwait osmUpOrDeadEvents
      foreach event $osmUpOrDeadEvents {
         if {[lindex $event 0] == "exit"} {
            set exitCode 1
            set done 1
         } elseif {[lindex $event 0] == "SubnetUp"} {
            set done 1
            set exitCode 0
         }
      }
   }
   return $exitCode
}

##############################################################################
#
# Check for the test results: make sure we got a "SUBNET UP"
# Return the exit code
proc checker {simDir osmPath osmPortGuid} {
   global env
   set osmLog [file join $simDir osm.log]

   puts "-I- Waiting max time of 100sec...."

   if {[osmWaitForUpOrDeadWithTimeout $osmLog 1000000]} {
      return 1
   }

   after 5000

   set ibdiagnetLog [file join $simDir ibdiagnet.log]
   set cmd "ibdiagnet -o $simDir"

   puts "-I- Invoking $cmd "
   if {[catch {set res [eval "exec $cmd > $ibdiagnetLog"]} e]} {
      puts "-E- ibdiagnet failed"
      return 1
   }
   # make sure directory is not remoevd
   return 1
}
