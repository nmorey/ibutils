# This is the checker for for a fat-tree routing check

##############################################################################
# 
# Start up the test applications
# This is the default flow that will start OpenSM only in 0x43 verbosity
# Return a list of process ids it started (to be killed on exit)
#
proc runner {simDir osmPath osmPortGuid} { 
   set osmStdOutLog [file join $simDir osm.stdout.log]
   set osmLog [file join $simDir osm.log]
   puts "-I- Starting: $osmPath -R ftree -d2 -V -g $osmPortGuid ..."
   #set osmPid [exec $osmPath -f $osmLog -V -g $osmPortGuid  > $osmStdOutLog &]
   set osmPid [exec $osmPath -R ftree -f $osmLog -V -g $osmPortGuid  > $osmStdOutLog &]
   #set osmPid [exec valgrind --tool=memcheck -v --log-file-exactly=/tmp/kliteyn/osm.valgrind.log $osmPath -R ftree -f $osmLog -V -g $osmPortGuid  > $osmStdOutLog &]

   # start a tracker on the log file and process:
   startOsmLogAnalyzer $osmLog
     
   return $osmPid
}

##############################################################################
#
# Check for the test results
# 1. Make sure we got a "SUBNET UP"
# 2. Run ibdiagnet to check routing
# 3. Check that fat-tree routing has run to completion
# 4. Run congestion analysis
# 5. At each step, return the exit code in case of any failure
#
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
      puts "-E- ibdiagnet failed with status:$e"
      return 1
   }

   after 5000

   # Check that the fat-tree routing has run to completion.
   # If it has, then opensm-ftree-ca-order.dump file should exist 
   # in the simulation directory.
   set osmFtreeCAOrderDump [file join $simDir opensm-ftree-ca-order.dump]
   if {[file exists $osmFtreeCAOrderDump]} {
      puts "-I- Fat-tree CA ordering file exists"
   } else {
      puts "-E- Fat-tree CA ordering file doesn't exist"
      puts "-E- Fat-tree routing hasn't run to normal completion"
      return 1
   }

   set congestionScript "congestion"
   set ibdiagnetLstFile [file join $simDir ibdiagnet.lst]
   set ibdiagnetFdbsFile [file join $simDir ibdiagnet.fdbs]
   set congestionLog [file join $simDir congestion.log]
   set cmd "$congestionScript -o $ibdiagnetLstFile $ibdiagnetFdbsFile $osmFtreeCAOrderDump"

   puts "-I- Running congestion analysis"
   if {[catch {set res [eval "exec $cmd > $congestionLog"]} e]} {
      puts "-E- Congestion analysis failed with status: $e"
      return 1
   }
   
   puts "-I- Congestion analysis completed"
   puts "-I- Parsing congestion log"

   set maxNumPath 0
   set maxWorstCong 0
   set f [open $congestionLog]
   while {[gets $f sLine] >= 0} {
      
      if {[regexp {.*TOTAL CONGESTION HISTOGRAM.*} $sLine match]} {
         #seek three lines forward in the file
         if {[gets $f sLine] < 0 || [gets $f sLine] < 0 || [gets $f sLine] < 0} {
            puts "-E- Failed parsing congestion log: $congestionLog"
            return -1
         }
         puts "-I- Total congestion histogram:"
         while {[regexp {\s*(\d+)\s*(\d+)} $sLine match numPath numOutPorts]} {
            puts "-I-  - NumPaths: $numPath, NumOutPorts: $numOutPorts"
            if { $maxNumPath < $numPath } {
               set maxNumPath $numPath
            }
            # read next line
            if {[gets $f sLine] < 0} {
               puts "-E- Failed parsing congestion log: $congestionLog"
               return -1
            }
         }
      }
      
      if {[regexp {.*STAGE CONGESTION HISTOGRAM.*} $sLine match]} {
         #seek three lines forward in the file
         if {[gets $f sLine] < 0 || [gets $f sLine] < 0 || [gets $f sLine] < 0} {
            puts "-E- Failed parsing congestion log: $congestionLog"
            return -1
         }
         puts "-I- Stage congestion histogram:"
         while {[regexp {\s*(\d+)\s*(\d+)} $sLine match worstCong numStages]} {
            puts "-I-  - WorstCong: $worstCong, NumStages: $numStages"
            if { $maxWorstCong < $worstCong } {
               set maxWorstCong $worstCong
            }
            # read next line
            if {[gets $f sLine] < 0} {
               puts "-E- Failed parsing congestion log: $congestionLog"
               return -1
            }
         }
      }
   }
   close $f
   
   if {$maxNumPath > 1 || $maxWorstCong > 1} {
      puts "-E- FatTree routing is unbalanced"
      return 1
   }
   
   puts "-I- FatTree routing is well-balanced"
   return 0
}

