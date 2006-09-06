##############################
### Initializ Databases
##############################
# InitalizeIBdiag
# InitalizeINFO_LST
# initOutputFile
# ParseOptionsList

##############################
### Initial and final actions
##############################
# Init_ibis
# Port_And_Idx_Settings
# Topology_And_SysName_Settings 
# startIBDebug
# finishIBDebug

##############################
### MADs handling
##############################
# SmMadGetByDr
# SmMadGetByLid
# PmListGet

##############################
### Farbic Discovery
##############################
# DiscoverFabric
# SetNeighbor                 
# DiscoverHiddenFabric        
# CheckDuplicateGuids         
# DumpBadLidsGuids
# DumpBadLinksLogic           
# DiscoverPath                
# RereadLongPaths
# PMCounterQuery             

##############################
### GENERAL PURPOSE PROCs
##############################
# WordInList
# RemoveElementFromList
# WordAfterFlag        
# bar                  
# ZeroesPad            
# ZeroesErase          
# Hex2Bin              
# LengthMaxWord        
# AddSpaces            
# ProcName        
# groupNumRanges
# groupingEngine
# compressNames

##############################
### Handling Duplicated Guids
##############################
# AdvncedMaskGuid
# GetCurrentMaskGuid
# BoolIsMaked                                   
# RetriveRealPort   

##############################
### Handling bad links
##############################
# PathIsBad
# DetectBadLinks
# ComparePMCounters
# BadLinksUserInform
# RemoveDirectPath

##############################
### SM handling
##############################
# CheckSM
# DumpSMReport
 
##############################
### handling topology file
##############################
# matchTopology
# reportTopologyMatching
# DrPath2Name
# linkNamesGet
# getArgvPortNames
# name2Lid
# reportFabQualities

##############################
### format fabric info
##############################
# GetDeviceFullType
# GetEntryPort
# GetParamValue
# FormatInfo

##############################
### ouput fabric info
##############################
# linkAtPathEnd
# lstInfo
# writeLstFile      
# writeNeighborFile
# writeMasksFile   
# writeSMFile      
# writeFdbsFile    
# writeMcfdbsFile  

##############################
### Debug
##############################
# listG
# debug

######################################################################
### Initializ Databases
######################################################################
#  NAME         InitalizeIBdiag
#  FUNCTION	set the inital enviorment values
#  OUTPUT	NULL
proc InitalizeIBdiag {} {
    global G argv argv0 InfoArgv INFO_LST MASK SECOND_PATH
    set G(version.num) 1.3.0rc10
    set G(tool) [file rootname [file tail $argv0]]
    source [file join [file dirname [info script]] ibdebug_if.tcl]
    set G(start.clock.seconds) [clock seconds]
    set G(detect.bad.links) 0
    set G(argv,debug) [expr [lsearch -exact $argv "--debug"] >= 0 ]
    fconfigure stdout -buffering none
    ### configuration of constants
    set G(config,badpath,maxnErrors)	3
    set G(config,badpath,retriesStart)	100
    set G(config,badpath,retriesEnd)	10000
    set G(config,badpath,retriesGrowth)	10
    # Maximum warnings/error reports for topology matching, before notifing 
    # the user that his cluster is messed up
    set G(config,warn.long.matchig.results)	20
    # The maximum value for integer-valued parameters
    set G(config,maximal.integer)	1000000
    set G(list,badpaths) ""
    set G(list,DirectPath) { "" }
    set G(list,NodeGuids) [list ]
    set G(list,PortGuids) [list ]
    set G(Counter,SW) 0
    set G(Counter,CA) 0
    set G(matchTopologyResult) 0
    set G(HiddenFabric) 0
    set MASK(CurrentMaskGuid) 1
    set SECOND_PATH ""
}

##############################
#  NAME         InitalizeINFO_LST
#  FUNCTION	Initalize the INFO_LST array, which defined the specific way 
#               to read and interpreted the result from MADS
#  INPUTS	NULL
#  OUTPUT	NULL
#  RESULT	the array INFO_LST is defined.
proc InitalizeINFO_LST {} {
    global INFO_LST
    array set INFO_LST { 
        Type	    { -source NodeInfo -flag node_type -width 8
    		        -substitution "1=CA 2=SW 3=Rt" -string 1 }
        Ports	    { -source NodeInfo -flag num_ports   -width 8 }
        SystemGUID  { -source NodeInfo -flag sys_guid   -width 64 }
        NodeGUID    { -source NodeInfo -flag node_guid   -width 64 }
        PortGUID    { -source NodeInfo -flag port_guid   -width 64 }
        DevID	    { -source NodeInfo -flag device_id   -width 16 }
        Rev	    { -source NodeInfo -flag revision    -width 32 }
        PN	    { -width 8 }
        PortNum	    { -source NodeInfo -flag port_num_vendor_id -width 8 -offset 0:32}
        VenID	    { -source NodeInfo -flag port_num_vendor_id -width 24 -offset 8:32}
        NodeDesc    { -source NodeDesc -flag description -width words -string 1 }
        LID	    { -source PortInfo -flag base_lid    -width 16 -fromport0 1 }
        PHY	    { -source PortInfo -flag link_width_active -width 8
    	                -substitution "1=1x 2=4x 4=8x 8=12x" -string 1 }
        LOG	    { -source PortInfo -flag state_info1 -width 4 -offset 4:8
    	                -substitution "1=DWN 2=INI 3=ARM 4=ACT" -string 1 }
        SPD	    { -source PortInfo -flag link_speed  -width 4 -offset 0:8
    	                -substitution "1=2.5 2=5 4=10" -string 1 }
    }
}

##############################
#  NAME         InitOutputFile
#  SYNOPSIS     InitOutputFile fileName
#  FUNCTION     open an output file for writing
#  INPUTS       file name
#  OUTPUT       file definition
proc InitOutputFile {_fileName} {
    global G 
    regsub {File$} [file extension [ProcName 1]] {} ext
    set ext [file extension $_fileName]
    if {![info exists G(outfiles,$ext)]} {
        inform "-E-outfile:not.valid" -file0 $outfile
    }
    set outfile $G(outfiles,[file extension $_fileName])
    if { [file exists $outfile] && ! [file writable $outfile] } {
	inform "-W-outfile:not.writable" -file0 $outfile -file1 $outfile.[pid]
	append G(outfiles,$ext) ".[pid]"
    }
    inform "-V-outfiles:$ext"
    return [open $G(outfiles,$ext) w]
}

##############################
#  NAME         ParseOptionsList
#  SYNOPSIS     ParseOptionsList list 
#  FUNCTION     defines the database (in uplevel) bearing the values of the options in a list
#  INPUTS       a list $list of options (= strings starting with "-") and their values
#  OUTPUT       NULL
#  RESULT       the array $cfg() is defined in the level calling the procedure.
#       	$cfg(option) is the value of the option
proc ParseOptionsList { list } { 
    catch { uplevel unset cfg }
    set cfgArrayList ""
    while { [llength $list] > 0 } {
	set flag  [lindex $list 0]
	set value [list [lindex $list 1]]
	set list  [lreplace $list 0 1]
	if {[regexp {^\-([^ ]+)$} $flag . flag ]} { 
	    lappend cfgArrayList "$flag" "$value"
	} else { 
	    return -code 1 -errorcode $flag
	}
    }
    uplevel array set cfg \"$cfgArrayList\"
    return
}


######################################################################
### Initial and final actions
######################################################################
#  NAME         Init_ibis
#  SYNOPSIS	Init_ibis
#  FUNCTION	Initalize ibis
#  INPUTS	NULL
#  OUTPUT	the result of the command "ibis_get_local_ports_info"
proc Init_ibis {} {
    catch { ibis_set_transaction_timeout 100 }
    #ibis_set_verbosity 0xffff
    if {[info exists env(IBMGTSIM_DIR)]} {
	ibis_opts configure -log_file [file join $env(IBMGTSIM_DIR) ibis.log]
    } else {
	if {[catch {set ID [open /tmp/ibis.log w]}]} {
            ibis_opts configure -log_file /tmp/ibis.log.[pid]
	}
	catch { close $ID }
    }
    if {[catch { ibis_init } ErrMsg]} { inform "-E-ibis:ibis_init.failed" -errMsg "$ErrMsg" }

    if {[catch { ibis_get_local_ports_info } ibisInfo ]} {
        if { $ibisInfo != "" } { inform "-E-ibis:ibis_get_local_ports_info.failed" -errMsg "$ibisInfo"}
    } else {
        inform "-V-ibis:ibis_get_local_ports_info" -value "$ibisInfo"
    }
    if { $ibisInfo == "" } {inform "-E-ibis:no.hca"}
    return $ibisInfo
}

##############################
#  NAME         Port_And_Idx_Settings
#  SYNOPSIS	Port_And_Idx_Settings ibisInfo 
#  FUNCTION	Sets the locat exit port and the local exit device
#               by parsing ibisInfo (the output of ibis_get_local_ports_info) 
#  INPUTS       The result from : ibis_get_local_ports_info"
#  OUTPUT	NULL
#  RESULT       set G(argv,port.num), G(RootPort,Guid) and G(RootPort,Lid).
proc Port_And_Idx_Settings {_ibisInfo} {
    global G PORT_HCA
    set ibisInfo $_ibisInfo
    set PortNum 0
    set devIndxNum 1
    set mode regular

    if {[llength [lindex $ibisInfo 0]] < 4} {
        set mode "oldIBIS"
        inform "-W-loading:old.ibis.version"
    } else {
        for {set portNumIdx 0} {$portNumIdx < [llength $ibisInfo]} {incr portNumIdx} {
            set entry [lindex $ibisInfo $portNumIdx]
            scan $entry {%s %s %s %s} PortGuid PortLid PortState portNum
            if {($portNum != 1) && ($portNum != 2)} {
                set mode "oldOSM"
                break;
            }
        }
    }
    # Ignore PN entries in _ibisInfo
    if {$mode == "oldOSM"} {
        inform "-W-loading:old.osm.version"
        for {set portNumIdx 0} {$portNumIdx < [llength $ibisInfo]} {incr portNumIdx} {
            set ibisInfo [lreplace $ibisInfo $portNumIdx $portNumIdx [lrange [lindex $ibisInfo $portNumIdx] 0 2]]
        }
    }
    # Ignore default port
    if {[llength $ibisInfo]>1} {
        if {[lsearch -start 1 $ibisInfo [lindex $ibisInfo 0]]!= -1} {
            set ibisInfo [lrange $ibisInfo 1 end]
        }
    }
    if {$mode != "regular"} {
        for {set portNumIdx 0} {$portNumIdx < [llength $ibisInfo]} {incr portNumIdx} {
            set entry [lindex $ibisInfo $portNumIdx]
            scan $entry {%s %s %s} PortGuid PortLid PortState
            set PORT_HCA($devIndxNum,[expr 1 + $portNumIdx]:PortGuid)  $PortGuid
            set PORT_HCA($devIndxNum,[expr 1 + $portNumIdx]:PortLid)   $PortLid
            set PORT_HCA($devIndxNum,[expr 1 + $portNumIdx]:PortState) $PortState
        }
    } else {
        set previousPortNum 0
        for {set portNumIdx 0} {$portNumIdx < [llength $ibisInfo]} {incr portNumIdx} {
            set entry [lindex $ibisInfo $portNumIdx]
            scan $entry {%s %s %s %s} PortGuid PortLid PortState portNum
            if {$previousPortNum >= $portNum} {
                incr devIndxNum
            }
            set previousPortNum $portNum
            set PORT_HCA($devIndxNum,$portNum:PortGuid)  $PortGuid
            set PORT_HCA($devIndxNum,$portNum:PortLid)   $PortLid
            set PORT_HCA($devIndxNum,$portNum:PortState) $PortState
        }
    }

    set portNumSet [info exists G(argv,port.num)]
    set devNumSet  [info exists G(argv,dev.idx)]

    if {$portNumSet && $devNumSet} {
        # Check if device exists
        if {$G(argv,dev.idx) > $devIndxNum} {
            inform "-E-localPort:dev.not.found" -value "$G(argv,dev.idx)" -maxDevices $devIndxNum
        }
        # Check if port exists in the device
        if {![info exists PORT_HCA($G(argv,dev.idx),$G(argv,port.num):PortGuid)]} {
            inform "-E-localPort:port.not.found.in.device" -flag "-p" -port $G(argv,port.num) -device $G(argv,dev.idx)
        }
        # Check the port state
        set portState $PORT_HCA($G(argv,dev.idx),$G(argv,port.num):PortState)
        if { $portState == "DOWN" } { 
            inform "-E-localPort:local.port.of.device.down" -port $G(argv,port.num) -device $G(argv,dev.idx)
        }
        if { ( $portState != "ACTIVE" ) && ( $G(tool) == "ibdiagpath" ) } {
            inform "-E-localPort:local.port.of.device.not.active" \
                 -port $G(argv,port.num) -state $portState -device $G(argv,dev.idx)
        }
    }

    if {!($portNumSet) && $devNumSet} {
        if {$G(argv,dev.idx) > $devIndxNum} {
            inform "-E-localPort:dev.not.found" -value "$G(argv,dev.idx)" -maxDevices $devIndxNum
        }
        set allDevPorts [lsort [array names PORT_HCA $G(argv,dev.idx),*:PortState]]
        set allPortsDown 1
        set upPorts 0
        foreach tmpEntry $allDevPorts {
            set portState $PORT_HCA($tmpEntry)
            if { $portState == "DOWN" } {continue} 
            if { ( $portState != "ACTIVE" ) && ( $G(tool) == "ibdiagpath" ) } {continue}
            incr upPorts
            if {$allPortsDown} {
                set saveEntry $tmpEntry
            }
            set allPortsDown 0
        }
        if {$allPortsDown} {
            inform "-E-localPort:all.ports.of.device.down" -device $G(argv,dev.idx)
        }
        set G(argv,port.num) [lindex [split $saveEntry ": ,"] 1]
        if {$upPorts > 1} {
            inform "-W-localPort:few.ports.up" -flag "-p" -value ""
        } else {
            inform "-I-localPort:one.port.up"
        }

    }

    if {$portNumSet && !($devNumSet)} {
        set debug 1
        set allDevPorts [lsort [array names PORT_HCA *,$G(argv,port.num):PortState]]
        if {[llength $allDevPorts] == 0} {
            inform "-E-localPort:port.not.found" -value $G(argv,port.num)
        }
        set allPortsDown 1
        set saveState "DOWN"
        set upDevices 0
        foreach tmpEntry $allDevPorts {
            set portState $PORT_HCA($tmpEntry)
            if { $portState == "DOWN" } {continue} 
            set saveState $portState
            if { ( $portState != "ACTIVE" ) && ( $G(tool) == "ibdiagpath" ) } {continue}
            if {$allPortsDown} {
                set saveState $portState
                set G(argv,dev.idx) [lindex [split $tmpEntry ": ,"] 0]
            }
            incr upDevices
            set allPortsDown 0
        }
        if {$allPortsDown} {
            if {$G(tool) == "ibdiagpath"} {
                inform "-E-localPort:local.port.not.active" \
                    -port $G(argv,port.num) -state $saveState    
            } else {
                inform "-E-localPort:local.port.down" -port $G(argv,port.num)   
            }
        }
        if {$upDevices > 1} {
            inform "-W-localPort:few.devices.up" 
        } elseif {$devIndxNum > 1} {
            inform "-I-localPort:using.dev.index" 
        }
    }

    if {!($portNumSet) && !($devNumSet)} {
        set allDevPorts [lsort [array names PORT_HCA *,*:PortState]]
        set allPortsDown 1
        set saveState "DOWN"
        set upPorts 0
        foreach tmpEntry $allDevPorts {
            set portState $PORT_HCA($tmpEntry)
            if { $portState == "DOWN" } {continue} 
            set saveState $portState
            if { ( $portState != "ACTIVE" ) && ( $G(tool) == "ibdiagpath" ) } {continue}
            if {$allPortsDown} {
                set G(argv,dev.idx)  [lindex [split $tmpEntry ": ,"] 0]
                set G(argv,port.num) [lindex [split $tmpEntry ": ,"] 1]
            }
            incr upPorts
            set allPortsDown 0
        }
        if {$allPortsDown} {
            if {$devIndxNum > 1} {
                set informMsg "-E-localPort:all.ports.down.mulitple.devices"
            } else {
                set informMsg "-E-localPort:all.ports.down"
            }
            if {$G(tool) == "ibdiagpath"} {
                inform $informMsg    
            } else {
                inform $informMsg
            }
        }
        if {$upPorts > 1} {
            inform "-W-localPort:few.ports.up" -flag "-p" -value ""
        } else {
            inform "-I-localPort:one.port.up"
        }
    }

    set G(RootPort,Guid) $PORT_HCA($G(argv,dev.idx),$G(argv,port.num):PortGuid)
    set G(RootPort,Lid)  $PORT_HCA($G(argv,dev.idx),$G(argv,port.num):PortLid)
    
    if {$G(RootPort,Guid) == "0x0000000000000000"} {
        inform "-E-localPort:port.guid.zero"
    }
    if {[catch {ibis_set_port $G(RootPort,Guid)} e]} {
        inform "-E-localPort:enable.ibis.set.port"
    }
    if {[info exists G(-p.set.by.-d)]} {
        inform "-I-localPort:is.dr.path.out.port"
    }
    return
}

##############################
#  NAME         Topology_And_SysName_Settings
#  SYNOPSIS	Topology_And_SysName_Settings 
#  FUNCTION	Sets and checks the topology file and local system name
#  INPUTS       NULL
#  OUTPUT	NULL
#  RESULT       set G(argv,sys.name)
proc Topology_And_SysName_Settings {} {
    global G 
    if { ! [info exists G(argv,topo.file)] } { return }

    if {[catch { set namesList $G(argv,sys.name) }]} {
	# Trying to guess the local system name: based on local NodeDesc
	set namesList [lindex [split [info hostname] .] 0]
	catch { append namesList " " [SmMadGetByDr NodeDesc -description {}] }
    }

    array set topoNodesArray [join [IBFabric_NodeByName_get $G(fabric,.topo)]]
    array set topoSysArray   [join [IBFabric_SystemByName_get $G(fabric,.topo)]]
    set sysNameSet [info exists G(argv,sys.name)]

    if {![info exists G(argv,sys.name)]} {set G(sys.name.guessed) 1}

    foreach item $namesList {
	if {[info exists topoNodesArray($item)]} {
	    set G(argv,sys.name) $item
	    if { ! $sysNameSet } { 
		inform "-W-localPort:node.intelligently.guessed" 
	    }
	    return
	} elseif {[info exists topoSysArray($item)]} {
	    set nodesNames [IBSystem_NodeByName_get $topoSysArray($item)]
	    set nodesNames [lsort -dictionary $nodesNames]
	    set G(argv,sys.name) \
		[lindex [lindex $nodesNames [expr $G(argv,dev.idx) -1]] 0]
	    if { ! $sysNameSet } { 
		inform "-W-localPort:node.intelligently.guessed" 
	    }
	    return
	}
    }

    ## If local system name was not idetified advertise only the HCA-Sys names
    set HCAnames ""
    foreach sysName [array names topoSysArray] {
	set sysPointer $topoSysArray($sysName)
	foreach item [IBSystem_NodeByName_get $sysPointer] {
	    if { [IBNode_type_get [lindex $item 1]] != 1 } {
		lappend HCAnames $sysName 
		break;
	    }
	}
    }

    # If the source node name was not found - exit with error
    if {[info exists G(argv,sys.name)]} {
	inform "-E-argv:bad.sys.name" \
	    -flag "-s" -value $G(argv,sys.name) -names [lsort $HCAnames]
    } else { 
	inform "-E-argv:unknown.sys.name" -names [lsort $HCAnames]
    }
    return
}

##############################
#  SYNOPSIS	startIBDebug
#  FUNCTION	
#	executes the following initial actions when starting to run any tool:
#	- parsing the command line (running proc parseArgv)
#	- initianlize ibis: 
#	    ibis_opts configure -log_file (if necessary)
#	    ibis_init, 
#	    ibis_get_local_ports_info
#	- parsing the result of ibis_get_local_ports_info:
#	   - If local hca-index was specified, check that such device exists
#	   - If local port-num was specified, check that this port is not DOWN
#	     (ACTIVE, in case of ibdiagpath)
#	   - If local port-num was not specified, set it to be the first not 
#	     DOWN (ACTIVE) port of the local device.
#	- if the above is OK, run ibis_set_port
#	- if a topology file is specified, check that the local system name is a
#	   valid system name, or - if the latter was not specified - try to
#	   guess it (if the host name or a word in the local node description
#	   are valid system names).
#  INPUTS	NULL
#  OUTPUT	NULL
#  DATAMODEL
#	the proc uses $env(IBMGTSIM_DIR) - if it exists, we are in simulation mode
#	the proc uses the following global variables:
#	   $G(argv,dev.idx) - the local-device-index
#	   $G(argv,port.num) - the local-port-num (this var may also be set here)
#	   $G(fabric,.topo) - the ibdm pointer to the fabric described in the topology file
#	   $G(-p.set.by.-d) - if set, then the port-num was not explicitly
#	     specified and it was set to be the output port of the direct route
#	the proc also sets the global vars G(RootPort,Guid) and G(RootPort,Lid)
#	- the node-guid and LID of the local port.	
proc startIBDebug {} {
    global G env tcl_patchLevel

    ### parsing command line arguments
    parseArgv
    
    ### Initialize ibis
    set ibisInfo [Init_ibis]

    ### Setting the local port and device index
    Port_And_Idx_Settings $ibisInfo

    ### Setting the local system name 
    Topology_And_SysName_Settings
    return
}

##############################
#  SYNOPSIS	finishIBDebug
#  FUNCTION	executes final actions for a tool:
#		- runs the proc listG
#		- displays the "-I-done" info ("Done" + run time)
#		- exits the program
#  INPUTS	NULL
#  OUTPUT	NULL
#  DATAMODEL	I use $G(start.clock.seconds) to tell the total run time
proc finishIBDebug {} { 
    global G
    listG
    inform "-I-done" $G(start.clock.seconds)
    catch { close $G(logFileID) }
    exit 0
}

######################################################################
### Sending queries (MADs and pmGetPortCounters) over the fabric
######################################################################

##############################
#  SYNOPSIS     SmMadGetByDr mad cget args
#  FUNCTION	
#	returns the info of the Direct Route Mad: sm${cmd}Mad getByDr $args.
#       It's recommanded to use this method to get MAS info- since it MAD 
#       sending handles failures
#  INPUTS	
#	$mad - the type of MAD to be sent - e.g., NodeInfo, PortInfo, etc.
#	$cget - the requested field of the mad ("dump" returns the all mad info)
#	$args - the direct route (and, optionally, the port) for sending the MAD
#  OUTPUT	
#	the relevant field (or - all fields) of the MAD info
#  DATAMODEL	
#	the proc uses $G(argv,failed.retry) - for stopping failed retries 
#	and $G(detect.bad.links) to decide whether to run DetectBadLinks
proc SmMadGetByDr { mad cget args } {
    global G errorInfo
    # Setting the send and cget commands
    set getCmd [concat "sm${mad}Mad getByDr $args"]
    if {[regexp {^-} $cget]} {
        set cgetCmd "sm${mad}Mad cget $cget"
    } else {
        set cgetCmd "sm${mad}Mad $cget"
    }
    
    # Sending the mads (with up to $G(argv,failed.retry) retries)
    inform "-V-mad:sent" -command "$getCmd"
    set status -1
    for { set retry 0 } { $retry < $G(argv,failed.retry) } { incr retry } { 
	if { [set status [eval $getCmd]] == 0 } { 
            incr retry
            break 
        }
    }
    inform "-V-mad:received" -status $status -attempts $retry
    # handling the results
    if { $G(detect.bad.links) && ( $status != 0 ) } {
        set res [DetectBadLinks $status "$cgetCmd" $mad $args]
        if {$res == -1} {
            return -code 1 -errorcode $status
        } else {
            return $res
        }
    } elseif { $status != 0 } {
        return -code 1 -errorcode $status
    } else {
        return [eval $cgetCmd]
    }
}

proc SmMadGetByDrNoDetectBadLinks { mad cget args } {
    global G errorInfo
    # Setting the send and cget commands
    set getCmd [concat "sm${mad}Mad getByDr $args"]
    if {[regexp {^-} $cget]} {
        set cgetCmd "sm${mad}Mad cget $cget"
    } else {
        set cgetCmd "sm${mad}Mad $cget"
    }
    
    set status -1
    for { set retry 0 } { $retry < $G(argv,failed.retry) } { incr retry } { 
	if { [set status [eval $getCmd]] == 0 } { 
            incr retry
            break 
        }
    }
    if { $status != 0 } {
        return -code 1 -errorcode $status
    } else {
        return [eval $cgetCmd]
    }
}

##############################

##############################
#  SYNOPSIS     SmMadGetByLid mad cget args
#  FUNCTION	
#	returns the info of the lid based Mad: sm${cmd}Mad getByLid $args.
#  INPUTS	
#	$mad - the type of MAD to be sent - e.g., NodeInfo, PortInfo, etc.
#	$cget - the requested field of the mad ("dump" returns the all mad info)
#	$args - the lid (and, optionally, the port) for sending the MAD
#  OUTPUT	
#	the relevant field (or - all fields) of the MAD info
#  DATAMODEL	
#	the proc uses $G(argv,failed.retry) - for stopping failed retries 
#	and $G(detect.bad.links) to decide whether to run DetectBadLinks
proc SmMadGetByLid { mad cget args } {
    global G errorInfo
    # Setting the send and cget commands
    set getCmd [concat "sm${mad}Mad getByLid $args"]
    if {[regexp {^-} $cget]} {
        set cgetCmd "sm${mad}Mad cget $cget"
    } else {
        set cgetCmd "sm${mad}Mad $cget"
    }

    inform "-V-mad:sent" -command "$getCmd"
    set status -1
    for { set retry 0 } { $retry < $G(argv,failed.retry) } { incr retry } { 
	if { [set status [eval $getCmd]] == 0 } { incr retry ; break }
    }
    inform "-V-mad:received" -status $status -attempts $retry
    # handling the results
    if { $status != 0 } {
        return -code 1 -errorcode $status
    } else {
        return [eval $cgetCmd]
    }
}
##############################

##############################
#  SYNOPSIS     PmListGet Lid:Port
#  FUNCTION	
#	returns the info of PM info request : pmGetPortCounters $Lid $Port
#  INPUTS	
#	$LidPort - the lid and port number for the pm info request
#		format: lid:port (the semicolon - historic)
#  OUTPUT	
#	the relevant PM (Performance Monitors) info for the $port at $lid
#  DATAMODEL	
#	the proc uses $G(argv,failed.retry) - for stopping failed retries 
proc PmListGet { LidPort } {
    global G

    # Setting Lid, Port and the pm command
    regexp {^(.*):(.*)$} $LidPort D Lid Port
    if { $Lid == 0 } { return }
    set cmd [concat "pmGetPortCounters $Lid $Port"]

    # Sending the pm info request
    inform "-V-mad:sent" -command $cmd
    set pm_list -1
    for { set retry 0 } { $retry < $G(argv,failed.retry) } { incr retry } { 
	if { [regexp "ERROR" [set pm_list [join [eval $cmd]]]]==0 } { 
	    break 
	}
    }
    inform "-V-mad:received" -attempts $retry

    # handling the results
    if {[regexp "ERROR" $pm_list]} {
	return -code 1 -errorcode 1 -errorinfo "$pm_list"
    } else { 
	return $pm_list
    }
}

######################################################################
### Farbic Discovery
######################################################################
#  SYNOPSIS 	DiscoverFabric 
#  FUNCTION & DATAMODEL
#	Using a BFS algorithm (staring at the local node), discovers the entire
#	fabric and sets up a few databases:
#       G(list,DirectPath):
#       G(list,NodeGuids):
#       G(list,PortGuids):
#       G(GuidByDrPath,<DirectPath>)    : <PortGuid> 
#       G(DrPathOfGuid,<PortGuid>)      : <DirectPath> 
#       G(PortInfo,<PortGuid>)          : <SmPortInfoMad>
#       G(NodeGuid,<PortGuid>)          : <NodeGuid>
#       G(NodeInfo,<NodeGuid>):         : <smNodeInfoMad>
#       G(NodeDesc,<NodeGuid>)          : 
#       G(PortGuid,<NodeGuid>:<PN>)     : <PortGuid>
#
#       Neighbor(<NodeGuid>:<PN>)       : <NodeGuid>:<PN>
#       
#       MASK(CurrentMaskGuid)           : <MaskGuid>
#       MASK(PortMask,<PortGuid>)       : <PortMask>
#       MASK(NodeMask,<NodeGuid>)       : <NodeMask>
#       MASK(PortGuid,<PortMask>)       : <PortGuid>
#       MASK(NodeGuid,<NodeMask>)       : <NodeGuid>
#
#       DUPandZERO(<PortGuid>,PortGUID) : <DirectPath>  
#       DUPandZERO(<NodeGuid>,NodeGUID) : <DirectPath>
#       DUPandZERO(<value>,<ID>)        : <DirectPath>
#
#       SM(<SMstate>                    : <DirectPath>,SMpriorty
#       
#       SECOND_PATH - list of second paths
#
#  INPUTS 
#       PathLimit  - defined in which bad paths type the discovery should 
#                   take place
#       startIndex - defined from which entry in G(list,DirectPath) the
#                   discovery should take place
#  OUTPUT NULL
proc DiscoverFabric { PathLimit {startIndex 0}} {
    global G DUPandZERO MASK Neighbor SM SECOND_PATH LINK_STATE
    inform "-V-discover:start.discovery.header"

    set index $startIndex 
    set possibleDuplicatePortGuid 0
    set badPathFound 0
    append LINK_STATE ""
    while { $index < [llength $G(list,DirectPath)] } {
        if {$badPathFound} {
            lappend SECOND_PATH $DirectPath
            RemoveDirectPath $DirectPath
            incr index -1
            set badPathFound 0
            if {[info exists G(GuidByDrPath,$DirectPath)]} {
                unset G(GuidByDrPath,$DirectPath)
            }
            continue
        }

        set DirectPath [lindex $G(list,DirectPath) $index]
        incr index

        inform "-V-discover:discovery.status" -index $index -path "$DirectPath"
        inform "-I-discover:discovery.status"
        # Reading NodeInfo across $DirectPath (continue if failed)
        if {[catch {set NodeInfo [SmMadGetByDr NodeInfo dump "$DirectPath"]}]} {
            set badPathFound 1
            continue
        }
        if {[PathIsBad $DirectPath] > $PathLimit} { 
            set badPathFound 1
            continue
        }

        set NodeGuid [WordAfterFlag $NodeInfo "-node_guid"]
        set PortGuid [WordAfterFlag $NodeInfo "-port_guid"]
        set EntryPort [GetEntryPort $DirectPath -byNodeInfo $NodeInfo]
        set boolNodeGuidknowen [expr ([lsearch $G(list,NodeGuids) $NodeGuid]!= -1)]
        set boolPortGuidknowen [expr ([lsearch $G(list,PortGuids) $PortGuid]!= -1)]
        
        set duplicatedGuidsFound ""
        if {$boolPortGuidknowen && !$boolNodeGuidknowen} {
            set preDrPath $G(DrPathOfGuid,$PortGuid)
            set duplicatedGuidsFound port
        }
        if {!$boolPortGuidknowen && $boolNodeGuidknowen} {
            set tmpPortGuid [lindex [array get G PortGuid,$NodeGuid:*] 1]
            set preDrPath $G(DrPathOfGuid,$tmpPortGuid)

            if {[catch {set type_1 [GetParamValue Type $preDrPath]}]} {
                set badPathFound 1
                continue
            }
            if {[catch {set type_2 [GetParamValue Type $DirectPath]}]} {
                set badPathFound 1
                continue
            }                                                                   
            if {$type_1 != $type_2} { set duplicatedGuidsFound node }

            if {$type_2 != "SW"} {
                if {[info exists Neighbor($NodeGuid:$EntryPort)]} {
                    set duplicatedGuidsFound node
                }
            } elseif {[CheckDuplicateGuids $NodeGuid $DirectPath 1]} {
                set duplicatedGuidsFound node
            }
        }
        if {$boolPortGuidknowen && $boolNodeGuidknowen } {
            # it's possible to get here with a second entry to a switch
            # and the previous entry determent that the switch PortGUID
            # is duplicated, so we need to check that it's not the source
            # or a knowen duplicated portGUID
            # TODO, also valid for NodeGUID

            # Dr for the current PG 
            set preDrPath $G(DrPathOfGuid,$PortGuid)
            # NG of current PG
            set preNodeGuid $G(NodeGuid,$PortGuid)
            # PG of current NG (use only one because HCa has max of 2 ports)
            # and for switch its the same
            set tmpPortGuid [lindex [array get G PortGuid,$NodeGuid:*] 1]
            # Dr for the current NG PG
            set preDrPath2 $G(DrPathOfGuid,$tmpPortGuid)
            
            if {[catch {set type_1 [GetParamValue Type $preDrPath]}]} {
                set badPathFound 1
                continue
            }
            if {[catch {set type_2 [GetParamValue Type $DirectPath]}]} {
                set badPathFound 1
                continue
            }

            if {[catch {set type_3 [GetParamValue Type $preDrPath2]}]} {
                set badPathFound 1
                continue
            }

            # Check if both were togther before
            if {$NodeGuid == $preNodeGuid } {
                #check if you reached the source / orignial
                # return 1 if not the same : current != original
                if {[CheckDuplicateGuids $NodeGuid $DirectPath 1]} {
                    set duplicatedGuidsFound "node port"
                } else {
                    # It's OK
                }
            } else {
                # Check if we reached an HCA
                if {$type_2 != "SW"} {
                    # We are in HCA, PG is uniqe per entry, it must be duplicated PG
                    lappend duplicatedGuidsFound "port"
                    if {$type_3 != "SW"} {
                        if {[info exists Neighbor($preNodeGuid:$EntryPort)]} {
                            lappend duplicatedGuidsFound "node"
                        } else {
                            # It's NG is o.k. - reentering HCA
                        }
                    }
                } else {
                    # now in switch if type1 || type2 are HCA they are duplicated
                    set duplicatedGuidsFound "node port"
                }
            }

            set DZ 0
            if {$DZ && [info exists MASK(PortMask,$PortGuid)] && ($duplicatedGuidsFound != "")} {
                foreach portMask $MASK(PortMask,$PortGuid) {
                    set preDrPath $G(DrPathOfGuid,$portMask)
                    set nodeGuid $G(NodeGuid,$portMask)

                    if {[catch {set type_1 [GetParamValue Type $preDrPath]}]} {
                        continue
                    }           

                    if {$type_1 != $type_2} { continue }
                    if {$type_1 != "SW"} {
                        if {[info exists Neighbor($NodeGuid:$EntryPort)]} {
                            continue
                        }
                    } elseif {[CheckDuplicateGuids $nodeGuid $DirectPath 1]} {
                        continue
                    }
                    set duplicatedGuidsFound ""
                    set PortGuid $portMask
                    # TODO CHECK IT OUT
                    set NodeGuid $nodeGuid
                    break;
                }
            }
        }
        
        if {[lsearch $duplicatedGuidsFound port]!= -1} {
            # Check if you encounter a knowen duplicate Guid or it's a new one
            # No - set a new mask GUID, 
            # Yes - set the current portGUID to the masked one, and break from here
            set portAllreadyMasked 0

            if {[info exists MASK(PortMask,$PortGuid)]} {
                foreach portMask $MASK(PortMask,$PortGuid) {
                    set preDrPath $G(DrPathOfGuid,$portMask)
                    set nodeGuid $G(NodeGuid,$portMask)
                    if {($nodeGuid != $NodeGuid) && (![BoolIsMaked $nodeGuid])} {
                        continue
                    }
                    if {[CheckDuplicateGuids $nodeGuid $DirectPath 1]} {
                        continue
                    }
                    set portAllreadyMasked 1
                    set PortGuid $portMask
                    set NodeGuid $nodeGuid
                    set duplicatedGuidsFound ""
                    break;
                }
            }
            if {!$portAllreadyMasked} {
                set preDrPath $G(DrPathOfGuid,$PortGuid)

                if {![info exists DUPandZERO($PortGuid,PortGUID)]} {
                    lappend DUPandZERO($PortGuid,PortGUID) $preDrPath
                }
                lappend DUPandZERO($PortGuid,PortGUID) $DirectPath

                set currentMaskGuid [GetCurrentMaskGuid]
                set MASK(PortGuid,$currentMaskGuid) $PortGuid
                lappend MASK(PortMask,$PortGuid) $currentMaskGuid
                set PortGuid $currentMaskGuid
                AdvncedMaskGuid
            }
        }
        if {[lsearch $duplicatedGuidsFound node]!= -1} {
            # Check if you encounter a knowen duplicate Guid or it's a new one
            # No - set a new mask GUID, 
            # Yes - set the current nodeGUID to the masked one, and break from here
            set nodeAllreadyMasked 0
            if {[info exists MASK(NodeMask,$NodeGuid)]} {
                foreach nodeMask $MASK(NodeMask,$NodeGuid) {
                    set tmpPortGuid [lindex [array get G PortGuid,$nodeMask:*] 1]
                    if {($tmpPortGuid != $PortGuid) && (![BoolIsMaked $tmpPortGuid])} {
                        continue
                    }
                    if {[CheckDuplicateGuids $nodeMask $DirectPath 1]} {
                        continue
                    }
                    set nodeAllreadyMasked 1
                    set NodeGuid $NodeMask
                    set PortGuid $tmpPortGuid
                    set duplicatedGuidsFound ""
                    break;
                }
            }
            if {!$nodeAllreadyMasked} {
                set tmpPortGuid [lindex [array get G PortGuid,$NodeGuid:*] 1]
                set preDrPath $G(DrPathOfGuid,$tmpPortGuid)

                if {![info exists DUPandZERO($NodeGuid,NodeGUID)]} {
                    lappend DUPandZERO($NodeGuid,NodeGUID) $preDrPath
                }
                lappend DUPandZERO($NodeGuid,NodeGUID) $DirectPath

                set currentMaskGuid [GetCurrentMaskGuid]
                set MASK(NodeGuid,$currentMaskGuid) $NodeGuid
                lappend MASK(NodeMask,$NodeGuid) $currentMaskGuid
                set NodeGuid $currentMaskGuid
                AdvncedMaskGuid
            }
        }

        set G(GuidByDrPath,$DirectPath) $PortGuid
        # check if the new link allready marked - if so removed $DirectPath
        # happens in switch systems and when a switch connects to himself
        if {![SetNeighbor $DirectPath $NodeGuid $EntryPort]} {
            set badPathFound 1
            continue
        }
        
        if {[catch {set NodeType [GetParamValue Type $DirectPath]}]} {
            set badPathFound 1
            continue
        }
        
        set boolNodeGuidknowen [expr ([lsearch $G(list,NodeGuids) $NodeGuid]!= -1)]
        # The next condition means - if we reached to allready visited Switch
        if {($boolNodeGuidknowen) && ($NodeType == "SW")} {
            continue
        }
        # The next line makes sure we only count the unknowen Nodes
        if {!(($boolNodeGuidknowen) && ($NodeType == "CA"))} {
            incr G(Counter,$NodeType)
        }

        set G(DrPathOfGuid,$PortGuid) $DirectPath
        if {!$boolNodeGuidknowen} {lappend G(list,NodeGuids)  $NodeGuid}
        if {!$boolPortGuidknowen} {lappend G(list,PortGuids)  $PortGuid}

        set G(NodeGuid,$PortGuid) $NodeGuid
        set G(NodeInfo,$NodeGuid) $NodeInfo
        set G(PortGuid,$NodeGuid:$EntryPort) $PortGuid

        # Update Neighbor entry In the Array it's possible it's allready 
        ## updated in the "return to switch check"
        if {[llength $DirectPath] > 0} {
            SetNeighbor $DirectPath $NodeGuid $EntryPort
        }
        if {[catch {set tmpNodeDesc [SmMadGetByDr NodeDesc -description "$DirectPath"]}]} {
            set G(NodeDesc,$NodeGuid) "UNKNOWN"
        } else {
            set G(NodeDesc,$NodeGuid) $tmpNodeDesc
        }
        # Build Port List
        if { $NodeType != "SW" } {
            set PortsList $EntryPort
        } else {
            if {[catch {set Ports [GetParamValue Ports $DirectPath]}]} {
                set badPathFound 1
                continue
            }
            set PortsList ""
            for { set port 0 } { $port <= $Ports } { incr port } {
                lappend PortsList $port
            }
        }

        set endLoop 0
        foreach ID "SystemGUID LID" {
            if {[catch {set value [GetParamValue $ID $DirectPath 0]}]} {
                set badPathFound 1
                set endLoop 1
                break
            } else {
                lappend DUPandZERO($value,$ID) "$DirectPath"
            }
        }
        if {$endLoop} {continue}

        # Check SM and update portInfo
        set endLoop 0
        foreach port $PortsList {
            if {[catch {set tmpPortInfo [SmMadGetByDr PortInfo dump "$DirectPath" $port]}]} {
                set endLoop 1
                set badPathFound 1
                continue
            }
            if { $NodeType == "CA" } {
                set tmpCapabilityMask [WordAfterFlag $tmpPortInfo -capability_mask]    
                if {[expr 2 & $tmpCapabilityMask]} {
                    if {[catch {set tmpLID [GetParamValue LID $DirectPath $port]}]} {
                        set badPathFound 1
                        set endLoop 1
                        continue
                    } 
                    if {![catch {set tmpSMInfo [SmMadGetByLid SMInfo dump $tmpLID ]}]} {
                        set tmpPriState [format 0x%x [WordAfterFlag $tmpSMInfo -pri_state]]
                        lappend SM([expr $tmpPriState % 0x10]) "{$DirectPath} [expr $tmpPriState / 0x10]"
                    }
                }
            }
            set G(PortInfo,$NodeGuid:$port) $tmpPortInfo
        
            # The loop for non-switch devices ends here.
            # This is also an optimization for switches ..
            if { ( ($index != 1) && ($port == $EntryPort) ) || ($port == 0) } {
                continue
            }

            # Check again that the local port is not down / ignore all other
            # down ports
            if {[catch {set tmpLog [GetParamValue LOG $DirectPath $port]}]} {
                set badPathFound 1
                set endLoop 1
                break
            }
            switch -- $tmpLog {
                "DWN" {
                    if { $index == 1 } { 
                        inform "-E-localPort:local.port.down" -port $port
                    }
                    continue
                }
                "INI" {
                    lappend LINK_STATE [join "$DirectPath $port"]
                }
            }
            # "$DirectPath $port" is added to the DirectPath list only if the
            # device is a switch (or the root HCA), the link at $port is not 
            # DOWN, $port is not 0 and not the entry port 
            lappend G(list,DirectPath) [join "$DirectPath $port"]
        }
        if {$endLoop} {continue}
    }
    if {$badPathFound} {
        lappend SECOND_PATH $DirectPath
        RemoveDirectPath $DirectPath
        if {[info exists G(GuidByDrPath,$DirectPath)]} {
            unset G(GuidByDrPath,$DirectPath)
        }
    }
    if {$G(HiddenFabric) == 0} {
        catch {set tmpHiddenFabric [DiscoverHiddenFabric]}
        inform "-I-discover:discovery.status"
        inform "-I-exit:\\r"
        inform "-V-discover:end.discovery.header"
    }
    if {[info exists tmpHiddenFabric] } {
        if {!$tmpHiddenFabric} {
            inform "-I-discover:discovery.status"
            inform "-I-exit:\\r"
            inform "-V-discover:end.discovery.header"    
        }
    }
    return

}
##############################

##############################
#  SYNOPSIS     SetNeighbor
#  FUNCTION	
#	setting the Neighbor info on the two end node 
#  INPUTS	
#	_directPath _nodeGuid _entryPort 
#  OUTPUT	
#       return 0/1 if Neighbor exists/not exists (resp.)
#  DATAMODEL	
#   Neighbor(<NodeGuid>:<PN>) 
proc SetNeighbor {_directPath _nodeGuid _entryPort} {
    global G Neighbor
    set previousDirectPath [lrange $_directPath 0 end-1]
    if {![llength $_directPath] } {
        return 1
    }
    if {![info exists G(GuidByDrPath,$previousDirectPath)]} {
        return 1
    }
    set tmpRemoteSidePortGuid $G(GuidByDrPath,$previousDirectPath)
    if {![info exists G(NodeGuid,$tmpRemoteSidePortGuid)]} {
        return 1
    }
    set tmpRemoteSideNodeGuid $G(NodeGuid,$tmpRemoteSidePortGuid)
    if {[info exists Neighbor($_nodeGuid:$_entryPort)]} {
        return 0
    }
    if {[info exists Neighbor($tmpRemoteSideNodeGuid:[lindex $_directPath end])]} {
        return 0
    }
    set Neighbor($_nodeGuid:$_entryPort) "$tmpRemoteSideNodeGuid:[lindex $_directPath end]"
    set Neighbor($tmpRemoteSideNodeGuid:[lindex $_directPath end]) "$_nodeGuid:$_entryPort"
    return 1
}
##############################

##############################
#  SYNOPSIS  DiscoverHiddenFabric   
#  FUNCTION  Call the second run of discovery, this time for all the bad links   
#  INPUTS    NULL	
#  OUTPUT    0 if the DiscoverFabric method wasn't called, 1 if it did
proc DiscoverHiddenFabric {} { 
    global G SECOND_PATH
    if {![info exists SECOND_PATH]} { return 0}

    set startIndex [llength $G(list,DirectPath)]
    foreach badPath $SECOND_PATH {
        lappend G(list,DirectPath) $badPath
    }
    set G(HiddenFabric) 1
    DiscoverFabric 1 $startIndex
    return 1
}
##############################

##############################
#  SYNOPSIS     CheckDuplicateGuids	
#  FUNCTION	Check if a given Node carries a Dupilcate GUID.
#               Using the Neighbor DB to compare the old neighbors to
#               the given Node neighbors
#  INPUTS	the node nodeGUID, and the directPath to the node from the
#               local system node
#               up to $_checks neighbors are being matched
#  OUTPUT	1 for duplicate 0 for not
proc CheckDuplicateGuids { _NodeGuid _DirectPath {_checks 1}} {
    global Neighbor
    set i 0
    set noResponseToMad 0
    # we can not DR out of HCA so we can return 1 anyway
    ## If Checking a HCA, one cannot enter and exit the HCA,
    ### So instead we will run the smNodeInfoMad on the partiel Dr.
    foreach name [array names Neighbor $_NodeGuid:*] {
        if {$i >= $_checks} { break }
        incr i
        if {[regexp {0x[0-9a-fA-F]+:([0-9]+)} $name all PN]} {
            lappend portList $PN

            #Found A port that once wasn't down and now it is DWN
            #if { [GetParamValue LOG $_DirectPath $PN] == "DWN"} { return 1 }

            #All knowen exits return error = it's not the same node
            # we use SmMadGetByDrNoDetectBadLinks, because we assume the direct path
            # exists (in order to compare its endNode with the knowen node endNode)
            # and the link is ACTIVE, its not have to be so no need fr setting that dr
            # as Bad link also.
            if {[catch {set NodeInfo [SmMadGetByDrNoDetectBadLinks NodeInfo dump "$_DirectPath $PN"]}]} {
                incr noResponseToMad
                continue
            }
            set NodeGuid [WordAfterFlag $NodeInfo "-node_guid"]
            set EntryPort [GetEntryPort "$_DirectPath $PN" -byNodeInfo $NodeInfo]
            if {$Neighbor($name) != "$NodeGuid:$EntryPort"} {
                return 1
            }
        }
    }
    # if all the checks ended up with no response - we assume it's
    # not the same node
    if {$i == $noResponseToMad} {
        return 1
    }
    return 0
}

##############################
#  SYNOPSIS     DumpBadLidsGuids    
#  FUNCTION	Dump the retrived info during discovery, regarding
#               Duplicate Guids and lids, and zero values
proc DumpBadLidsGuids { args } {
    global G DUPandZERO errorInfo
    set informHeader 0
    ### Checking for zero and duplicate IDs
    foreach entry [lsort [array names DUPandZERO]] {
        regexp {^([^:]*),([^:]*)$} $entry all value ID
        # llength will be diffrent then 1 when duplicate guids acored
        if { ( ( [llength $DUPandZERO($entry)]==1 ) || ( $ID=="SystemGUID" ) ) \
		 && ( $value != 0 ) } {
            continue
	}
        if {!$informHeader} {
            inform "-I-ibdiagnet:bad.guids.header"
            incr informHeader
        }
        set idx 0
	set paramList ""
        foreach DirectPath $DUPandZERO($entry) {
            append paramList " -DirectPath${idx} \{$DirectPath\}"
            incr idx
	}
        # use eval on the next line because $paramList is a list 
        if {[catch {eval inform "-E-discover:zero/duplicate.IDs.found" -ID $ID -value $value $paramList} e]} {
            continue;
        }
    }
    if {!$informHeader} {
        inform "-I-ibdiagnet:no.bad.guids.header"
    }
}
##############################
#  SYNOPSIS     DumpBadLinksLogic	
#  FUNCTION	Dump to information retrived during discovery regarding all the
#               the links which are in INI state
proc DumpBadLinksLogic {} {
    global LINK_STATE
    inform "-I-ibdiagnet:bad.link.logic.header"
    set firstINITlink 0
    if {[info exists LINK_STATE]} {
        foreach link $LINK_STATE {                                                        
            if {[PathIsBad $link] > 1} {continue}
            set paramlist "-DirectPath0 \{[lrange $link 0 end-1]\} -DirectPath1 \{$link\}"
            eval inform "-W-ibdiagnet:report.links.init.state" $paramlist
            set firstINITlink 1
        }
    }
    if {!$firstINITlink} {
        inform "-I-ibdiagnet:no.bad.link.logic"
    }
}

##############################
#  SYNOPSIS	
#	DiscoverPath Path2Start node
#  FUNCTION
#	Traverses a path between two fabric nodes, reading info regarding the 
#	nodes passed, and writing this data into various databases.
#	This proc is used whenever a tool should traverse some path: 
#	ibdiagpath, ibcfg, ibping,ibmad.
#	The path is defined by its two end points: the source node and the 
#	destination node. The path between the endpoints will be a direct route
#	- in case of by-direct-path-addressing - or lid-route in case of by-name
#	or by-lid addressing.
#  INPUTS 
#	$Path2Start is a direct route to the source node. In case of lid routing
#	it will be a part of the lid route to the destination node.
#	$node points to the destination is specified - either by a Direct route
#	(by-direct-path-addressing), or by LID (by-lid or by-name addressing).
#  OUTPUT
#	A direct route starting at the local node, passing through the source
#	node, ending at the destination node, 
#	that agrees with the addressing mode
#  DATAMODEL
#	Similarly to DiscoverFabric, the prod uses and updates these arrays 
#	G(NodeInfo,<NodeGuid>)
#	G(list,DirectPath)
#	Additionally, the following database is maintained:
#	G(DrPath2LID,<DirectPath>): 
#		the LID of the entry port at the end of <DirectPath>
#	Also used: G(argv,* ) (= the parsed command line arguments) is used to
#	specify the addressing mode; and the pointer to the merged fabric 
#	G(fabric,merged) (= the ibdm merging of topo file and .lst file)
proc DiscoverPath { Path2Start node } {
    debug "943" -header
    global G errorCode errorInfo
    if {[set byDrPath [info exists G(argv,direct.route)]]} { 
	set Path2End [join $node]
    } else { 
	set destinationLid $node
	set blockNum [expr $destinationLid / 64]
	set LidMod64 [expr $destinationLid % 64]
    }

    # When the source node is a remote HCA, if I don't do the following 
    # then my MADs will get stuck upon "entering-and-exiting" this node

    if { ($Path2Start != "") && [GetParamValue Type $Path2Start] != "SW" } {
	set Path2Start [lreplace $Path2Start end end]
    }
    set DirectPath $Path2Start
    while { 1 } {
        # Step #1: get the NodeGuid of $DirectPath
            if {[catch {set NodeInfo [SmMadGetByDr NodeInfo dump "$DirectPath"]}]} {
                break
            }
            if {[PathIsBad $DirectPath] > 1} { break }
            debug "981" DirectPath NodeInfo
            set NodeGuid  [WordAfterFlag $NodeInfo "-node_guid"]
            set PortGuid  [WordAfterFlag $NodeInfo "-port_guid"]
            set EntryPort [GetEntryPort $DirectPath -byNodeInfo $NodeInfo]
            set G(GuidByDrPath,$DirectPath) $PortGuid
            set G(DrPathOfGuid,$PortGuid)   $DirectPath
            set G(NodeGuid,$PortGuid)       $NodeGuid
            set G(NodeInfo,$NodeGuid)       $NodeInfo
            set G(NodeInfoByDr,$DirectPath) $NodeInfo

            set DirectPath [join $DirectPath]

            if {[llength $DirectPath] > 0} {
                SetNeighbor $DirectPath $NodeGuid $EntryPort
            }

            if {[catch {set tmpNodeDesc [SmMadGetByDr NodeDesc -description "$DirectPath"]}]} {
               set G(NodeDesc,$NodeGuid) "UNKNOWN"
            } else {
                set G(NodeDesc,$NodeGuid) $tmpNodeDesc
            }
            if { ! [WordInList $DirectPath $G(list,DirectPath)] } { 
	        lappend G(list,DirectPath) $DirectPath 
	    }

            set NodeType	[GetParamValue Type $DirectPath]
            set NodePorts	[GetParamValue Ports $DirectPath]

            set NodeLid	[GetParamValue LID $DirectPath -port $EntryPort]
            if { $NodeLid == "0x" } { break }
            if { $NodeType == "SW" } { 
	        set G(DrPath2LID,$DirectPath:0) $NodeLid 
            } else { 
	        set G(DrPath2LID,$DirectPath:$EntryPort) $NodeLid
            }
            if { $DirectPath != $Path2Start } {
                set remoteLidGuidDev [DrPath2Name $DirectPath -fullName -port $EntryPort]
                set portName1 [lindex [lindex [linkNamesGet $DirectPath] end] 1]
        	regsub {\(} $portName1 " (" portName1
                inform "-I-ibdiagpath:read.lft.to" "$remoteLidGuidDev $portName1"
            }
        ############################################################
        ### If we "discover" by means of direct route
        if {$byDrPath} {
        # This is the stopping condition for direct routing
	    if { $DirectPath == $Path2End } { break }
	    set exitPort [lindex $Path2End [llength $DirectPath]]

            # if the user gives a direct path passing through a HCA
	    if { ( $NodeType != "SW" ) && ( $DirectPath != $Path2Start ) } {
	        inform "-E-ibdiagpath:direct.route.deadend" \
	            -DirectPath "$DirectPath"
	    }

	    # if port number is wrong (it exceeds the node's number of ports)
            if { $exitPort > $NodePorts } { 
	        inform "-E-ibdiagpath:direct.path.no.such.port" \
		    -DirectPath "$DirectPath" -port $exitPort
	    }
        ############################################################
        } else { 
        ############################################################
            # If we discover by means of lid-route
            
            # This is the good stopping condition for lid routing
            if { $NodeLid == $destinationLid } { break } 
            # If we reached LID 0
            if { $NodeLid == 0 } { 
                inform "-E-ibdiagpath:reached.lid.0" -DirectPath "$DirectPath"
            } 
            
            # If we reached a HCA
            if { ( $NodeType != "SW" ) && ( $DirectPath != $Path2Start ) } {
                inform "-E-ibdiagpath:lid.route.deadend.reached.hca" \
                    -DirectPath [lrange $DirectPath 0 end-1] -lid $destinationLid -port [lindex $DirectPath 0]
            } 
            
            # If we returned to an already-visited node: we are in a lid-loop -> exit
            if { [info exists Guid2DrPath($NodeGuid)] } {
                inform "-E-ibdiagpath:lid.route.loop" \
                -DirectPath "$Guid2DrPath($NodeGuid)" -lid $destinationLid 
            } else { 
                set Guid2DrPath($NodeGuid) $DirectPath
            }
            
            if { $NodeType != "SW" } {
                set exitPort $EntryPort
            } else {
                if {[catch {set FDBsBlock [SmMadGetByDr LftBlock dump "$DirectPath" $blockNum]}]} {
                    if { $errorCode == 0x801c } {
                        inform "-E-ibdiagpath:fdb.block.unreachable" \
                        -errorcode $errorCode -command "$cmd"
                        }
                    break 
                }
                if {[PathIsBad $DirectPath] > 1} { break }
                set exitPort [expr [lindex $FDBsBlock $LidMod64]]
                if { ($exitPort == "0x00") } {
                    inform "-E-ibdiagpath:lid.route.deadend" \
                    -DirectPath [lrange $DirectPath 0 end] -lid $destinationLid -port [lindex $DirectPath 0]
                }
                
                if { ($exitPort == "0xff")} {
                    inform "-E-ibdiagpath:fdb.bad.value" \
                    -lid $destinationLid \
                    -command "smLftBlockMad getByDr \{$DirectPath\} $blockNum" \
                    -entry "\#$LidMod64" -value $exitPort
                }
            }
        }
        #if {![catch {set tmpPortInfo [SmMadGetByDr PortInfo dump "$DirectPath" $exitPort]}]} {
        #    set G(PortInfo,$NodeGuid:$exitPort) $tmpPortInfo
        #}
        # if exitPort is down
        if { [GetParamValue LOG $DirectPath $exitPort] == "DWN" } {
            inform "-E-ibdiagpath:link.down" \
                -DirectPath "$DirectPath" -port $exitPort
        }

        set DirectPath [join "$DirectPath $exitPort"]
        set portName0 [lindex [lindex [linkNamesGet $DirectPath] end] 0]
        regsub {\(} $portName0 " (" portName0
        # Note that lidGuidDev are corresponding to the "old" DirectPath
        # replace here the port number of the current device
        set tmpDr [lrange $DirectPath 0 end-1]
        set tmpPort $exitPort
        set localLidGuidDev  [DrPath2Name $tmpDr -fullName -port $tmpPort]
        inform "-I-ibdiagpath:read.lft.from" "$localLidGuidDev"
        ############################################################
    }
    if {[PathIsBad $DirectPath] > 1} { 
	BadLinksUserInform
        catch { close $G(logFileID) }
        inform "-E-ibdiagpath:route.failed" -DirectPath $tmpDr -port $tmpPort    
    }
    return [list $DirectPath]
}
##############################

##############################
#  SYNOPSIS     RereadLongPaths	
#  FUNCTION	Send $G(argv,count) MADs that don't wait for replies 
#               and then read all performance counters 
proc RereadLongPaths {} { 
    # send $G(argv,count) MADs that don't wait for replies 
    # and then read all performance counters

    ## Retrying discovery multiple times (according to the -c flag)
    global G 
    # The initial value of count is set to 4, since every link is traversed at least 3 times:
    # 1 NodeInfo, 1 PortInfo (once for every port), 1 NodeDesc
    set InitCnt 2
    if { $InitCnt > $G(argv,count) } { return }
    inform "-V-discover:long.paths"
    set oldSeconds [clock seconds]
    set countDr -1
    foreach DirectPath [lrange $G(list,DirectPath) 1 end] {
        incr countDr
        # start from the second path in $G(list,DirectPath), because the first is ""
	# For the retries we use only the longest paths
        if { [lsearch -regexp $G(list,DirectPath) "^$DirectPath \[0-9\]"] == -1 } { 
            for { set count $InitCnt } { $count <= $G(argv,count) } { incr count } {
                if {[PathIsBad $DirectPath]} { break }
                #puts -nonewline "\r[expr ($countDr*100) / [llength [lrange $G(list,DirectPath) 1 end]]]%"
                if {[catch { SmMadGetByDr NodeDesc dump "$DirectPath"}]} { break }
            }
	}
    }
    return
}
##############################

##############################
#  SYNOPSIS     PMCounterQuery
#  FUNCTION	Query all knowen ports, then Send $G(argv,count) MADs that don't wait for replies 
#               and then read all performance counters again
proc PMCounterQuery {} { 
    # send $G(argv,count) MADs that don't wait for replies 
    # and then read all performance counters
    ## Retrying discovery multiple times (according to the -c flag)
    global G LINK_STATE PM_DUMP
    inform "-V-discover:long.paths"
    inform "-I-ibdiagnet:pm.counter.report.header"
    set firstPMcounter 0
    # Inform that the local link is in init state
    if {[info exists LINK_STATE]} {
        if {[llength [lindex $LINK_STATE 0]] == 1 } {
            inform "-W-ibdiagnet:local.link.in.init.state"
            RereadLongPaths
            return 0
        }
    } else {
        set LINK_STATE "DZ"
    }
    foreach directPath [lrange $G(list,DirectPath) 0 end] {
	# start from the second path in $G(list,DirectPath), because the first is ""
        # Ignore those links which has state INIT
        set drIsInit 0
        if {[PathIsBad $directPath] > 1} { continue }
        for {set i 0} {$i < [llength $directPath]} {incr i} {
            if {[lsearch $LINK_STATE [lrange $directPath 0 $i]] != -1} {
                set drIsInit 1
                continue
            }
        }
        if {$drIsInit} {continue}
        
        set entryPort [GetEntryPort $directPath]
        if {[info exists tmpLidPort]} {
            unset tmpLidPort
        }
        # preparing database for reading PMs
        if {![catch {set tmpLID [GetParamValue LID $directPath $entryPort]}]} { 
            if { $tmpLID != 0 } { 
                if {[info exists G(argv,reset.port.counters)]} {
                    catch {pmClrAllCounters $tmpLID $entryPort}
                }
                set tmpLidPort "$tmpLID:$entryPort"
                set LidPort($tmpLidPort) $directPath
            }
        }
        # Initial reading of Performance Counters
        if {[info exists tmpLidPort]} {
            if {[catch { set oldValues($tmpLidPort) [join [PmListGet $tmpLidPort]] } e] } {
                inform "-E-ibdiagpath:pmGet.failed" [split $tmpLidPort :]
            }
        }
        set tmpLidPort "DZ"
        set entryPort [lindex $directPath end]
        set directPath [join [lreplace $directPath end end]]
        if {[llength $directPath] == 0} {
            set directPath ""
        }
        unset tmpLidPort
        if {![catch {set tmpLID [GetParamValue LID $directPath $entryPort]}]} { 
            if { $tmpLID != 0 } { 
                if {[info exists G(argv,reset.port.counters)]} {
                    catch {pmClrAllCounters $tmpLID $entryPort}
                }
                set tmpLidPort "$tmpLID:$entryPort"
                set LidPort($tmpLidPort) $directPath
            }
        }
        # Initial reading of Performance Counters
        if {[info exists tmpLidPort]} {
            if {[catch { set oldValues($tmpLidPort) [join [PmListGet $tmpLidPort]] } e] } {
                inform "-E-ibdiagpath:pmGet.failed" [split $tmpLidPort :]
            }
        }
    }
    RereadLongPaths
    foreach tmpLidPort [array names LidPort] {
        if {![info exists oldValues($tmpLidPort)]} {continue}

        set entryPort [lindex [split $tmpLidPort :] 1]
        set directPath $LidPort($tmpLidPort)
        set name [DrPath2Name $directPath -fullName -port $entryPort]

        # Final reading of Performance Counters
        if [catch { set newValues($tmpLidPort) [join [PmListGet $tmpLidPort]] }] {
            inform "-E-ibdiagpath:pmGet.failed" [split $tmpLidPort :]
        }
        set pmList ""
        if {![info exists newValues($tmpLidPort)]} {continue}
        for { set i 0 } { $i < [llength $newValues($tmpLidPort)] } { incr i 2 } {
            set oldValue [lindex $oldValues($tmpLidPort) [expr $i + 1]]
            set newValue [lindex $newValues($tmpLidPort) [expr $i + 1]]
            lappend pmList [expr $newValue - $oldValue]
        }
    
        inform "-V-ibdiagpath:pm.value" "$name $pmList"

        set badValues ""
        ## -pm option
        # set a list of all pm counters and reduced each one which is reported as an error 
        set pmCounterList "symbol_error_counter link_error_recovery_counter\
            link_down_counter port_rcv_errors port_xmit_discard port_xmit_constraint_errors\
            port_rcv_constraint_errors local_link_integrity_errors excesive_buffer_errors vl15_dropped" 

        foreach entry [ComparePMCounters $oldValues($tmpLidPort) $newValues($tmpLidPort)] {
            scan $entry {%s %s %s} parameter err value
            switch -exact -- $err {
                "valueChange" {
                    regsub -- "->" $value "-" exp
                    unset oldValue
                    unset newValue
                    scan [split $exp -] {%s %s} oldValue newValue
                    if {![info exists newValue]} {
                        set newValue $oldValue
                        set oldValue 0
                    }
                    set diffValue [expr $newValue - $oldValue]
                    lappend badValues "$parameter=0x[format %x $newValue] \(Increase by $diffValue during $G(tool) scan.\)"
                }
                "overflow" {
                    lappend badValues "$parameter=$value \(=overflow\)"
                }
                "exceeded"  {
                    set value 0x[format %x $value]
                    lappend badValues "$parameter=$value"
                }
            }
        }
        if { $badValues != "" } {
            set firstPMcounter 1
            inform "-W-ibdiagnet:bad.pm.counter.report" -deviceName $name -listOfErrors [join $badValues "%n"]
        }

        if {[info exists G(argv,port.counters)]} {
            lappend PM_DUMP(nodeNames) $name
            set PM_DUMP($name,pmCounterList) $pmCounterList
            set PM_DUMP($name,pmCounterValue) $newValues($tmpLidPort)
        }
    }
    if {$firstPMcounter == 0} {
        inform "-I-ibdiagnet:no.pm.counter.report"
    }
    if {[info exists G(argv,port.counters)]} {
        writePMFile
    }
    return 1
}

#####################################################################
### GENERAL PURPOSE PROCs
######################################################################
##############################
#  SYNOPSIS	WordInList word list 
#  FUNCTION	Indicates whether $word is a word in $list
#  INPUTS	a string $word and a list $list#
#  OUTPUT	1 or 0 - if $word is or isn't a word in $list (resp.)
proc WordInList { word list } {
    return [expr [lsearch -exact $list $word] >= 0 ] 
}
##############################

##############################
#  SYNOPSIS	RemoveElementFromList  
#  FUNCTION	remove an entry from a list
#  INPUTS	original list _word and the unrequierd entry _element
#  OUTPUT	the orignal list if if $_element isn't in $_list.
proc RemoveElementFromList {_list _element } {
    set tmpIndex [lsearch -exact $_list $_element]
    if {$tmpIndex == -1} { return $_list}
    return [lreplace $_list $tmpIndex $tmpIndex]
}
##############################


##############################
#  SYNOPSIS	WordAfterFlag list flag 
#  FUNCTION	Returns the entry in $list that is right after $flag (if exists)
#  INPUTS	a list $list and a string $flag
#  OUTPUT	a srting, which is the word in $list which is right after $flag 
#		- if exists - if not, the empty string is returned.
proc WordAfterFlag { list flag } {
    if {[set index [expr [lsearch -exac $list $flag] +1]]} { 
	return [lindex $list $index]
    }
    return
}
##############################

##############################
#  SYNOPSIS	bar char length 
#  FUNCTION	Return a string made of $length times $char
#  INPUTS	a string $char and an integer $length
#  OUTPUT	a srting, which is made of $length times duplicates of $char
proc bar { char length } {
    return [string repeat $char $length]
}
##############################

##############################
#  SYNOPSIS	ZeroesPad num length 
#  FUNCTION	adds zeroes to the LHS of $number for it to be of string length
#		$length
#  INPUTS	a number $num and an integer $length
#  OUTPUT	a srting, of length $length made of padding $num with zeroes on
#		the LHS.If the length of $num is greater than $length, 
#		the procedure will return $num.
proc ZeroesPad { num length } {
    return "[bar 0 [expr $length - [string length $num]]]$num"
}
##############################

##############################
#  SYNOPSIS	ZeroesErase num
#  FUNCTION	erase all zeroes at the LHS of $num. The number "0" returns "0"
#		(and not "")
#  INPUTS	an integer $length
#  OUTPUT	a number, that is made of erasing all zeroes at the LHS of $num.
#		If $num == 0, the procedure returns 0
proc ZeroesErase { num } {
    regsub {^0*(.+)$} $num {\1} num
    return $num
}
##############################

##############################
#  SYNOPSIS	Hex2Bin hex_list 
#  FUNCTION	turns a list of hexa munbers into a list of binary numbers
#  INPUTS	a list $list of hexadecimal numbers
#  OUTPUT	a list, which is made of the numbers of $list, represented in 
#		Binary base.
proc Hex2Bin { hex_list } {
    set bin_list ""
    array set hexbit2bin { 
	0 0000  1 0001  2 0010  3 0011
	4 0100  5 0101  6 0110  7 0111
	8 1000  9 1001  a 1010  b 1011
	c 1100  d 1101  e 1110  f 1111
    }
    foreach hex $hex_list {
	regsub {^0x} [string tolower $hex] {} hex
	set bin ""
	foreach hbit [split $hex ""] { 
	    append bin $hexbit2bin($hbit)
	}
	lappend bin_list $bin
    }
    return $bin_list
}
##############################

##############################
#  SYNOPSIS  LengthMaxWord _list  
#  FUNCTION  return the char length of the maximum word from the list   
#  INPUTS    a list of words   
#  OUTPUT    the length of te longest word   
proc LengthMaxWord {_list} {
    set maxLength 0
    foreach field $_list {
        if {[string length $field] > $maxLength } {
            set maxLength [string length $field]
        }
    }
    return $maxLength
}
##############################

##############################
#  SYNOPSIS AddSpaces _word  _desiredLength 
#  FUNCTION addind requierd amount of spaces    
#  INPUTS   the original word, and the amount of spaces to append to it    
#  OUTPUT   word + spaces    
proc AddSpaces {_word _desiredLength} {
    set wordLength [string length $_word]
    if {$wordLength >= $_desiredLength } {
        return $_word
    } else {
        return "$_word[string repeat " " [expr $_desiredLength - $wordLength]]"
    }
}
##############################

##############################
#  SYNOPSIS	ProcName args (<- args may be a positive integer)
#  FUNCTION	Return the name of the calling proc 
#  INPUTS	optinally - a positive integer
#  OUTPUT	the name of the calling proc 
#		(if $args != "" -> the name of the calling proc $args levels up)
proc ProcName { args } {
    set upLevels 0
    if { $args != "" } { set upLevels $args }
    return [lindex [info level [expr [info level] -1 -$upLevels]] 0]
}

proc removeLeadingZeros {num} {
  return [string trimleft $num 0] 
}

##############################
# get a list of numbers and generate a nice consolidated sub list
proc groupNumRanges {nums} {
   if {[llength $nums] <= 1} {
      return [lindex $nums 0]
   }

   set start -1
   set res ""
   if {[catch {set snums [lsort -dictionary $nums]}]} {
     set snums [lsort $nums]
   }
   set last [lrange $snums end end]
   set start [lindex $snums 0]
   set end $start
   foreach n $snums {
      if {([removeLeadingZeros $n] > [removeLeadingZeros $end] + 1)} {
         if {$start == $end} {
            append res "$end,"
         } else {
            append res "$start..$end,"
         }
         set start $n
         set end $n
      } else {
         set end $n
      }
   }
   if {$start == $end} {
      append res "$end,"
   } else {
      append res "$start..$end,"
   }
   return "\[[string range $res 0 end-1]\]"
}

# process every group by splitting it to pre num and post
# then look for matches and build next groups
proc groupingEngine {groups} {
   set res {}
   foreach group $groups {
      set idx [lindex $group 0]
      set word [lindex $group 1]

      # try to find a number on the right of the idx:
      set prefix [string range $word 0 [expr $idx -1]]
      set suffix [string range $word $idx end]
      if {![regexp {([^0-9]*)([0-9]+)(.*)} $suffix d1 w1 num w3]} {
         # no number - just keep this group
         lappend res $group
         continue
      }

      append prefix $w1
      set suffix $w3
      set key "$prefix $suffix"
      lappend NEW_GROUPS($key) $num
   }

   # go over all new groups and see if we can collapse them:
   foreach pNs [lsort [array names NEW_GROUPS]] {
      set ranges [groupNumRanges $NEW_GROUPS($pNs)]
      foreach range $ranges {
         set prefix [lindex $pNs 0]
         set suffix [lindex $pNs 1]
         set gIdx [expr [string length $prefix] + [string length $range]]
         lappend res "$gIdx $prefix$range$suffix"
      }
   }
   return $res
}

# Algorithm:
# split the given words on the first number
# then group on the leading string and sort for continoues
proc compressNames {words} {
    # we need to prepare the first stage which is a list of words and
    # simply the index 0 for were to start the search for integers
    foreach word $words {
       lappend groups [list 0 $word]
    }

    # now call the grouping engine
    set prevGroups 0
    while {$prevGroups != [llength $groups]} {
       set prevGroups [llength $groups]
       set groups [groupingEngine $groups]
    }

    set res ""
    foreach group $groups {
       lappend res [lindex $group 1] 
    }
    return [join $res]
}
##############################

######################################################################
### Handling Duplicated Guids
######################################################################
##############################
#  SYNOPSIS  AdvncedMaskGuid    
#  FUNCTION  advenced current mask guid by _increment(default set to 1)   
#  INPUTS    _increment(default set to 1)   
#  OUTPUT   0 when  _increment is not an integer, otherwise return 1    
proc AdvncedMaskGuid { {_increment 1}} {
    #ASSUME MASK GUID FORMAT IS HARD CODED 
    global MASK
    if {![string is integer $_increment]} {
        return 0
    }
    incr MASK(CurrentMaskGuid) $_increment
    return 1
}
##############################

##############################
#  SYNOPSIS GetCurrentMaskGuid    
#  FUNCTION return the current mask guid    
#  INPUTS   NULL    
#  OUTPUT   mask guid    
proc GetCurrentMaskGuid {} {
    global MASK
    set tmp $MASK(CurrentMaskGuid)
    set tmp [format %08x $tmp]
    set tmp "0xffffffff${tmp}"
    return $tmp
}
##############################


##############################
#  SYNOPSIS  BoolIsMaked { _currentMaskGuid}   
#  FUNCTION  checks if a guid is masked   
#  INPUTS    GUID   
#  OUTPUT    0 or 1
proc BoolIsMaked { _currentMaskGuid} {
    return [string equal 0xffffffff [string range $_currentMaskGuid 0 9]]
}
##############################

##############################
#  SYNOPSIS  RetriveRealPort { _currentMaskGuid}   
#  FUNCTION  return the masked guid   
#  INPUTS    mask guid   
#  OUTPUT    real guid   
proc RetriveRealPort { _currentMaskGuid} {
    global MASK
    set tmpGuid $_currentMaskGuid
    while {[BoolIsMaked $tmpGuid]} {
        if {![info exists MASK(PortGuid,$tmpGuid)]} {
            return -1
        }
        set tmpGuid $MASK(PortGuid,$tmpGuid)
    }
    return $tmpGuid
}

######################################################################
### Detecting bad links on a path on which a packet was lost
######################################################################

##############################
#  SYNOPSIS	
#	PathIsBad path
#  FUNCTION	
#	returns 1 if the direct path $path contains a link that was found to be
#	"bad"; it returns 0 otherwise.
#  INPUTS	
#	$path - a direct path: a list of integers separated by spaces - denoting
#	a direct route in the fabric (= a list of exit ports, starting at the 
#	fabric's source node).
#  OUTPUT	
#	0/1 - according to whether $path has a bad link or not
#  DATAMODEL	
#	the proc uses the database $G(bad,paths,<DirectPath>), which is set in
#	proc DetectBadLinks, and that denotes the reasons (errors) why the link
#	at the end of DirectPath was found to be bad.
proc PathIsBad { path } { 
    global G
    set boolOnlyBadPMs 1
    set boolPathIsBad  0
    for { set i 0 } { $i < [llength $path] } { incr i } { 
	if { [info exists G(bad,paths,[lrange $path 0 $i])] } {
            set boolPathIsBad 1
            # ignore PMcounter types error
            foreach arrayEntry $G(bad,paths,[lrange $path 0 $i]) {
                if {[lindex $arrayEntry 1] != "badPMs"} {
                    set boolOnlyBadPMs 0
                }
            }
            
        }
    }
    if {$boolPathIsBad} {
        if {$boolOnlyBadPMs} {
            return 1
        } else {
            return 2
        }
    }
    return 0
}
##############################

##############################
#  SYNOPSIS	
#	DetectBadLinks starting cgetCmd cmd args
#  FUNCTION	
#	Explores the direct route on which $cmd failed, and detects bad link(s)
#	along this path.
#	The exploration algorithm:... TODO: fill this in ...
#	The bad are then written to the database $G(bad,links,*).
#	This proc is called by the proc "SmMadGetByDr", when the global variable 
#	$G(detect.bad.links) is set.
#  INPUTS	
#	$status - the last exit status of $cmd
#	$cgetCmd - the command that returns the result of $cmd
#	$cmd - the name of the command that failed
#	$args - the arguments of $cmd
#  OUTPUT	
#	the result data of running $cmd $args - if available;
#	if the data in not available, returns with error code 1.
#  DATAMODEL	
#	$G(config,badpath,*) - a database used, which defines various
#	 parameters for the bad paths exploration: limits and growth rate for
#	 the retries of trying to run $cmd $args and error threshold to stop it.
#	$G(bad,paths,<DirectPath>) - a database used, that denotes the reasons
#	 (errors) why the link at the end of DirectPath was found to be bad.
#	$G(list,badpaths) - a database updated by the proc. It is the list of 
# 	 bad paths. I need this list, in addition to [array names G bad,paths,*],
#	 because it will be used in proc "DiscoverHiddenFabric".
#	$InfoPm(<PM>) - the width-in-bits of each PM and its error threshold

proc DetectBadLinks { status cgetCmd cmd args } { 
    global G env
    set args [join $args]
    set DirectPath [join [lindex $args 0]]
    set data -1
    if  {$status == 0}  { set data [eval $cgetCmd] }
    inform "-V-ibdiagnet:detect.bad.links" -path "$DirectPath"

    # preparing database for reading PMs
    set LidPortList ""
    for { set I 0 } { $I < [llength $DirectPath] } { incr I } {
        set ShortPath [lrange $DirectPath 0 $I]
        if {[PathIsBad $ShortPath]} { break }
	set path0 [lreplace $ShortPath end end]
	set port0 [lindex $ShortPath end]
        if {![catch {set LID0 [GetParamValue LID $path0 $port0 -noread]}]} { 
	    if { $LID0 != 0 } { lappend LidPortList "$LID0:$port0:$ShortPath" }
	}
	set path1 $ShortPath
	catch { unset port1 }
        catch { set port1 [GetParamValue PortNum $ShortPath -noread] }
        if {![catch {set LID1 [GetParamValue LID $path1 $port1 -noread]}]} { 
	    if { $LID1 != 0 } { lappend LidPortList "$LID1:$port1:$ShortPath" }
	}
    }

    # Reseting the Performance Counters
    foreach LidPortPath $LidPortList {
        set LidPort [join [lrange [split $LidPortPath :] 0 1] :]
        regexp {^(.*):(.*)$} $LidPort D Lid Port
    }

    # Initial reading of Performance Counters
    foreach LidPortPath $LidPortList {
	set LidPort [join [lrange [split $LidPortPath :] 0 1] :]
	catch { set oldValues($LidPort) [join [PmListGet $LidPort]] }
    }
    
    # setting retriesStart, retriesEnd, maxnErrors, retriesGrowth
    foreach entry [array names G config,badpath,*] {
	set name [lindex [split $entry ,] end]
	set $name $G($entry)
    }

    inform "-V-ibdiagnet:incremental.bad.links" -path "$DirectPath"

    set errors 0
    for	{ set maxnRetries $retriesStart } {( $maxnRetries <= $retriesEnd ) && ( $errors < $maxnErrors ) } { set maxnRetries [expr $maxnRetries * $retriesGrowth] } {
        for { set I 0 ; set errors 0 } { ($I < [llength $DirectPath]) && ($errors == 0) } { incr I } {
            set ShortPath [lrange $DirectPath 0 $I]
	    set getCmd [concat "smNodeInfoMad getByDr [list $ShortPath]"]
            if {[PathIsBad $ShortPath] > 1 } { break }
            for { set retry 0 } { ($retry < $maxnRetries) && ($errors < $maxnErrors) } { incr retry } {
                incr errors [expr [eval $getCmd] != 0]
	    }
            if { ($ShortPath==$DirectPath) && ($retry>$errors)} {
                set data [eval $cgetCmd]
            }
        }
    }
    # Final reading of Performance Counters
    foreach LidPortPath $LidPortList {
	regexp {^([^:]+):([^:]+):([^:]+)$} $LidPortPath . Lid Port Path
        if {[PathIsBad $ShortPath]} { break }
	if {[catch { set newValues [join [PmListGet $Lid:$Port]] }]} { continue }
	foreach entry [ComparePMCounters $oldValues($Lid:$Port) $newValues] {
	    if { ! [WordInList "$Path" $G(list,badpaths)] } {
                lappend G(list,badpaths) $Path
	    }
	    scan $entry {%s %s %s} parameter err value
	    switch -exact -- $err {
		"valueChange" {
                    set cmd [concat "pmGetPortCounters $Lid $Port"]
                    lappend G(bad,paths,$Path) \
			"-error badPMs -PMcounter $parameter -valueChange $value -command \{$cmd\}"
		}
		"overflow" {
                    lappend G(bad,paths,$Path) "-error badPMs -PMcounter $parameter value-overflow=$value"
		}
	    }
	}
    }
    # If errors count did not reach $maxnErrors, the path is considered to be OK
    if { $errors < $maxnErrors } { return $data }

    # If it did - the link at the end of ShortPath is "bad"
    if { [llength $ShortPath] <= 1 } {
        if { ( $retry == $errors ) } {
	    inform "-E-localPort:local.port.crashed" -command "$getCmd"
	} else {
	    inform "-E-localPort:local.port.failed" \
		-fails "$errors" -attempts $retry -command "$getCmd"
	}
    }
    if { ! [WordInList "$ShortPath" $G(list,badpaths)] } {
	lappend G(list,badpaths) $ShortPath
    }

    if { ( $retry == $errors ) } {
        lappend G(bad,paths,$ShortPath) "-error noInfo -command \{$getCmd\}"
	inform "-V-badPathRegister" -error noInfo -command "$getCmd"
        return -code 1 -errorinfo "Direct Path \"$ShortPath\" is bad = noInfo"
    } else {
        lappend G(bad,paths,$ShortPath) \
	    "-error madsLost -ratio $errors:$retry -command \{$getCmd\}"
    }
    
    return $data
}
######################################################################

##############################
proc ComparePMCounters { oldValues newValues args } {
    global G

    array set InfoPm { 
	port_select			{ -width 8  -thresh 0  }
	counter_select			{ -width 16 -thresh 0  }
	symbol_error_counter		{ -width 16 -thresh 1  }
	link_error_recovery_counter	{ -width 8  -thresh 1  }
	link_down_counter		{ -width 8  -thresh 1  }
	port_rcv_errors			{ -width 16 -thresh 1  }
	port_rcv_remote_physical_errors { -width 16 -thresh 0  }
	port_rcv_switch_relay_errors	{ -width 16 -thresh 0  }
	port_xmit_discard		{ -width 16 -thresh 10 }
	port_xmit_constraint_errors	{ -width 8  -thresh 10 }
	port_rcv_constraint_errors	{ -width 8  -thresh 10 }
	local_link_integrity_errors	{ -width 4  -thresh 10 }
	excesive_buffer_errors		{ -width 4  -thresh 10 }
	vl15_dropped			{ -width 16 -thresh 10 }
	port_xmit_data			{ -width 32 -thresh 0  }
	port_rcv_data			{ -width 32 -thresh 0  }
	port_xmit_pkts			{ -width 32 -thresh 0  }
	port_rcv_pkts			{ -width 32 -thresh 0  }
    }

    set errList ""
    set pmRequestList ""
    if {[info exists G(argv,query.performence.monitors)]} {
        set pmRequestList [split $G(argv,query.performence.monitors) {, =}]
    }
    foreach parameter [array names InfoPm] {
	ParseOptionsList $InfoPm($parameter)
	if { ! [info exists cfg(thresh)] } { continue }
	if { $cfg(thresh) == 0 } { continue }

	set oldValue	[WordAfterFlag $oldValues $parameter]
	set newValue	[WordAfterFlag $newValues $parameter]
        set delta	[expr $newValue - $oldValue]
	set overflow	0x[bar f [expr $cfg(width) / 4]]

	if { ( $delta >= $cfg(thresh) ) || ( $oldValue > $newValue ) } {
            lappend errList "$parameter valueChange $oldValue->$newValue"
	} elseif { ( $oldValue == $overflow ) || ( $newValue == $overflow ) } {
	    lappend errList "$parameter overflow $overflow"
	} elseif {[info exists G(argv,query.performence.monitors)]} {
            if {[lsearch $pmRequestList $parameter] != -1} {
                set pmTrash [WordAfterFlag $pmRequestList $parameter]
                if {$newValue >= $pmTrash} {
                    lappend errList "$parameter exceeded 0x[format %lx $newValue]"
                } 
            } elseif {[lsearch $pmRequestList "all"] != -1} {
                set pmTrash [WordAfterFlag $pmRequestList "all"]
                if {$newValue >= $pmTrash} {
                    lappend errList "$parameter exceeded 0x[format %lx $newValue]"
                }
            }
        }
    }
    return $errList
}
##############################

##############################
#  SYNOPSIS	
#	BadLinksUserInform
#  FUNCTION	
#	Pretty-printing of the bad links information
#  INPUTS	
#	NULL
#  OUTPUT	
#	Prints to the standard output the list of bad links, with proper
#	indentation, and - optionally - with infromation why this link was 
#       found to be bad.
#  DATAMODEL	
#	$G(bad,paths,<DirectPath>) - a database used, that denotes the reasons
#	 (errors) why the link at the end of DirectPath was found to be bad.
proc BadLinksUserInform { } { 
    global G

    if { ! [llength [array names G "bad,paths,*"]] } { 
	inform "-I-ibdiagnet:no.bad.paths.header"
	return 
    }
    inform "-I-ibdiagnet:bad.links.header"

    foreach entry [array names G "bad,paths,*"] {
	set DirectPath [lindex [split $entry ,] end]
        set linkNames "Link at the end of direct route \"[ArrangeDR $DirectPath]\""
        #set linkNames "Link at the end of direct route \{$DirectPath\}"
        if {[DrPath2Name $DirectPath] != ""} {
            append linkNames " \"[DrPath2Name $DirectPath]\"" 
        }
        array set BadPathsLinksArray "\{$linkNames\} \{$G($entry)\}"
    }
    ### pretty-printing of a list of links
    set LinksList [array names BadPathsLinksArray]
    foreach item $LinksList { 
	set link [lindex $item end]
        lappend llen [string length [lindex $link 0]] [string length [lindex $link 1]] 
    }
    set maxLen1 [lindex [lsort -integer $llen] end]

    set space(0)	"   "
    set space(1)	[bar " " [string length $space(0)]]
    array set prefix {
	"names:external" "Cable:"
	"names:internal" "Internal link:"
    }
    foreach kind [array names prefix] { 
	lappend prefix_llen [string length $prefix($kind)]
    }
    foreach kind [array names prefix] {
	set maxLen0	 [lindex [lsort -integer $prefix_llen] end]
	set rubberLen0	 [expr $maxLen0 - [string length $prefix($kind)]]
	set space($kind) "$space(0) $prefix($kind)[bar " " $rubberLen0]"
    }
    array set sym { 
	names:external,conn	"="
	names:external,cable	"-"
	names:internal,conn	"."
	names:internal,cable	"."
    }

    foreach item $LinksList { 
	set kind [lindex $item 0]
	set link [lsort -dictionary [lindex $item end]]
	if { [llength $link] == 1 } { lappend link "? (unknown port)" }
	if { ! [regexp {[^ ]} [lindex $link 0]] } { 
	    set link [list [lindex $link 1] "? (unknown port)"]
	}

        if { ! [info exists prefix($kind)] } {
	    lappend portsList "Z.$item"
	    set stdoutList(Z.$item) "$space(0) $item" 
	    set stdoutErrs(Z.$item) $BadPathsLinksArray($item)
	} else { 
	    regsub {^[^\(]*\((.*)\)$} [lindex $link 0] {\1} p0
	    lappend portsList $p0
	    set rubberLen1 [expr $maxLen1 - [string length [lindex $link 0]] + 3]
	    set cable "$sym($kind,conn)[bar $sym($kind,cable) $rubberLen1]$sym($kind,conn)"
	    set stdoutList($p0) "$space($kind) [lindex $link 0] $cable [lindex $link 1]"
	    set stdoutErrs($p0) $BadPathsLinksArray($item)
	}
    }

    set line ""
    foreach item [lsort -dictionary $portsList] {
	if { $line != [set line $stdoutList($item)] } {
	    inform "-I-ibdiagnet:bad.link" -link "$line"
	    inform "-I-ibdiagnet:bad.link.errors" \
		-errors " $space(1) Errors:\n $space(1)  [join $stdoutErrs($item) "\n $space(1)  "]"
	}
    }
    inform "-I-ibdiagnet:bad.links.err.types"
    return
}

##############################
#  SYNOPSIS     RemoveDirectPath	  
#  FUNCTION	Removes a direct path from $G(list,DirectPath)
#               - when we in a loop
#               - when we enter an allready knowen switch
#               - when we returned on an old link from the other end
proc RemoveDirectPath {_drPath } {
    global G
    set tmpList $G(list,DirectPath)
    set tmpList [RemoveElementFromList $G(list,DirectPath) $_drPath ]
    set G(list,DirectPath) $tmpList
}
##############################

######################################################################
### SM handling
######################################################################
proc CheckSM {} {
    global SM
    set master 3
    if {![info exists SM($master)]} {
        inform "-I-ibdiagnet:bad.sm.header" 
        inform "-E-ibdiagnet:no.SM"
    } else {
        if {[llength $SM($master)] != 1} {
            inform "-I-ibdiagnet:bad.sm.header" 
            inform "-E-ibdiagnet:many.SM.master" 
            foreach element $SM($master) {
                set tmpDirectPath [lindex $element 0]
                set nodeName [DrPath2Name $tmpDirectPath -port [GetEntryPort $tmpDirectPath]]
                if { $tmpDirectPath == "" } {
                    set nodeName "The Local Device : $nodeName"
                }
                inform "-I-ibdiagnet:SM.report.body" $nodeName [lindex $element 1]
            }
        }
    }
}

proc DumpSMReport { {_fileName stdout} }  {
    global SM
    set tmpStateList "not-active dicovering standby master"
    for {set i 3} {$i > -1} {incr i -1} {
        if {[info exists SM($i)]} {
            set SMList [lsort -index 1 -decreasing $SM($i)]
            set msg "\n  SM - [lindex $tmpStateList $i]"
            if {$_fileName == "stdout"} {
                inform "-I-ibdiagnet:SM.report.head" [lindex $tmpStateList $i]
            } else {
                puts $_fileName $msg
            }
            foreach element $SMList {
                set tmpDirectPath [lindex $element 0]
                set nodeName [DrPath2Name $tmpDirectPath -port [GetEntryPort $tmpDirectPath] -fullName]
                if { $tmpDirectPath == "" } {
                    set nodeName "The Local Device : $nodeName"
                }
                set msg "    $nodeName priorty:[lindex $element 1]"
                if {$_fileName == "stdout"} {
                    inform "-I-ibdiagnet:SM.report.body" $nodeName [lindex $element 1]
                } else {
                    puts $_fileName $msg
                }
            }
        }
    }
}
##############################

######################################################################
### If a topology file is given
######################################################################

proc matchTopology { lstFile args } {
    global G

    if {[info exists G(lst.failed)]} {
        inform "-F-crash:failed.build.lst"
        return 0
    }

    if { [info exists G(argv,report)] || [info exists G(argv,topo.file)] } {
	set G(fabric,.lst) [new_IBFabric]
	if {[IBFabric_parseSubnetLinks $G(fabric,.lst) $lstFile]} {
            inform "-F-crash:failed.parse.lst"
        }
    }
    if { ! [info exists G(argv,topo.file)] } { return 0}

    # Matching defined and discovered fabric
    if { [info exists G(LocalDeviceDuplicated)] } { 
        if {[info exists G(argv,topo.file)] && [info exists G(sys.name.guessed)]} {
            inform "-E-topology:localDevice.Duplicated" 
            return 0
        }
    }
    set MatchingResult \
        [ibdmMatchFabrics $G(fabric,.topo) $G(fabric,.lst) \
             $G(argv,sys.name) $G(argv,port.num) $G(RootPort,Guid) ]

        switch -- [lrange $MatchingResult 0 4] {
            "Fail to find anchor port" -
            "Even starting ports do not" {
                inform "-W-topology:Critical.mismatch" -massage [join $MatchingResult]
                return 0
            }
        }

    set G(MatchingResult) ""
    set old_line ""
    set G(missing.links) ""
    foreach line [split $MatchingResult \n] {

	if { [regexp {[^ ]} $line] || [regexp {[^ ]} $old_line] } { 
	    lappend G(MatchingResult) "  $line" 
	}
	# $G(missing.links) is the list of links found to be missing by topology
	# matching;
	# a pair of entries (0 & 1 , 2 & 3 etc.) are ports at the link's end
	set missingSysExp \
	    {^ *Missing System:([^ \(]+).*from port: *([^ ]+) to: *([^ ]+) *$}
	set missingLinkExp \
	    {^ *Missing internal Link connecting: *([^ ]+) to: *([^ ]+) *$}
	if { [regsub $missingSysExp "$old_line $line" {\1/\2 \3} link] || \
		 [regsub $missingLinkExp  "$line" {\1 \2} link] } {
	    set G(missing.links) [concat $G(missing.links) $link]
	}
        set old_line $line
    }

    set G(fabric,merged) [new_IBFabric]
    if [catch {ibdmBuildMergedFabric \
		   $G(fabric,.topo) $G(fabric,.lst) $G(fabric,merged)} ] {
        return 0
    }

    # need to copy the min lid
    IBFabric_minLid_set $G(fabric,merged) [IBFabric_minLid_get $G(fabric,.lst)]

    return 1
}
##############################

##############################
proc reportTopologyMatching { args } {
    global G
    if {$G(matchTopologyResult) == 0} { return }
    set noheader [WordInList "-noheader" $args] 
    if { ! $noheader } { inform "-I-topology:matching.header" }

    set MatchingResultLen [llength $G(MatchingResult)]
    if { $MatchingResultLen == 0 } {
	inform "-I-topology:matching.perfect"
    } else { 
	if { ! $noheader } { inform "-I-topology:matching.note" }
	if { $MatchingResultLen > $G(config,warn.long.matchig.results) } { 
	    inform "-W-topology:matching.bad"
	}
    }
    if {[string is space [lindex $G(MatchingResult) end]]} {
        set G(MatchingResult) [lrange $G(MatchingResult) 0 end-1]
    }
    putsIn80Chars [join $G(MatchingResult) \n]
}
##############################

proc ArrangeDR {_dr} {
    set res ""
    foreach drEntry $_dr {
        append res $drEntry,
    }
    return [string range $res 0 end-1]
}

##############################
# support LID , PortGUID , NodeGUID , EntryPort , Type , DevID ,Name
proc DrPath2Name { DirectPath args } {
    global G 
    set fullName [WordInList "-fullName" $args]
    set nameOnly [WordInList "-nameOnly" $args]
    if {[WordInList "-byDr" $args]} {
        set byDr "-byDr"
    } else {
        set byDr ""
    }

    if {[catch {set EntryPort [GetEntryPort $DirectPath]}]} {
        set EntryPort 0
    } else {
        if {$EntryPort == ""} {
            set EntryPort 0
        }
    }
    if {[set addPort [WordInList "-port" $args]]} { 
	set port [WordAfterFlag $args "-port"]
        set EntryPort $port
    }
    if { $fullName && [PathIsBad $DirectPath] < 2} { 
        set PortGUID	[GetParamValue PortGUID $DirectPath]
        set NodeDevID	[expr [GetParamValue DevID $DirectPath]]
        set NodePorts	[GetParamValue Ports $DirectPath]
        set NodeLid	[GetParamValue LID $DirectPath $EntryPort]
	set lidGuidDev	"lid=$NodeLid guid=$PortGUID dev=$NodeDevID"
    } else {
	set lidGuidDev	""
    }
    if { ($G(matchTopologyResult)==0) } {
        if {![catch {set deviceType [GetParamValue Type $DirectPath $byDr]}]} {
            if {$deviceType == "CA"} {
                if {![catch {set nodeDesc [lindex [GetParamValue NodeDesc $DirectPath $byDr] 0]}]} {
                    if {($nodeDesc == "") && ($addPort)} { return "PN=$port" }
                    set res "$nodeDesc"
                    if {($addPort)} { append res "/P$port" }
                    if {([llength $lidGuidDev] != 0) && !$nameOnly} {
                        append res " $lidGuidDev"
                    }
                    return $res
                }
            }
        }
        if {($addPort)} { 
            return "$lidGuidDev port=$port"
        } else {
            return "$lidGuidDev"
        }
    }
    set path $DirectPath
    set topoNodesList [join [IBFabric_NodeByName_get $G(fabric,.topo)]]
    if { [set nodePointer [WordAfterFlag $topoNodesList $G(argv,sys.name)]] == "" } {
        if {($addPort)} { 
            return "$lidGuidDev port=$port"
        } else {
            return "$lidGuidDev"
        }
    }
    while { [llength $path] > 0 } { 
        set port [lindex $path 0]
	set path [lrange $path 1 end]

        set nodePorts	[IBNode_Ports_get $nodePointer]
        set portPointer [IBNode_getPort $nodePointer $port]

        if {$portPointer != ""} {
            if {[catch {set remPortPointer [IBPort_p_remotePort_get $portPointer]} msg]} {
                return "$lidGuidDev port=$EntryPort"
	    } elseif { $remPortPointer == "" } { 
                return "$lidGuidDev port=$EntryPort"
    	    } elseif {[catch {set nodePointer [IBPort_p_node_get $remPortPointer]}]} { 
                return "$lidGuidDev port=$EntryPort"
	    } elseif { $nodePointer == "" } { 
                return "$lidGuidDev port=$EntryPort"
	    }
        }
    }
    if {[catch {set nodeName [IBNode_name_get $nodePointer]}]} { 
        return "$lidGuidDev port=$EntryPort"
    } elseif { $nodeName == "" } { 
        return "$lidGuidDev port=$EntryPort"
    } else {
        if {$addPort} {append nodeName "/P$EntryPort"} 
        if { $fullName } {  
	    return "\"$nodeName\" $lidGuidDev"
        } else { 
	    return "$nodeName"
        }
    }
}
##############################

##############################
proc linkNamesGet { DirectPath args } { 
    global G
    if {$G(matchTopologyResult)==0} { return;}

    set DirectPath	[join $DirectPath]
    if { [set Port0 [lindex $DirectPath end]] == "" } { 
	set Port0 $G(argv,port.num)
    }

    set PortGuid $G(GuidByDrPath,[lreplace $DirectPath end end])
    set NodeGuid $G(NodeGuid,$PortGuid)
    if { [set Pointer(node0) \
	      [IBFabric_getNodeByGuid $G(fabric,.topo) $NodeGuid]] == "" } {
	return ;
    }
    set node0Ports	[IBNode_Ports_get $Pointer(node0)]
    set Pointer(port0)	[lindex $node0Ports [lsearch -regexp $node0Ports "/$Port0$"]]
    catch { set Pointer(port1)	[IBPort_p_remotePort_get $Pointer(port0)] }

    set linkKind "external"
    foreach I { 0 1 } { 
	if { $Pointer(port${I}) == "" } { continue }

	set Name(port${I}) [IBPort_getName $Pointer(port${I})]
	set Pointer(sysport${I}) [IBPort_p_sysPort_get $Pointer(port${I})]
	if {[WordInList "-node" $args]} { 
	    set Pointer(node${I}) [IBPort_p_node_get $Pointer(port${I})]
	    set Name(node${I})  [IBNode_name_get   $Pointer(node${I})]
	    lappend link "$Name(node${I})"
	} elseif { $Pointer(sysport${I}) == "" } {
	    lappend link $Name(port${I})
	    set linkKind "internal"
	} else { 
	    set Pointer(node${I}) [IBPort_p_node_get $Pointer(port${I})]
	    set Num(port${I})	  [IBPort_num_get    $Pointer(port${I})]
	    set Name(node${I})	  [IBNode_name_get   $Pointer(node${I})]
	    lappend link "$Name(port${I})($Name(node${I})/P$Num(port${I}))"
	}
    }

    # processing the result
    switch -exact [llength $link] { 
	0 {;# just to be on the safe side: if both link ends are UNKNOWN
	    return
	}
	1 {;# look for the info of the other side of the link in the 
	    # "missing links" of topo matching
	    # lsearch ^ 1 = the index of the other-in-pair 
	    # (note: if lsearch = -1 then index = -2)
	    # TODO: should I not report these links, 
	    # as the topology matching already reported abo
	    set index [expr [lsearch -exact $G(missing.links) $link] ^ 1]
	    lappend link [lindex $G(missing.links) $index]
	}
    }
    return "names:$linkKind [list $link]"
}
##############################

##############################
# extract the name(s) of the port(s) from the -n flag
proc getArgvPortNames {} {
    global G argv
    if { ! [info exists G(argv,by-name.route)] } { return }
    set flag "-n"
    array set topoNodesArray [join [IBFabric_NodeByName_get $G(fabric,.topo)]]
    array set topoSysArray   [join [IBFabric_SystemByName_get $G(fabric,.topo)]]
    foreach nodeName [array names topoNodesArray] {
	foreach portPtr [join [IBNode_Ports_get $topoNodesArray($nodeName)]] {
	    set portName [IBPort_getName $portPtr] 
	    set portNum	 [IBPort_num_get $portPtr]
	    array set topoPortsArray	"$portName $portPtr"
	    array set topoPortsArray	"$nodeName/P${portNum} $portPtr"
	}
    }

    foreach name [split $G(argv,by-name.route) ,] {
        catch { unset portPointer portPointers }
        if {[catch { set portPointer $topoPortsArray($name) }]} {
            if { ! [catch { set nodePointer $topoNodesArray($name) }] } {
                if { [IBNode_type_get $nodePointer] == 1 } { ; # 1=SW 2=CA 3=Rt
                    set portPointer [lindex [IBNode_Ports_get $nodePointer] 0]
	        }
            } elseif { ! [catch { set sysPointer $topoSysArray($name) }] } { 
                if { [llength [set sys2node [IBSystem_NodeByName_get $sysPointer]]] == 1 } {
		    set nodePointer [lindex [join $sys2node] end]
	        }
	    } else {
                inform "-E-argv:bad.node.name" -flag $flag -value "$name" \
                    -names [lsort -dictionary [array names topoNodesArray]]
            }
        }
        if {[info exists portPointer]} {
            if { [IBPort_p_remotePort_get $portPointer] == "" } {
		inform "-E-argv:specified.port.not.connected" \
		    -flag $flag -value "$name"
	    }
	} else { 
            if {[info exists nodePointer]} {
		set W0 "node [IBNode_name_get $nodePointer]"
		foreach pointer [IBNode_Ports_get $nodePointer] { 
		    if { [IBPort_p_remotePort_get $pointer] != "" } { 
			lappend portPointers $pointer
		    }
		}
	    } else { 
                set W0 "system [IBSystem_name_get $sysPointer]"
                foreach sysPortNPtr [IBSystem_PortByName_get $sysPointer] { 
                    set sysPointer [lindex $sysPortNPtr 1]
		    set pointer [IBSysPort_p_nodePort_get $sysPointer]
                    if { [IBPort_p_remotePort_get $pointer] != "" } { 
			lappend portPointers $pointer
		    }
		}
	    }
            if { ! [info exists portPointers] } { 
		inform "-E-argv:hca.no.port.is.connected" -flag $flag -type [lindex $W0 0] -value $name
	    } elseif { [llength $portPointers] > 1 } { 
		inform "-W-argv:hca.many.ports.connected" -flag $flag -type [lindex $W0 0] -value $name \
		    -port [IBPort_num_get [lindex $portPointers 0]]
	    } 
            set portPointer [lindex $portPointers 0]
	}
        lappend portNames $portPointer
    }
    return $portNames
}
##############################

##############################
proc name2Lid {localPortPtr destPortPtr exitPort} {
    set Dr $exitPort
    set listPorts $localPortPtr
    set index 0
    set Nodes($exitPort) $localPortPtr
    set destNodePtr [IBPort_p_node_get $destPortPtr]
    while { $index < [llength $Dr] } {
        set DirectPath      [lindex $Dr $index]
        set localPortPtr    $Nodes($DirectPath)
        incr index
        set localNodePtr    [IBPort_p_node_get  $localPortPtr] 
        set localNodetype   [IBNode_type_get    $localNodePtr]
        set destNodePtr     [IBPort_p_node_get  $destPortPtr] 

        if {$destPortPtr == $localPortPtr} {
            if {$localNodetype == 1} {
                return "$DirectPath 0"
            } else {
                return $DirectPath
            }
        }
        if {($localNodetype != 1) } {continue}
        if {(($localNodetype == 1) && ($localNodePtr == $destNodePtr))|| ($index == 1) } {
        # in the current switch check if it's any of the switch ports
            for {set i 1} {$i <= [IBNode_numPorts_get $localNodePtr]} {incr i} {
                set tmpPort [IBNode_getPort $localNodePtr $i]    

                if {$tmpPort == $destPortPtr} {
                    return "$DirectPath 0"
                }
            }
        }

        # build a list of new ports
        for {set i 1} {$i <= [IBNode_numPorts_get $localNodePtr]} {incr i} {
            set tmpPort [IBNode_getPort $localNodePtr $i] 
            if {$tmpPort == ""} { continue }
            if { [catch {set tmpRemotePtr [IBPort_p_remotePort_get $tmpPort]} e] } {
                continue
            }
            if {($tmpRemotePtr != "")} {
                if {[lsearch $listPorts $tmpRemotePtr] != -1} {continue}
                lappend listPorts $tmpRemotePtr
                lappend Dr "$DirectPath $i"
                set newDr "$DirectPath $i"
                set Nodes($newDr) $tmpRemotePtr
            }
        }
    }
    return -1
}
##############################

##############################
proc reportFabQualities {} { 
    global G SM
    if {[info exists G(lst.failed)]} {return }
    if { ! [info exists G(argv,report)] } { return }
    set nodesNum [llength [array names G "NodeInfo,*"]]
    set swNum [llength [array names G "PortInfo,*:0"]]
    if { [set hcaNum [expr $nodesNum - $swNum]] == 1 } { 
	inform "-W-report:one.hca.in.fabric"
	return
    }
    if {$G(matchTopologyResult)==1} { 
	set fabric $G(fabric,merged)
    } else { 
	set fabric $G(fabric,.lst)
    }

    # SM report
    set totalSM [llength [array names SM]]
    if {$totalSM != 0} {
        inform "-I-ibdiagnet:SM.header"
        DumpSMReport
    }

    inform "-I-ibdiagnet:report.fab.qualities.header"

    # general reports
    if {[IBFabric_parseFdbFile $fabric $G(outfiles,.fdbs)]} {
        inform "-F-crash:failed.parse.fdbs"
    }

    if {[IBFabric_parseMCFdbFile $fabric $G(outfiles,.mcfdbs)]} {
        inform "-F-crash:failed.parse.mcfdbs"
    }

    if {![file exists $G(outfiles,.lst)]} {
        inform "-E-ibdiagnet:no.lst.file" -fileName $G(outfiles,.lst)
        return 0
    }

    # verifying CA to CA routes
    set report [ibdmVerifyCAtoCARoutes $fabric]
    append report [ibdmCheckMulticastGroups $fabric]

    inform "-I-ibdiagnet:check.credit.loops.header"

    # report credit loops 
    ibdmCalcMinHopTables $fabric
    set roots [ibdmFindRootNodesByMinHop $fabric]
    if {[llength $roots]} {
        inform "-I-reporting:found.roots" $roots
        ibdmReportNonUpDownCa2CaPaths $fabric $roots
    } else {
        ibdmAnalyzeLoops $fabric
    }

    # Multicast mlid-guid-hcas report
    set mcPtrList [sacMCMQuery getTable 0]
 
    if { [llength $mcPtrList] > 0 } {
        inform "-I-ibdiagnet:mgid.mlid.hca.header"
        putsIn80Chars "mgid [bar " " 32] | mlid   | HCAs\n[bar - 80]"
	foreach mcPtr $mcPtrList {
            if {[catch {sacMCMRec OBJECT -this $mcPtr} msg]} {
                puts $msg
	    } else {
                catch {OBJECT cget} attributes
                foreach attr [lindex $attributes 0] {
                    if {($attr == "-this") || ($attr == "-mgid") || ($attr == "-port_gid")} {
                        #set [string range $attr 1 end] 0x00
                        #continue
                    }
                    set [string range $attr 1 end] [OBJECT cget $attr]
		}
                rename OBJECT ""
	    }
            set mlidHex 0x[format %lx $mlid]
            if {[info exists G(mclid2DrPath,$mlidHex)]} {
                set mlidHcas $G(mclid2DrPath,$mlidHex)
            } else {
                set mlidHcas NONE
            }
            putsIn80Chars "$mgid | 0x[format %lx $mlid] | [compressNames $mlidHcas]"
        }
    }
    return
}
######################################################################

######################################################################
### format fabric info
######################################################################
# The pocedure GetParamValue needs the database $G(list,DirectPath) 
# returns the value of a parameter of a port in .lst file format

##############################
proc GetDeviceFullType {_name} {
    array set deviceNames { SW "Switch" CA "HCA" Rt "Router" }
    if {[lsearch [array names deviceNames] $_name] == -1} {
        return $_name
    } else {
        return $deviceNames($_name)
    }
}
##############################

##############################
proc GetEntryPort { _directPath args} {
    global G INFO_LST Neighbor
    if {$_directPath == ""} {
        if {[lsearch -exac $args "-byNodeInfo"]!=-1} {
            set nodeInfo [WordAfterFlag $args "-byNodeInfo"]
        } else {
            set nodeInfo [SmMadGetByDr NodeInfo dump ""]    
        }
        set _port_num_vendor_id [WordAfterFlag $nodeInfo "-port_num_vendor_id"]
        return [format %d [FormatInfo $_port_num_vendor_id PortNum NONE]]
    }

    if {[info exists G(GuidByDrPath,$_directPath)]} {
        set tmpGuid $G(GuidByDrPath,[lrange $_directPath 0 end-1])
        set tmpGuid $G(NodeGuid,$tmpGuid)
        if {[info exists Neighbor($tmpGuid:[lindex $_directPath end])]} {
            set entryPort $Neighbor($tmpGuid:[lindex $_directPath end])
            return [lindex [split $entryPort :] end ]
        }
    }

    if {[lsearch -exac $args "-byNodeInfo"]!=-1} {
        set nodeInfo [WordAfterFlag $args "-byNodeInfo"]
        set _port_num_vendor_id [WordAfterFlag $nodeInfo "-port_num_vendor_id"]
        return [format %d [FormatInfo $_port_num_vendor_id PortNum NONE]]
    } elseif {$_directPath == ""} {
        return -code 1 -errorinfo "Can't retrive entry port"
    }

    if {[catch {set tmpGuid [GetParamValue NodeGUID [lrange $_directPath 0 end-1] -byDr]}]} {
        return ""
    } else {
        if {[info exists Neighbor($tmpGuid:[lindex $_directPath end])]} {
            set entryPort $Neighbor($tmpGuid:[lindex $_directPath end])
            return [lindex [split $entryPort :] end ]
        } else {
            return ""
        }
    }
}
##############################

##############################
proc GetParamValue { parameter DirectPath args } {
    global G INFO_LST SECOND_PATH
        set DirectPath "[join $DirectPath]"
        # noread - if info doesn't exists don't try to get it by dr
        set byDr 0       
        set noread 0
        if {[lsearch -exac $args "-byDr"] != -1} { set byDr 1 }
        if {[lsearch -exac $args "-noread"] != -1} { set noread 1}
        if {[WordInList $parameter "PortGuid"]} { set byDr 1 }
        if { ! [WordInList $DirectPath $G(list,DirectPath)] && (![WordInList $DirectPath $SECOND_PATH]) && (!$byDr)} {
            return -code 1 -errorinfo "Direct Path \"$DirectPath\" not in $G(list,DirectPath)\n and not in $SECOND_PATH"
        }
        ## Setting the parameter flags
        ParseOptionsList $INFO_LST($parameter) 

        ## Setting the port number
        set port [lindex $args 0]
        if {[info exists cfg(fromport0)]} { 
            if {$byDr} {
                if { [catch {set tmpType [GetParamValue Type $DirectPath -byDr] }]} {
                    return -code 1 -errorinfo "6.Direct Path \"$DirectPath\" is bad"
                }
            } else {
                if { [catch {set tmpType [GetParamValue Type $DirectPath] }]} {
                    return -code 1 -errorinfo "6.Direct Path \"$DirectPath\" is bad"
                }
            }
            if {$tmpType == "SW" }  {
                set port 0
            }
        }
        ## setting port/node guids
        if {[info exists G(GuidByDrPath,$DirectPath)]} {
            set PortGuid $G(GuidByDrPath,$DirectPath)
            if {[info exists G(NodeGuid,$PortGuid)]} {
                set NodeGuid $G(NodeGuid,$PortGuid)
            } else {
                set byDr 1
            }
        } else {
            set byDr 1
        }
        ### Getting the parameter value 
        set value DZ
        switch -exact -- $parameter { 
            "PN" { return [FormatInfo $port PN $DirectPath] }
            "PortGUID" {
                set addPort2Cmd [regexp {(Port|Lft)} $cfg(source)]
                if {[info exists PortGuid]} {
                    return [FormatInfo $PortGuid $parameter $DirectPath]
                } else {
                    set Cmd [list SmMadGetByDr $cfg(source) -$cfg(flag) "$DirectPath"]
                    if {$addPort2Cmd} { append Cmd " $port" }
                    if {[catch { set value [eval $Cmd]}]} { return -code 1 }
                }
            }
            default {
                set addPort2Cmd [regexp {(Port|Lft)} $cfg(source)]
                if {[info exists NodeGuid]} {
                    set InfoSource "$cfg(source),$NodeGuid"
                    if {$addPort2Cmd} { append InfoSource ":$port" }
                } else {
                    set InfoSource "DZ"
                }
                if {$byDr} {
                    if {$noread} { return -code 1 -errorinfo "1.Direct Path \"$DirectPath\" is bad"}
                    if { [PathIsBad $DirectPath] > 1 } {
                        return -code 1 -errorinfo "2.Direct Path \"$DirectPath\" is bad"
                    }
                    set Cmd [list SmMadGetByDr $cfg(source) -$cfg(flag) "$DirectPath"]
                    if {$addPort2Cmd} { append Cmd " $port" }
                    if {[catch { set value [eval $Cmd]}]} { return -code 1 -errorinfo "5.Direct Path \"$DirectPath\" is bad"}
                } else {
                    if {[info exists G($InfoSource)]} { 
                        if {$parameter == "NodeDesc"} {
                            return [FormatInfo $G(NodeDesc,$NodeGuid) NodeDesc $DirectPath]
                        }
                        return [FormatInfo [WordAfterFlag $G($InfoSource) -$cfg(flag)] $parameter $DirectPath]    
                    } else {
                        if { [PathIsBad $DirectPath] > 1 } {
                            return -code 1 -errorinfo "3.Direct Path \"$DirectPath\" is bad"
                        }
                        if {$noread} { return -code 1 -errorinfo "4.DZ Direct Path \"$DirectPath\" is bad"}
                        set Cmd [list SmMadGetByDr $cfg(source) -$cfg(flag) "$DirectPath"]
                        if {$addPort2Cmd} { append Cmd " $port" }
                        if {[catch { set value [eval $Cmd]}]} { return -code 1 }
                    }
                }
            }
        }
    return [FormatInfo $value $parameter $DirectPath]
}
##############################

##############################
proc FormatInfo {_value _parameter _directRoute} {
    global G INFO_LST MASK
    set value $_value
    ParseOptionsList $INFO_LST($_parameter)
    ## Formatting $value
    catch { set value [format %lx $value] }
    regsub {^0x} $value {} value

    # bits -> bytes
    if {[catch { set width [expr $cfg(width) / 4] }]} { set width "" }

    if {!(( $width == 0 ) || ( ! [regexp {^[0-9]+} $width] )) } {
        if {[info exists cfg(offset)]} { 
            scan $cfg(offset) {%d%[:]%d} offset D bigwidth
            set bigwidth [expr $bigwidth / 4]
            set offset [expr $offset / 4]
            set value [ZeroesPad $value $bigwidth]
            set value [string range $value $offset [expr $offset + $width -1]]
        } else { 
            set value [ZeroesPad $value $width]
        }
    }

    if {[info exists cfg(substitution)]} { 
        regsub -all { *= *} [join $cfg(substitution)] {= } substitution
        set value [ZeroesErase $value]
        set value [WordAfterFlag $substitution "$value="] 
    } 
    if { ! [info exists cfg(string)] } {
        set value "0x$value"
    }
    return $value
}
##############################

######################################################################
### ouput fabric info
######################################################################
proc linkAtPathEnd { Path } {
    if { [catch { set port1 [GetEntryPort $Path] } ] } { 
	return -code 1
    }
    
    uplevel  1 set path0 \"[lreplace $Path end end]\"
    uplevel  1 set port0 [lindex $Path end]
    uplevel  1 set path1 \"$Path\"
    uplevel  1 set port1 $port1
}
##############################

##############################
#  NAME         lstInfo
#  SYNOPSIS     lstInfo type{port|link} DirectPath port
#  FUNCTION     returns either the info of one of a port in .lst format 
#                       or the info regarding the links : SPD,PHY,LOG
#  INPUTS       NULL
#  OUTPUT       returns the info of one of a port in .lst format
proc lstInfo { type DirectPath port } {
    global G MASK SM
    set DirectPath [join $DirectPath]
    set Info ""
    ## The lists of parameters
    switch -exact -- $type { 
	"port" { 
	    set sep ":" 
	    append lstItems "Type Ports SystemGUID NodeGUID PortGUID VenID"
	    append lstItems " DevID Rev NodeDesc LID PN"
	} "link" { 
	    set sep "="
	    append lstItems "PHY LOG SPD" 
	}
    }
    
    foreach parameter $lstItems {
	# The following may fail - then the proc will return with error
        # Knowen Issue - GetParamValue will return 
        regsub {^0x} [GetParamValue $parameter $DirectPath $port] {} value
	# .lst formatting of parameters and their values
	if {[WordInList $parameter "VenID DevID Rev LID PN"]} {
	    set value [string toupper $value]
	}
        switch -exact -- $parameter {
            "Ports"     { set tmpPorts  $value }
            "PN"        { set tmpPN     $value }
        }
        switch -exact -- $parameter {
            "Type"	{ 
                # Replace CA with CA-SM 
                if {$value == "CA"} {
                    set master 3
                    if {[info exists SM($master)]} {
	     	        foreach element $SM($master) {
                            set tmpDirectPath [lindex $element 0]
                            if {$DirectPath == $tmpDirectPath} {
                                set value "CA-SM"
                            }
                        }
		    }
                }
                lappend Info "$value" 
            }
	    "NodeDesc"	{ lappend Info "\{$value\}" }
	    "DevID"	{ lappend Info "${parameter}${sep}${value}0000" }
	    "VenID"	{ lappend Info "${parameter}${sep}00${value}" }
	    default	{ lappend Info "${parameter}${sep}${value}" }
	}
    }
    if {$type == "port"} {
        if {[info exists tmpPorts] && [info exists tmpPN]} {
            if {$tmpPorts < $tmpPN} {
                set G(lst.failed) 1
            }
        }
    }
    return [join $Info]
}
##############################

##############################
#  NAME         writeLstFile
#  SYNOPSIS     writeLstFile  
#  FUNCTION     writes a dump of the fabric links
#  INPUTS       NULL
#  OUTPUT       NULL
proc writeLstFile {} {
    global G

    set FileID [InitOutputFile $G(tool).lst]
    foreach DirectPath $G(list,DirectPath) {
        # seperate the next 3 logical expr to avoid extra work
        if {![llength $DirectPath]  } {continue }
        if {[PathIsBad $DirectPath] > 1 } {continue }
        if {[catch {linkAtPathEnd $DirectPath}] } {continue }
	set lstLine ""
        append lstLine "\{ [lstInfo port $path0 $port0] \} "
        append lstLine "\{ [lstInfo port $path1 $port1] \} "
        append lstLine "[lstInfo link $path0 $port0]"
        puts $FileID "$lstLine"
        unset path0
        unset path1
        unset port0
        unset port1
    }
    close $FileID

    return
}
##############################

##############################
#  NAME         writeNeighborFile
#  SYNOPSIS     writeNeighborFile  
#  FUNCTION     writes a dump of the ports pairs in the discovered fabric
#  INPUTS       NULL
#  OUTPUT       NULL
proc writeNeighborFile { args } {
    global Neighbor G

    set FileID [InitOutputFile $G(tool).neighbor]
    set preGuid ""
    foreach neighbor [lsort -dictionary [array names Neighbor]] {
        if {($preGuid != [string range $neighbor 0 17]) && ($preGuid != "")} {
            puts $FileID ""
        }
        puts $FileID "$neighbor\t$Neighbor($neighbor)"
        set preGuid [string range $neighbor 0 17]
    }
    close $FileID
    return
}
##############################

##############################
#  NAME         writeMasksFile
#  SYNOPSIS     writeMasksFile  
#  FUNCTION     writes a map for duplicate GUIDs <-> New assgiened GUIDs
#  INPUTS       NULL
#  OUTPUT       NULL
proc writeMasksFile { args } {
    global MASK G
    if {[llength [array names MASK *Guid,*]] == 0 } {
        return 0
    }
    set FileID [InitOutputFile $G(tool).masks]
    foreach mask [lsort -dictionary [array names MASK *Guid,*]] {
        puts $FileID "$mask\t$MASK($mask)"
    }
    close $FileID
    return 1
}
##############################

##############################
#  NAME         writeSMFile
#  SYNOPSIS     writeSMFile 
#  FUNCTION     writes a dump of SM query
#  INPUTS       NULL
#  OUTPUT       NULL
proc writeSMFile {} {
    global SM G
    set SMFound 0
    for {set i 3} {$i > -1} {incr i -1} {
        if {[info exists SM($i)]} {
            set SMFound 1
        }
    }

    if {!$SMFound} {return 0}
    set FileID [InitOutputFile $G(tool).sm]

    puts $FileID "ibdiagnet fabric SM report"

    DumpSMReport $FileID
    close $FileID
    return 1

}

##############################
#  NAME         writePMFile
#  SYNOPSIS     writePMFile 
#  FUNCTION     writes a dump of Port Counter query
#  INPUTS       NULL
#  OUTPUT       NULL
proc writePMFile {} {
    global G PM_DUMP
    if {![info exists PM_DUMP]} {return 0}
    set FileID [InitOutputFile $G(tool).pm]
    foreach name $PM_DUMP(nodeNames) {
        puts $FileID [string repeat "-" 80]
        puts $FileID $name
        puts $FileID [string repeat "-" 80]
        set tmpPmCounterList $PM_DUMP($name,pmCounterList)
        set listOfPMValues $PM_DUMP($name,pmCounterValue)
        foreach pmCounter $tmpPmCounterList {
            set pmCounterValue "0x[format %lx [WordAfterFlag $listOfPMValues $pmCounter]]"
            puts $FileID "$pmCounter = $pmCounterValue"
        }
    }

    close $FileID
    return 1
}

##############################

##############################
#  SYNOPSIS	write.fdbsFile
#  FUNCTION
#	writes the $G(tool).fdbs file, which lists the Linear Forwarding Tables
#	of all the switches in the discovered faric.
#	Writing this file is part of the flow of ibdiagnet.
#	The data is obtained by sending LftBlock MADs to read all the entires
#	of the Linear Forwarding Tables to all the switches.
#	The file has the following format for each switch of the IB fabric:
#	   Switch <NodeGuid>
#	   LID    : Out Port(s)
#	   0xc000   0x002 0x00f
#		...
#  INPUTS	NULL
#  OUTPUT	the file $G(tool).mcfdbs
#  DATAMODEL	
#	the proc uses the global arrays
#	$G(PortInfo,<NodeGuid>:0) - as a list of all the switches
#	and $G(Guid2DrPath,<NodeGuid>) - to translate node-guids to direct paths
#	it sets the global array $G(mclid2DrPath,<mcLid>) - a list of (direct
#	paths to) HCAs belonging to a multicast-lid - to be used later by
#	reportFabQualities.
proc writeFdbsFile { args } {
    global G

    set FileID [InitOutputFile $G(tool).fdbs]

    foreach entry [array names G "DrPathOfGuid,*"] {
        set DirectPath $G($entry)
        if {[PathIsBad $DirectPath] > 1} { continue }
        set NodeType [GetParamValue Type $G($entry)]
        if {$NodeType != "SW"} { continue }

        set PortGuid [lindex [split $entry ,] end]
        set NodeGuid $G(NodeGuid,$PortGuid) 

        set thisSwLid [GetParamValue LID $DirectPath X -noread]
	if {[PathIsBad $DirectPath] > 1} { continue }
	if [catch {set LinFDBTop \
		       [SmMadGetByDr SwitchInfo -lin_top "$DirectPath"]}] { 
	    continue 
	}
	set FDBs ""
	for { set I 0 } { [expr $I *64] <= $LinFDBTop } { incr I } {
	    # Note "<=" - because LinFDBTop indicates the INDEX of the last 
	    # valid entry 
	    if [catch {set NewFDBs \
			   [SmMadGetByDr LftBlock dump "$DirectPath" $I] }] { 
		set FDBs [concat $FDBs [bar "0xff " 64]]
	    } else { 
		set FDBs [concat $FDBs $NewFDBs] 
	    }
	}
	puts -nonewline $FileID "osm_ucast_mgr_dump_ucast_routes: "
	puts $FileID "Switch $NodeGuid"
	puts $FileID "LID    : Port : Hops : Optimal"
	for { set lid 1 } { $lid <= $LinFDBTop } { incr lid 1 } { 
	    scan [lindex $FDBs $lid] %x port
	    puts -nonewline $FileID "0x[string toupper [format %04x $lid]] : "
	    if { $port == "0xff" } { 
		puts $FileID "UNREACHABLE"
	    } elseif { ( $port == "0x00" ) && ( $lid != $thisSwLid ) } {
		puts $FileID "UNREACHABLE"
	    } else { 
		puts $FileID "[ZeroesPad $port 3]  : 00   : yes"
	    }
	}
	puts $FileID ""
    }
    close $FileID
}
##############################

##############################
#  SYNOPSIS	write.mcfdbsFile
#  FUNCTION
#	writes the $G(tool).mcfdbs file, which lists the Multicast Forwarding
#	Tables of all the switches in the discovered faric.
#	Writing this file is part of the flow of ibdiagnet.
#	The data is obtained by sending MftBlock MADs to read all the entires
#	of the MC Forwarding Tables. Note the tables are read in blocks of
#	16 ports x 64 mcLids blocks, thus if a deviec has more than 16 ports
#	then reading its mc table is a bit tricky...
#	The file has the following format for each switch of the IB fabric:
#	   Switch <NodeGuid>
#	   LID    : Out Port(s)
#	   0xc000   0x002 0x00f
#		...
#  INPUTS	NULL
#  OUTPUT	the file $G(tool).mcfdbs
#  DATAMODEL	
#	the proc uses the global arrays
#	$G(PortInfo,<NodeGuid>:0) - as a list of all the switches
#	and $G(Guid2DrPath,<NodeGuid>) - to translate node-guids to direct paths
#	it sets the global array $G(mclid2DrPath,<mcLid>) - a list of (direct
#	paths to) HCAs belonging to a multicast-lid - to be used later by
#	reportFabQualities.
proc writeMcfdbsFile { } { 
    global G

    set FileID [InitOutputFile $G(tool).mcfdbs]

    foreach entry [array names G "DrPathOfGuid,*"] {
        set DirectPath $G($entry)
        if {[PathIsBad $DirectPath] > 1} { 
            continue 
        }
        set NodeType [GetParamValue Type $G($entry)]
        if {$NodeType != "SW"} { continue }
        set PortGuid [lindex [split $entry ,] end]
        set NodeGuid $G(NodeGuid,$PortGuid) 

        if {[catch { set McFDBCap [SmMadGetByDr SwitchInfo -mcast_cap "$DirectPath"] }]} { 
            continue
        }
        set NumPorts [GetParamValue Ports $DirectPath]
        puts $FileID "\nSwitch $NodeGuid\nLID    : Out Port(s) "
        for {set LidGrp 0xc000} {$LidGrp < 0xc000 + $McFDBCap} {incr LidGrp 0x20} {
            set McFDBs ""
            set LidGroup "0x[format %lx $LidGrp]"
            # read the entire McFDBs data for Lids $LidGroup .. $LidGroup + 0x1f
            for {set PortGroup 0} {$PortGroup <= $NumPorts} {incr PortGroup 16} {
                if {[catch { set newBlock [SmMadGetByDr MftBlock dump "$DirectPath" $LidGroup $PortGroup] }]} { break }
                if {[lindex $newBlock 0] == "-mft"} {
                    append McFDBs " " [Hex2Bin [lrange $newBlock 1 end]]
                } else {
                    append McFDBs " " [Hex2Bin $newBlock]
                }
            }
            # figure out - and print to file - the mc ports for each Lid 
            # in the lid group
            for { set lidIdx 0 } { $lidIdx < 0x20 } { incr lidIdx } {
                set mask ""
                for { set PortGroup 0; set idx 0 } { $PortGroup <= $NumPorts } { incr PortGroup 16; incr idx 32 } {
                    set mask "[lindex $McFDBs [expr $lidIdx + $idx]]$mask"
                }
                if { ! [regexp "1" $mask] } { continue }
                set mcLid [format %04x [expr $lidIdx + $LidGroup]]
                set outputLine "0x[string toupper $mcLid] :"
                for { set Port 0; set maskIdx [expr [string length $mask]-1] } { $Port <= $NumPorts } { incr Port 1 ; incr maskIdx -1 } {
                    if { [string index $mask $maskIdx] == 1 } { 
                        append outputLine " 0x[string toupper [format %03x $Port]] "
                        set LongPath [join "$DirectPath $Port"]
                        catch { if { [GetParamValue Type $LongPath -byDr] != "SW" } { 
                                set directPathName [DrPath2Name $LongPath -byDr]
                                if {$directPathName !=""} {
                                    lappend G(mclid2DrPath,0x$mcLid) $directPathName
                                } else {
                                    lappend G(mclid2DrPath,0x$mcLid) $LongPath
                                }
                            }
                        }
                    }
                }
                puts $FileID "$outputLine"
            }
        }
    }
    close $FileID
}
######################################################################

##############################
### Debug related procedure 
##############################
#  SYNOPSIS	
#	debug msgId args 
#  FUNCTION	
#	provides verbosity for tool's debug
#  INPUTS	
#	$msgId - message id (I usually use the line number in the script)
#	$args - a list of arguments which may be any of the kind:
#	- names of variables
#	- commands to run
#	- the special argument "-header"
#  OUTPUT	NULL
#  DATAMODEL	
#	the proc uses the global variable $G(argv,debug) - indicating
#	whether we are running in debug mode
#  RESULT: TODO: fix this
#	writes a message to the standard output, according to $type 
#	(and to the file ${tool}.dbg ??)
#	if type=="header", write the calling proc's name and values of arguments
#	if type=="vars", write the names and values of variables denoted by $args
#	otherwise, write the message $type with optional printing parameters 
#	(e.g., "-nonewline") $args
proc debug { msgId args } {
    global G
    if { ! $G(argv,debug) } { return }
    set srcProcName [ProcName 1]
    set message "-D- $msgId $srcProcName"
    if {[regsub " -header " " $args " { } args ]} {
	append message " header:"
	set varNames [concat [info args $srcProcName] $args]
    } else {
	append message ":"
	set varNames $args
    }
    foreach var $varNames {
	catch { unset value }
	catch { set value [uplevel set . [join $var]] }
	catch { set value [uplevel set . $$var] }
	catch { regsub {^\$} $value {} value }
	if { ! [info exists value] } { 
	    continue 
	} elseif { $var == $value } { 
	    continue 
	} elseif { $var == "args" } {
	    append message " $var = $value (len=[llength $value]);"
	} else {
	    append message " $var = $value ;"
	}
    }
    puts "$message"
    return
}
##############################

##############################
#  SYNOPSIS	listG
#  FUNCTION	displays (compactly) the entries in the global vars array G
#		if the --G flag was specified in the comand line.
#		This is used for debug purposes.
#		Ran from finishIBDebug.
#  INPUTS	NULL
#  OUTPUT	NULL
proc listG {} {
    global G argv
    if {  [WordInList "--G" $argv] } { 
        foreach entry [lsort [array names G]] {
            puts "$entry : $G($entry)"
        }
        return 1
    }

    if { ! [WordInList "--G" $argv] } { return }
    set Glist ""
    foreach entry [lsort [array names G]] { 
	regsub {,[^,]*$} $entry {,*} head1
	regsub {,[^,]*$} [lindex $Glist end] {,*} head0
	regsub {^PortInfo,[0-9a-fx]+,\*} $head1 {PortInfo,*,*} head1
	regsub {^PortInfo,[0-9a-fx]+,\*} $head0 {PortInfo,*,*} head0
	if { "$head0" == "$head1" } { set Glist [lreplace $Glist en end $head1]
	} else { lappend Glist "$entry" }
    }
    puts "-G- G entries: [join [lsort $Glist] "; "]"
    return
}

proc CheckAllinksSettings {} {
    global G LINK_SPD LINK_PHY
    set checkList ""
    set spd ""
    set phy ""
    if {[info exists G(argv,link.width)]} {
        lappend checkList "PHY"
        set phy $G(argv,link.width)
    }
    if {[info exists G(argv,link.speed)]} {
        lappend checkList "SPD"
        set spd $G(argv,link.speed)
    }

    foreach DirectPath $G(list,DirectPath) {
        if {$DirectPath == ""} {
            continue
        }
        if {[lsearch $checkList "SPD"] != -1} {
            set tmpLinkspeed [GetParamValue "SPD" $DirectPath [GetEntryPort $DirectPath]]
            if {$tmpLinkspeed != $spd} {
                lappend LINK_SPD($DirectPath) $tmpLinkspeed
            }
        }
        if {[lsearch $checkList "PHY"] != -1} {
            set tmpLinkWidth [GetParamValue "PHY" $DirectPath [GetEntryPort $DirectPath]]
            if {$tmpLinkWidth != $phy} {
                lappend LINK_PHY($DirectPath) $tmpLinkWidth
            }
        }
    }

    if {[lsearch $checkList "PHY"] != -1} {
        inform "-I-ibdiagnet:bad.link.width.header"
        if {[llength [array names LINK_PHY]]} {
            foreach link [lsort [array names LINK_PHY]] {                                                        
                if {[PathIsBad $link] > 1} {continue}
                set paramlist "-DirectPath0 \{[lrange $link 0 end-1]\} -DirectPath1 \{$link\}"
                eval inform "-W-ibdiagnet:report.links.width.state" -phy $LINK_PHY($link) $paramlist
                set firstINITlink 1
            }
        } else {
            inform "-I-ibdiagnet:no.bad.link.width"
        }
    }

    if {[lsearch $checkList "SPD"] != -1} {
        inform "-I-ibdiagnet:bad.link.speed.header"
        if {[llength [array names LINK_SPD]]} {
            foreach link [lsort [array names LINK_SPD]] {                                                        
                if {[PathIsBad $link] > 1} {continue}
                set paramlist "-DirectPath0 \{[lrange $link 0 end-1]\} -DirectPath1 \{$link\}"
                eval inform "-W-ibdiagnet:report.links.speed.state" -spd $LINK_SPD($link) $paramlist
                set firstINITlink 1
            }
        } else {
            inform "-I-ibdiagnet:no.bad.link.speed"
        }
    }
    return 
}
                                              
