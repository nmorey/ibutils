puts "Running Simulation flow for SM LINK SETUP test case"

proc setPortSpeed {fabric nodeName portNum speed} {
	set node [IBFabric_getNode $fabric $nodeName]
	if {$node == ""} {
		puts "-E- fail to find node $nodeName"
		return "ERR: fail to find node $nodeName"
	}
	set port [IBNode_getPort $node $portNum]
	if {$port == ""} {
		puts "-E- fail to find node $nodeName port $portNum"
		return "ERR: fail to find node $nodeName port $portNum"
	}

	switch $speed {
		2.5 {set code 1}
		5   {set code 2}
		10  {set code 4}
		default {
			return "ERR: unknown speed:$speed"
		}
	}
	set pi [IBMSNode_getPortInfo sim$node $portNum]
	set old [ib_port_info_t_link_speed_get $pi]
	set new [format %x [expr ($code << 4) | ($old & 0xf)]]
	ib_port_info_t_link_width_active_set $pi $new
	return "Set node:$nodeName port:$portNum LinkSpeedActive to ${speed}Gpbs was $old now $new"
}

proc setPortWidth {fabric nodeName portNum width} {
	set node [IBFabric_getNode $fabric $nodeName]
	if {$node == ""} {
		puts "-E- fail to find node $nodeName"
		return "ERR: fail to find node $nodeName"
	}
	set port [IBNode_getPort $node $portNum]
	if {$port == ""} {
		puts "-E- fail to find node $nodeName port $portNum"
		return "ERR: fail to find node $nodeName port $portNum"
	}

	switch $width {
		1x {set code 1}
		4x {set code 2}
		8x {set code 4}
		12x {set code 8}
		default {
			return "ERR: unknown width:$width"
		}
	}
	set pi [IBMSNode_getPortInfo sim$node $portNum]
	set old [ib_port_info_t_link_width_active_get $pi]
	ib_port_info_t_link_width_active_set $pi $code
	return "Set node:$nodeName port:$portNum LinkWidthActive to $width was $old now $code"
}

proc setPortOpVLs {fabric nodeName portNum vls} {
	set node [IBFabric_getNode $fabric $nodeName]
	if {$node == ""} {
		puts "-E- fail to find node $nodeName"
		return "ERR: fail to find node $nodeName"
	}
	set port [IBNode_getPort $node $portNum]
	if {$port == ""} {
		puts "-E- fail to find node $nodeName port $portNum"
		return "ERR: fail to find node $nodeName port $portNum"
	}

	set pi [IBMSNode_getPortInfo sim$node $portNum]
	set old [ib_port_info_t_vl_enforce_get $pi]
	set new [format %x [expr ($vls << 4) | ($old & 0xf)]]
	ib_port_info_t_vl_enforce_set $pi $new
	return "Set node:$nodeName port:$portNum OpVLs to $vls opvls_enforcement was $old now $new"
}

proc setPortMTU {fabric nodeName portNum mtu} {
	set node [IBFabric_getNode $fabric $nodeName]
	if {$node == ""} {
		puts "-E- fail to find node $nodeName"
		return "ERR: fail to find node $nodeName"
	}
	set port [IBNode_getPort $node $portNum]
	if {$port == ""} {
		puts "-E- fail to find node $nodeName port $portNum"
		return "ERR: fail to find node $nodeName port $portNum"
	}

	switch $mtu {
		256 {set mtuCode 1}
		512 {set mtuCode 2}
		1024 {set mtuCode 3}
		2048 {set mtuCode 4}
		4096 {set mtuCode 5}
		default {
			return "ERR: unknown MTU:$mtu"
		}
	}

	set pi [IBMSNode_getPortInfo sim$node $portNum]
	set old [ib_port_info_t_mtu_smsl_get $pi]
	set new [format %x [expr ($mtuCode << 4) | ($old & 0xf)]]
	ib_port_info_t_mtu_smsl_set $pi $new
	return "Set node:$nodeName port:$portNum NeighborMTU to $mtu mtu_smsl was $old now $new"
}


set fabric [IBMgtSimulator getFabric]
