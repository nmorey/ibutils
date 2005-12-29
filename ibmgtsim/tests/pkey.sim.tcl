puts "Running Simulation flow for PKey test"

# Randomally assign PKey tables of 3 types:
# Group 1 : .. 0x81
# Group 2 : ........ 0x82 ...
# Group 3 : ... 0x82 ... 0x81 ...
# 
# So osmtest run from nodes of group1 should only see group1
# Group2 should only see group 2 and group 3 should see all.

# to prevent the case where randomized pkeys match (on ports 
# from different group we only randomize partial membership 
# pkeys (while the group pkeys are full)

# In order to prevent cases where partial Pkey matches Full Pkey
# we further split the space:
# Partials are: 0x1000 - 0x7fff
# Full are    : 0x8000 - 0x8fff
proc getPartialMemberPkey {} {
   return [format 0x%04x [expr int([rmRand] * 0x6fff) + 0x1000]]
}

proc getFullMemberPkey {} {
   return [format 0x%04x [expr int([rmRand] * 0xffe) + 0x8001]]
}

# produce a random PKey containing the given pkeys
proc getPartialMemberPkeysWithGivenPkey {numPkeys pkeys} {

   # randomally select indexes for the given pkeys:
   # fill in the result list of pkeys with random ones,
   # also select an index for each of the given pkeys and
   # replace the random pkey with the given one

   
   # flat pkey list (no blocks)
   set res {}
   
   # init both lists
   for {set i 0} {$i < $numPkeys - [llength $pkeys] } {incr i} {
      lappend res [getPartialMemberPkey]
   }

   # select where to insert the given pkeys
   for {set i 0} {$i < [llength $pkeys]} {incr i} {
      set pkeyIdx [expr int([rmRand] * [llength $numPkeys])]
      set res [linsert $res $pkeyIdx [lindex $pkeys $i]]
   }
      
   # making sure:
   for {set i 0} {$i < [llength $pkeys]} {incr i} {
      set pk [lindex $pkeys $i]
      set idx [lsearch $res $pk]
      if {$idx < 0 || $idx > $numPkeys} {
         puts "-E- fail to find $pk in $res"
         exit 1
      }
   }
   puts "-I- got random pkeys:$res"
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

   set pkey1 [getFullMemberPkey]
   set pkey2 [getFullMemberPkey]
   set pkey3 [getPartialMemberPkey]

   set G1 [list 0x7fff $pkey1 $pkey3]
   set G2 [list 0x7fff $pkey2 $pkey3]
   set G3 [list 0x7fff $pkey1 $pkey2 $pkey3]
   
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

      set pkeys [getPartialMemberPkeysWithGivenPkey 48 $group]
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


# Remove 0x7fff or 0xffff from the PKey table for all HCA ports - except the SM
proc removeDefaultPKeyFromTableForHcaPorts {fabric} {
   set hcaPorts [getAllActiveHCAPorts $fabric]
   foreach port $hcaPorts {
      set portNum [IBPort_num_get $port]
      # the H-1/P1 has a special treatment:
      set node [IBPort_p_node_get $port]
      if {[IBNode_name_get $node] == "H-1/U1"} {
         #Do nothing - do not remove the default PKey
      } else {
         set ni [IBMSNode_getNodeInfo sim$node]
         set partcap [ib_node_info_t_partition_cap_get $ni]
         for {set blockNum 0 } {$blockNum < $partcap/32} {incr blockNum} {
            set block [IBMSNode_getPKeyTblBlock sim$node $portNum $blockNum]
            puts "-I- PKey get $node port:$portNum block:$blockNum to:$block"
            #updating the block
            for {set i 0 } {$i < 32} {incr i} {
               if {[lindex $block $i] == 0x7fff || \
                      [lindex $block $i] == 0xffff} {
                  set block [lreplace $block $i $i 0]
                  puts "-I- Removing 0x7fff or 0xffff from the PKeyTableBlock"
               }
            }
            IBMSNode_setPKeyTblBlock sim$node $portNum $blockNum $block
            puts "-I- Default PKey set for $node port:$portNum block:$blockNum to:$block"
         }
      }
   }
   # all HCA active ports
   return "Remove Default PKey from HCA ports"
}


# Verify that 0x7fff or 0xffff is in the PKey table for all HCA ports
proc verifyDefaultPKeyForAllHcaPorts {fabric} {
   global PORT_PKEY_GROUP
   set hcaPorts [getAllActiveHCAPorts $fabric]   
   foreach port $hcaPorts {
      set portNum [IBPort_num_get $port]
      set node [IBPort_p_node_get $port]
      set ni [IBMSNode_getNodeInfo sim$node]
      set partcap [ib_node_info_t_partition_cap_get $ni]
      set hasDefaultPKey 0
      for {set blockNum 0 } {$blockNum < $partcap/32} {incr blockNum} {
         set block [IBMSNode_getPKeyTblBlock sim$node $portNum $blockNum]
         puts "-I- [IBPort_getName $port] block:$blockNum pkeys:$block"
         #Verifying Default PKey in the block
         for {set i 0 } {$i < 32} {incr i} {
            if {[lindex $block $i] == 0x7fff || \
                   [lindex $block $i] == 0xffff } {
               set hasDefaultPKey 1
               break
            }
         }
         if {$hasDefaultPKey == 1} {
            break
         }
      }
      if {$hasDefaultPKey == 0} {
         puts "-E- Default PKey not found for $node port:$portNum"
         return 1
      }        
   }
   # all HCA active ports
   return 0
}


# set the change bit on one of the switches:
proc setOneSwitchChangeBit {fabric} {
   set allNodes [IBFabric_NodeByName_get $fabric]
   foreach nameNNode $allNodes {
      set node [lindex $nameNNode 1]
      #if Switch
      if {[IBNode_type_get $node] == 1} {
         set swi [IBMSNode_getSwitchInfo sim$node]
         set lifeState [ib_switch_info_t_life_state_get $swi]
         set lifeState [expr ($lifeState & 0xf8) | 4 ]
         ib_switch_info_t_life_state_set $swi $lifeState
         puts "-I- Set change bit on switch:$node"
         return "-I- Set change bit on switch:$node"
      }
   }
   return "-E- Fail to set any change bit. Could not find a switch"
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
