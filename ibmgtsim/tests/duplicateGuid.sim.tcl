
puts "Randomally Set Duplicated Port Guid (do not touch the SM port)"

proc duplicatePortGuid {fromPort toPort } {
   IBPort_guid_set $toPort [IBPort_guid_get $fromPort]
}

# get a random order of all the fabric nodes:
proc getNodesByRandomOreder {fabric} {
   # get number of nodes:
   set nodesByName [IBFabric_NodeByName_get $fabric]

   set nodeNameNOrderList {}
   foreach nodeNameNId [IBFabric_NodeByName_get $fabric] {
      lappend nodeNameNOrderList [list [lindex $nodeNameNId 1] [rmRand]]
   }

   set randNodes {}
   foreach nodeNameNOrder [lsort -index 1 -real $nodeNameNOrderList] {
      lappend randNodes [lindex $nodeNameNOrder 0]
   }
   return $randNodes
}

set fabric [IBMgtSimulator getFabric]

# get a random order of the nodes:
set randNodes [getNodesByRandomOreder $fabric]
set numNodes [llength $randNodes]

# now get the first N nodes for err profile ...
set numNodesUsed 0
set idx 0
while {($numNodesUsed < $numNodes / 10) && ($numNodesUsed < 12) && ($idx < $numNodes)} {
   set node [lindex $randNodes $idx]
   # ignore the root node:
   if {[IBNode_name_get $node] != "H-1/U1"} {
      if {[IBNode_type_get $node] != 1} {
         setNodePortErrProfile $node
         incr numNodesUsed
      }
   }
   incr idx
}
