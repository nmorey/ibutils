# This is the checker for the semi static lid assignment feature:

# A. the sim code should generate the cache file once the simulator is up.
# it should randomize:
# 1. some guids should not have a lid
# 2. some guids should share a lid
# 3. some extra guids should be there

# B. Wait for OpenSM SUBNET UP
#
# C. The simulator code should randomally do the following (several of each)
# 1. Zero some port lids
# 2. Copy some port lids to other ports
# 3. Invent some new lids to some ports
# 4. Turn some node ports down - disconect (all ports of the node)
# 
# D. The simulator shoudl send a trap or set a switch change bit
#
# E. Wait for heavy sweep.
#
# F. The simulator code should verify that the lids match what it expects:
#    Note that the nodes that did have a non overlapping lid in the file
#    must have it. The rest of the ports should have valid lid values.
#

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

   # randomize lids
   puts $simCtrlSock "assignLegalLids \$fabric $lmc"
   puts "SIM: [gets $simCtrlSock]"
   
   # randomize lid failures:
   puts $simCtrlSock "setLidAssignmentErrors  \$fabric $lmc"
   puts "SIM: [gets $simCtrlSock]"

   # randomize guid2lid file:
   set env(OSM_CACHE_DIR) $simDir/
   puts $simCtrlSock "writeGuid2LidFile $simDir/guid2lid $lmc"
   puts "SIM: [gets $simCtrlSock]"
   
   file copy $simDir/guid2lid $simDir/guid2lid.orig

   set osmCmd "$osmPath -l $lmc -V -f $osmLog -g $osmPortGuid"
   puts "-I- Starting: $osmCmd"
   set osmPid [eval "exec $osmCmd > $osmStdOutLog &"]
   
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
   global simCtrlSock
   global lmc
   set osmLog [file join $simDir osm.log]

   puts "-I- Waiting max time of 100sec...."

   if {[osmWaitForUpOrDeadWithTimeout $osmLog 1000000]} {
      return 1
   }

   # check for lid validity:
   puts $simCtrlSock "checkLidValues \$fabric $lmc"
   set res [gets $simCtrlSock]
   puts "SIM: Number of check errors:$res"
   if {$res != 0} {
      return $res
   }

   # we try several iterations of changes:
   for {set i 1} {$i < 5} {incr i} {
      # connect the disconnected
      puts $simCtrlSock "connectAllDisconnected \$fabric"
      puts "SIM: [gets $simCtrlSock]"

      # refresh the lid database and start the POST_SUBNET_UP mode
      puts $simCtrlSock "updateAssignedLids \$fabric"
      puts "SIM: [gets $simCtrlSock]"
      
      # randomize lid failures:
      puts $simCtrlSock "setLidAssignmentErrors \$fabric $lmc"
      puts "SIM: [gets $simCtrlSock]"

      # inject a change bit 
      puts $simCtrlSock "setOneSwitchChangeBit \$fabric"
      puts "SIM: [gets $simCtrlSock]"

      # wait for sweep to end or exit
      if {[osmWaitForUpOrDeadWithTimeout $osmLog 1000000]} {
         return 1
      }
      
      # wait 3 seconds
      after 3000
      
      # check for lid validity:
      puts $simCtrlSock "checkLidValues \$fabric $lmc"
      set res [gets $simCtrlSock]
      puts "SIM: Number of check errors:$res"
      if {$res != 0} {
         return $res
      }
   }

   return 0
}
