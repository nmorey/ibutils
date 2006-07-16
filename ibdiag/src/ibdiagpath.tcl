### This script is running over ibis (/usr/bin/ibis)
source [file join [file dirname [info script]] ibdebug.tcl]

######################################################################
#  IB Debug Tools
#  NAME
#       ibdiagpath
#
#  COPYRIGHT
#                 - Mellanox Confidential and Proprietary -
#
# Copyright (C) Jan. 2004, Mellanox Technologies Ltd.  ALL RIGHTS RESERVED.
#
# Except as specifically permitted herein, no portion of the information,
# including but not limited to object code and source code, may be reproduced,
# modified, distributed, republished or otherwise exploited in any form or by
# any means for any purpose without the prior written permission of Mellanox
# Technologies Ltd. Use of software subject to the terms and conditions
# detailed in the file "LICENSE.txt".
# End of legal section.
#
# DATAMODEL
#     Note: all global variables are placed in the array G
#
#  FUNCTION
#     ibdiagpath traces a path between two LIDs/GUIDs 
#     and provides information regarding the nodes and ports passed and their health. 
#     ibdiagpath utilizes device-specific health queries for the different devices on the path.
#
#  AUTHOR
#	Danny Zarko. Mellanox Technologies LTD.
#
#  CREATION DATE
#	04/Aug/05
#
#  MODIFICATION HISTORY
#  $Revision: 2622 $
#  Initial Revision.
#
#  NOTES
#
#******
######################################################################

######################################################################
proc ibdiagpathMain {} {
    # previously, consisted of 2 procs, ibdiagpathGetPaths & readPerfCountres
    global G errorInfo
    set addressingLocalPort 0
    # So we could use topology file names
    set G(matchTopologyResult) [info exists G(argv,topo.file)]
    # lid routing
    if {[info exists G(argv,lid.route)]} {
        set targets [split $G(argv,lid.route) ","]
        if { $G(argv,lid.route) == $G(RootPort,Lid) } { 
            set addressingLocalPort 1
        }
        if {[llength $targets] == 2} {
            if {[lindex $targets 0] == [lindex $targets 1]} {
                set targets [lindex $targets 0]
            }
        }
    }
    
    # direct routing
    if [info exists G(argv,direct.route)] {
        set targets [list [split $G(argv,direct.route) ","]]
        if { $G(argv,direct.route) == "" } {
            set addressingLocalPort 1
        }
    }

    # CHECK some Where that the names are legal
    if [info exists G(argv,by-name.route)] {
        array set mergedNodesArray [join [IBFabric_NodeByName_get $G(fabric,.topo)]]

        set localNodePtr  [IBFabric_getNode $G(fabric,.topo) $G(argv,sys.name)]
        set localPortPtr  [IBNode_getPort $localNodePtr $G(argv,port.num)]
        set localPortName [IBPort_getName $localPortPtr]
        if {[catch {set tmpRemote [IBPort_p_remotePort_get $localPortPtr]}]} {
            continue
        }
        foreach portPtr [getArgvPortNames] {
            if { $portPtr == $localPortPtr } {
                lappend targets $G(RootPort,Lid)
            } else {
                if {[catch {set tmpDR [name2Lid $tmpRemote $portPtr $G(argv,port.num)]} e]} {
                    inform "-E-topology:bad.sysName.or.bad.topoFile" -name [IBPort_getName $portPtr]
                }
                if {$tmpDR == -1} {
                    inform "-E-topology:no.route.to.host.in.topo.file" -name [IBPort_getName $portPtr] -topo.file $G(argv,topo.file)
                }
                if {[lindex $tmpDR end ] == 0} {
                    if {[catch {set newTarget [GetParamValue LID [lrange $tmpDR 0 end-1] -port 0 -byDr]} e]} {
                        inform "-E-topology:bad.path.in.name.tracing" -path $tmpDR -name [IBPort_getName $portPtr]
                    }
                } else {
                    if {[catch {set newTarget [GetParamValue LID "$tmpDR" -port [IBPort_num_get $portPtr] -byDr]} e]} {
                        inform "-E-topology:bad.path.in.name.tracing" -path $tmpDR -name [IBPort_getName $portPtr]
                    }
                }
                if {($newTarget == -1)} {
                    inform "-E-topology:lid.by.name.failed" -name [IBPort_getName $portPtr]
                }
                if {($newTarget == 0)} {
                    inform "-E-topology:lid.by.name.zero" -path $tmpDR -name [IBPort_getName $portPtr]
                }
                lappend targets $newTarget
                lappend targetsNames 
            }
            lappend targetsNames [IBPort_getName $portPtr]
            if { "$targets" == $G(RootPort,Lid) } { 
                set addressingLocalPort 1 
            } 
        }
        if {[llength $targets] == 2} {
            inform "-I-ibdiagpath:obtain.src.and.dst.lids" -name0 [lindex $targetsNames 0] \
                -name1 [lindex $targetsNames 1] -lid0 [lindex $targets 0] -lid1 [lindex $targets 1]
        } else {
            inform "-I-ibdiagpath:obtain.src.and.dst.lids" -name0 $localPortName \
                -name1 [lindex $targetsNames 0] -lid0 $G(RootPort,Lid) -lid1 [lindex $targets 0]
        }
    }
    set paths ""
    set G(detect.bad.links) 1
    for {set i 0} {$i < [llength $targets]} {incr i} {
        set address [lindex $targets $i]
        if { !$addressingLocalPort} {
            if {!$i } {
                if {[llength $targets] < 2} {
                    inform "-I-ibdiagpath:read.lft.header" local destination
                } else {
                    inform "-I-ibdiagpath:read.lft.header" local source
                }
            } else {
                inform "-I-ibdiagpath:read.lft.header" source destination
            }
        }
        set paths [concat $paths [DiscoverPath [lindex $paths end] $address]]
    }
    set G(detect.bad.links) 0
    ## for the special case when addressing the local node
    if $addressingLocalPort {
        inform "-W-ibdiagpath:ardessing.local.node"
        set paths $G(argv,port.num)
    }

    # Translating $src2trgtPath (starting at node at index $startIndex) into a list of LIDs and ports
    set local2srcPath   [lindex [lreplace $paths end end] end]
    set src2trgtPath    [lindex $paths end]
    set startIdx        [llength $local2srcPath]

    # For the case when the source node is a remote HCA
    if { ( $startIdx != 0 ) && [GetParamValue Type $local2srcPath -byDr] != "SW" } {
        set sourceIsHca [lindex $local2srcPath end]
        incr startIdx -2
    }
    # the following loop is only for pretty-priting...
    set llen ""
    for { set i $startIdx } { $i < [llength $src2trgtPath] } { incr i } {
        set portNames [lindex [linkNamesGet [lrange $src2trgtPath 0 $i]] end]
        lappend llen [string length [lindex $portNames 0]] [string length [lindex $portNames 1]]
    }
    set maxLen [lindex [lsort -integer $llen] end]
    # preparing the list of lid-s and ports for reading the PM counters
    set directPathsList [list $src2trgtPath]
    for { set I $startIdx } { $I < [llength $src2trgtPath] } { incr I } {
        set bug32708fix [expr ( $I == $startIdx ) && [info exists sourceIsHca]]
        set ShortPath [lrange $src2trgtPath 0 $I]
        if { $bug32708fix } {
            lappend ShortPath $sourceIsHca
            lappend directPathsList "$ShortPath"
        }
        if $addressingLocalPort {
            set port0 $G(argv,port.num)
            set path0 ""
        } else {
            if { [catch { linkAtPathEnd $ShortPath} ] } { continue }
        }
        set portNames [lindex [linkNamesGet $ShortPath] end]
        foreach idx { 0 1 } {
            if { $addressingLocalPort && ( $idx == 1 ) } { continue }
            # The link associated to bug32708fix should be displayed reverse order
            if { $bug32708fix } { set idx [expr 1 - $idx] }

            set name [lindex $portNames $idx]
            set port [expr $[list port$idx]]
            set path [expr $[list path$idx]]
            set LID  [GetParamValue LID $path $port]
            if { [GetParamValue Type $path -byDr] != "SW" } {
                set LID $G(DrPath2LID,$path:$port)
            } else {
                set LID $G(DrPath2LID,$path:0)
            }
            if { $LID == 0 } {
                inform "-E-ibdiagpath:reached.lid.0" \
                    -DirectPath "$path" +cannotRdPM
            }

            append name " lid:$LID port:$port"
            lappend LidPortList "$LID:$port"
            set linkLidsNames($LID:$port) $name
        }
    }
    inform "-I-ibdiagpath:read.pm.header"
    # Initial reading of Performance Counters
    foreach LidPort $LidPortList {
        if {[catch { set oldValues($LidPort) [join [PmListGet $LidPort]] } e] } {
            inform "-E-ibdiagpath:pmGet.failed" [split $LidPort :]
        }
    }
    # Sending MADs over the path(s)
    for { set count 0 } { $count < $G(argv,count) } { incr count } {
        foreach path $directPathsList {
            catch { SmMadGetByDr NodeDesc dump "$path"}
        }
    }
    # Final reading of Performance Counters
    foreach LidPort $LidPortList {
        if {![info exists oldValues($LidPort)]} {continue}
        if [catch { set newValues($LidPort) [join [PmListGet $LidPort]] }] {
            inform "-E-ibdiagpath:pmGet.failed" [split $LidPort :]
        }
        set pmList ""
        if {![info exists newValues($LidPort)]} {continue}
        for { set i 0 } { $i < [llength $newValues($LidPort)] } { incr i 2 } {
            set oldValue [lindex $oldValues($LidPort) [expr $i + 1]]
            set newValue [lindex $newValues($LidPort) [expr $i + 1]]
            lappend pmList [expr $newValue - $oldValue]
        }

        set name $linkLidsNames($LidPort)
        set rubberLen [expr $maxLen - [string length $name]]
        inform "-V-ibdiagpath:pm.value" "$name [bar " " $rubberLen] $pmList"
    }
    foreach LidPort $LidPortList {
        set name $linkLidsNames($LidPort)
        append name "[bar " " [expr $maxLen - [string length $name]]]"
        set badValues ""

        if {![info exists newValues($LidPort)]} {continue}
        if {![info exists oldValues($LidPort)]} {continue}
        foreach entry [ComparePMCounters $oldValues($LidPort) $newValues($LidPort)] {
            scan $entry {%s %s %s} parameter err value
            switch -exact -- $err {
                "valueChange" {
                    regsub -- "->" $value " - " exp
                    set value [expr - ($exp)]
                    lappend badValues "$parameter=$value"
                }
                "overflow" {
                    lappend badValues "$parameter=$value\(=overflow\)"
                }
            }
        }
        if { $badValues != "" } {
            putsIn80Chars "-E- $name: [join $badValues ", "]"
        }
    }

    return
}
######################################################################

######################################################################
### Action 
######################################################################
### Initialize ibis
InitalizeIBdiag
InitalizeINFO_LST
startIBDebug

### Figuring out the paths to take and Reading Performance Counters
set G(detect.bad.links) 1
ibdiagpathMain
set G(detect.bad.links) 0
### Finishing
finishIBDebug
######################################################################
