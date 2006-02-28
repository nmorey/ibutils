### This script is running over ibis (/usr/bin/ibis)
source [file join [file dirname [info script]] ibdebug.tcl]

######################################################################
#  IB Debug Tools
#  NAME
#       ibdiagnet
#
#  COPYRIGHT
#               - Mellanox Confidential and Proprietary -
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
#  FUNCTION
#     ibdiagnet discovers the entire network. providing text display of the result as well as subnet.lst, 
#     LFT dump (same format as osm.fdbs) and Multicast dump (same as osm.mcfdbs). 
#     The discovery exhaustively routes through all the fabric links multiple times, 
#     tracking and reporting packet drop statistics - indicating bad links if any.
#
#  AUTHOR
#	Danny Zarko. Mellanox Technologies LTD.
#
#  CREATION DATE
#	19/May/05
#
#  MODIFICATION HISTORY
#  $Revision: 2608 $
#  Initial Revision.
#
#  NOTES
#
#******
######################################################################

######################################################################
### Action 
######################################################################
### Initialize ibis and pre-setting for ibdiag
InitalizeIBdiag
InitalizeINFO_LST
startIBDebug
set G(detect.bad.links) 1
### Discover the cluster
if {[catch {DiscoverFabric 0} e]} { 
    ### Discover the hidden cluster
    if {[catch {DiscoverHiddenFabric} e]} { 
        inform "-I-discover:discovery.status"
        inform "-I-exit:\\r"
        inform "-V-discover:end.discovery.header"
        inform "-E-discover:broken.func" $errorInfo $e
    }
}

### Write the .lst
writeLstFile

### match topology (if topology was given)
set G(matchTopologyResult) [matchTopology $G(outfiles,.lst)]
DumpBadLidsGuids
DumpBadLinksLogic
CheckSM
RereadLongPaths

### Write the .fdbs, .mcfdbs, .masks and .sm files
writeFdbsFile 
writeMcfdbsFile
writeMasksFile
writeSMFile

### output info about bad/broken links
BadLinksUserInform

### report the results of topology matching (after bad links report)
reportTopologyMatching

### report fabric qualities
if {[catch {reportFabQualities} e]} { puts "\n\nERROR $errorInfo $e" ; exit 1}
#reportFabQualities

### Finishing
finishIBDebug
######################################################################
package provide $G(tool)

