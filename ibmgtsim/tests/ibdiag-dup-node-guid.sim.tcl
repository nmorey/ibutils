
puts "FLOW: duplicate some node guid"

# duplicate the node guid from the source to the dest
proc dupNodeGuid {fromNode toNode} {
   global errorInfo
   set newGuid [IBNode_guid_get $fromNode]
   set toNodeName [IBNode_name_get $toNode]
   set fromNodeName [IBNode_name_get $fromNode]
   puts "-I- Overriding node:$toNodeName guid to $newGuid (dup of $fromNodeName)"

   # IBDM ...
   IBNode_guid_set $toNode $newGuid

   # But we need to deal with the SIMNODE too:
   set simNode "sim$toNode"
   set ni [IBMSNode_getNodeInfo $simNode]
   ib_node_info_t_node_guid_set $ni $newGuid
}

# get a random order of all the fabric nodes:
proc getNodesByRandomOreder {fabric} {
   # get number of nodes:
   set nodesByName [IBFabric_NodeByName_get $fabric]

   set nodeNOrderList {}
   foreach nodeNameNId [IBFabric_NodeByName_get $fabric] {
      set node [lindex $nodeNameNId 1]
      lappend nodeNOrderList [list $node [rmRand]]
   }

   set randNodes {}
   foreach nodeNRnd [lsort -index 1 -real $nodeNOrderList] {
      lappend randNodes [lindex $nodeNRnd 0]
   }
   return $randNodes
}

# setup post SM run changes:
proc postSmSettings {fabric} {
   return "-I- Nothing to be done post SM"
}

# make sure ibdiagnet reported the bad links
proc verifyDiagRes {fabric logFile} {
   return "-I- Could not figure out if OK yet"
}

set fabric [IBMgtSimulator getFabric]

# get a random order of the end ports:
set randNodes [getNodesByRandomOreder $fabric]
set numNodes [llength $randNodes]
set idx [expr int([rmRand]*$numNodes)]

set fromNode [lindex $randNodes $idx]
set toNode [lindex $randNodes [expr $idx+1]]

dupNodeGuid $fromNode $toNode
