
puts "FLOW: set some unicast partial connectivity"

# get random list of switch nodes:
proc getRandomSwitchNodesList {fabric} {
   # get number of nodes:
   set nodesByName [IBFabric_NodeByName_get $fabric]
   
   set nodeNOrderList {}
   foreach nodeNameNId [IBFabric_NodeByName_get $fabric] {
      set node [lindex $nodeNameNId 1]
      
      # only switches please
      if {[IBNode_type_get $node] == 1} {
         lappend nodeNOrderList [list $node [rmRand]]
      }
   }
   
   set randNodes {}
   foreach nodeNRnd [lsort -index 1 -real $nodeNOrderList] {
      lappend randNodes [lindex $nodeNRnd 0]
   }
   return $randNodes   
}

# scan the switches (randomly) for a LFT entry which is not zero
# delete one entry ...
proc removeUCastRouteEntry {fabric} {
   set nodes [getRandomSwitchNodesList $fabric]
   
   while {[llength $nodes]} {
      set node [lindex $nodes 0]
      set nodeName [IBNode_name_get $node]
      set lft [IBNode_LFT_get $node]
      
      # convert to LID Port list
      set lidPortList {}
      for {set lid 0 } {$lid < [llength $lft]} {incr lid} {
         set outPort [lindex $lft $lid]
         if {($outPort != 0xff) && ($outPort != 0) } {
            lappend lidPortList [list $lid $outPort]
         }
      }

      # select a random entry 
      if {[llength $lidPortList]} {
         set badLidIdx [expr int([rmRand]*[llength $lidPortList])]
         set badLidNPort [lindex $lidPortList $badLidIdx]
         set badLid [lindex $badLidNPort 0]
         set wasPort [lindex $badLidNPort 1]
         puts "-I- Deleting LFT on $nodeName lid:$badLid (was $wasPort)"
         IBNode_setLFTPortForLid $node $badLid 0xff
         return 0
      }
      set nodes [lrange $nodes 1 end]
   }
   return 1
}

# setup post SM run changes:
proc postSmSettings {fabric} {
   global errorInfo
   set nDisconencted 0
   # now go and delete some switch MC entries...
   for {set i 0} {$i < 3} {incr i} {
      # delete one entry
      if {![removeUCastRouteEntry $fabric]} {
         incr nDisconencted
      }
   }
   return "-I- Disconnected $nDisconencted LFT Entries"
}

# make sure ibdiagnet reported the bad links
proc verifyDiagRes {fabric logFile} {
   return "Could not figure out if OK yet"
}

set fabric [IBMgtSimulator getFabric]

