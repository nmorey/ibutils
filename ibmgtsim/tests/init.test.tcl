MsgMgr setLogFile "/tmp/sim.log"
MsgMgr setVerbLevel $MsgShowAll
IBMgtSimulator init /home/eitan/SW/cvsroot/IBADM/ibdm/Clusters/RhinoBased512.topo 46517 5
puts [IBMgtSimulator getFabric]
IBMSNode_setPhyPortErrProfile simnode:1:SL2-4/spine2/U2 1  {-drop-rate-avg 5 -drop-rate-var 7}
puts [IBMSNode_getPhyPortErrProfile simnode:1:SL2-4/spine2/U2 1]


puts [IBMSNode_getPhyPortPMCounter simnode:1:SL2-4/spine2/U2 1 1]
set mcm [madMcMemberRec]
madMcMemberRec_send_set $mcm simnode:1:SL2-2/spine1/U2 1 1 0

MsgMgr setLogFile "/tmp/sim.log"
MsgMgr setVerbLevel $MsgShowAll
IBMgtSimulator init /home/eitan/SW/cvsroot/IBADM/ibdm/Clusters/FullGnu.topo 46517 5
source /home/eitan/SW/SVN/osm/branches/main2_0/osm/test/osmMulticastRoutingTest.sim.tcl

sendJoinForPort port:1:H02/U1/2


proc activateNodePorts {node} {
   for {set pn 1} {$pn <= [IBNode_numPorts_get $node]} {incr pn} {
      set port [IBNode_getPort $node $pn]
      if {[IBPort_p_remotePort_get $port] != ""} {
         set pi [IBMSNode_getPortInfo sim$node $pn]
         ib_port_info_t_state_info1_set $pi 0x4
      }
   }
}

MsgMgr setLogFile "/tmp/sim.log"
MsgMgr setVerbLevel $MsgShowAll
IBMgtSimulator init /usr/share/ibmgtsim/Gnu16NodeOsmTest.topo 46517 1
set f [IBMgtSimulator getFabric]
set smNode [IBFabric_getNode $f H-1/U1]
set smPort [IBNode_getPort $smNode 1]
ibdmAssignLids $smPort
ibdmOsmRoute $f
foreach nodeNameNPtr [IBFabric_NodeByName_get $f] {
   activateNodePorts [lindex $nodeNameNPtr 1]
}

MsgMgr setLogFile "/tmp/sim.log"
MsgMgr setVerbLevel $MsgShowAll
IBMgtSimulator init test.topo 46517 1
set f [IBMgtSimulator getFabric]
set smNode [IBFabric_getNode $f H-1/U1]
set smPort [IBNode_getPort $smNode 1]
set n IBFabric_getNode $f H-2/U1]
set n  [IBFabric_getNode $f H-2/U1]
set p [IBNode_getPort $n 1]
IBNode_guid_set $n [IBNode_guid_get $smNode]
IBPort_guid_set $p [IBPort_guid_get $smPort]
