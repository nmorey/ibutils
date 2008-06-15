#!/bin/sh
# the next line restarts using tclsh \
   exec tclsh "$0" "$@"

package require ibis

# given a key and a list of ley/value pairs get the pair
proc assoc {key key_list} {
	foreach kv $key_list {
		if {[lindex $kv 0] == $key} {return [lrange $kv 1 end]}
	}
	return ""
}

# Find the first available port that is not DOWN and
# return its GUID
proc Ibis_GetFirstAvailablePortGuid {} {
	foreach GuidLidStat [ibis_get_local_ports_info] {
		set portState [lindex $GuidLidStat 2]
		if {$portState != "DOWN"} {
			return [lindex $GuidLidStat 0]
		}
	}
	return ""
}

# Use the first available port (active or init)
set port_guid [Ibis_GetFirstAvailablePortGuid]
if {$port_guid == ""} {
	puts "-E- Fail to find any available port"
	exit
}
puts "-I- Setting IBIS Port to $port_guid"
ibis_set_port $port_guid

package require ibsac

# get all nodes
set allNodes [sacNodeQuery getTable 0]

# get all ports
set allPorts [sacPortQuery getTable 0]

# get SM Info from the local port
set allSms [sacSmQuery getTable 0]

# get all Links:
set allLinks [sacLinkQuery getTable 0]

puts "Found: [llength $allNodes] nodes [llength $allPorts] ports [llength $allSms] SMs [llength $allLinks] Links"

foreach nr $allNodes {
	# Get the Node Info and the GUID
	set ni [sacNodeRec_node_info_get $nr]
	puts "Node Guid:[sacNodeInfo_node_guid_get $ni]"
	# garbadge collection
	sacNodeRec_delete $nr
}

# Print the FDB of the first switch found:
sacLFTQuery configure -lid 2
set lfts [sacLFTQuery getTable $IB_LFT_COMPMASK_LID]
foreach lft $lfts {
   puts $lft
}

after 50000

exit
