puts "Running Simulation flow for PKey test"

# Randomally assign PKey tables of 3 types:
# Group 1 : .. 0x81
# Group 2 : ........ 0x82 ...
# Group 3 : ... 0x82 ... 0x81 ...
# 
# So osmtest run from nodes of group1 should only see group1
# Group2 should only see group 2 and group 3 should see all.

# to prevent the case where our pkeys match the randomized ones
# we use a range of pkeys 0x80PP for the given Pkeys and 
# 0x0000-0x7FFF for the random ones

proc getRandomPkey {} {
   return [format 0x%04x [expr int([rmRand] * 0x7fff)]]
}

proc getGroupPkey {} {
   return [format 0x%04x [expr int([rmRand] * 0xfff) + 0x8000]]
}

# produce a random PKey containing the given pkeys
proc getRandomPkeysWithGivenPkey {numPkeys pkeys} {

   # randomally select indexes for the given pkeys:
   # fill in the result list of pkeys with random ones,
   # also select an index for each of the given pkeys and
   # replace the random pkey with the given one

   # hold the full list of indexes to randomly select from
   set idxes {}
   
   # flat pkey list (no blocks)
   set res {}
   
   # init both lists
   for {set i 0} {$i < $numPkeys} {incr i} {
      lappend idxes $i
      lappend res [getRandomPkey]
   }

   # select where to insert the given pkeys
   for {set i 0} {$i < [llength $pkeys]} {incr i} {
      set pkeyIdx [expr int([rmRand] * [llength $idxes])]
      set res [lreplace $res $pkeyIdx $pkeyIdx [lindex $pkeys $i]]
   }
      
   return $res
}

# get a flat list of pkeys and partition into blocks:
proc getPkeyBlocks {pkeys} {
   set blocks {}
   set extra {0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0}
   
   set nKeys [llength $pkeys]
   while {$nKeys} {
      if {$nKeys < 32} {
         append pkeys " [lrange $extra 0 [expr 32 - $nKeys - 1]]"
      }
      lappend blocks [lrange $pkeys 0 31]
      set pkeys [lrange $pkeys 32 end]
      set nKeys [llength $pkeys]
   }
   return $blocks
}

# find all active HCA ports
proc getAllActiveHCAPorts {fabric} {
   set hcaPorts {}

   # go over all nodes:
   foreach nodeNameId [IBFabric_NodeByName_get $fabric] {
      set node [lindex $nodeNameId 1]
      
      # we do care about non switches only
      if {[IBNode_type_get $node] != 1} {
         # go over all ports:
         for {set pn 1} {$pn <= [IBNode_numPorts_get $node]} {incr pn} {
            set port [IBNode_getPort $node $pn]
            if {($port != "") && ([IBPort_p_remotePort_get $port] != "")} {
               lappend hcaPorts $port
            }
         }
      }
   }
   return $hcaPorts
}

# prepare the three PKey groups G1 G2 abd G3
# then randomly set the active HCA ports PKey tables
# Note that the H-1/P1 has to have a slightly different PKey table
# with 0xffff such that all nodes can query the SA:
# we track the assignments in the array: PORT_PKEY_GROUP
proc setAllHcaPortsPKeyTable {fabric} {
   global PORT_PKEY_GROUP

   set pkey1 [getGroupPkey]
   set pkey2 [getGroupPkey]

   set G1 [list 0x7fff $pkey1]
   set G2 [list 0x7fff $pkey2]
   set G3 [list 0x7fff $pkey1 $pkey2]
   
   puts "-I- Group1 Pkeys:$G1"
   puts "-I- Group2 Pkeys:$G2"
   puts "-I- Group3 Pkeys:$G3"

   set hcaPorts [getAllActiveHCAPorts $fabric]

   foreach port $hcaPorts {
      set portNum [IBPort_num_get $port]
      # the H-1/P1 has a special treatment:
      set node [IBPort_p_node_get $port]
      if {[IBNode_name_get $node] == "H-1/U1"} {
         set group [list 0xffff $pkey1 $pkey2]
         set PORT_PKEY_GROUP($port) 3
      } else {
         # randomly select a group for this port:
         set r [expr int([rmRand] * 3) + 1]
         set PORT_PKEY_GROUP($port) $r
         switch $r {
            1 {set group $G1}
            2 {set group $G2}
            3 {set group $G3}
            default {
               puts "-E- How come we got $r ?"
            }
         }
      }

      set pkeys [getRandomPkeysWithGivenPkey 48 $group]
      set blocks [getPkeyBlocks $pkeys]
      
      set blockNum 0
      foreach block $blocks {
         # now set the PKey tables
         puts "-I- PKey set $node port:$portNum block:$blockNum to:$block"
         IBMSNode_setPKeyTblBlock sim$node $portNum $blockNum $block
         incr blockNum
      }
   } 
   # all HCA active ports
   return "Set PKeys on [array size PORT_PKEY_GROUP] ports"
}

# Validate the inventory generated from a particular node
# matches the partition. Return number of errors. 0 is OK.
proc validateOsmTestInventory {queryNode fileName} {
   global PORT_PKEY_GROUP
}

# Dump out the HCA ports and their groups:
proc dumpHcaPKeyGroupFile {simDir} {
   global PORT_PKEY_GROUP
   set fn [file join $simDir "port_pkey_groups.txt"]
   set f [open $fn w]

   foreach port [array names PORT_PKEY_GROUP] {
      set node [IBPort_p_node_get $port]
      set sys [IBNode_p_system_get $node]
      set num [IBPort_num_get $port]
      set name [IBSystem_name_get $sys]
      set guid [IBPort_guid_get $port]

      puts $f "$name $num $PORT_PKEY_GROUP($port) $guid"
   }
   close $f
   return "Dumpped Group info into:$fn"
}

set fabric [IBMgtSimulator getFabric]
