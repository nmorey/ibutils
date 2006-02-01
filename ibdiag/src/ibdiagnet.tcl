### This script is running over ibis (/usr/bin/ibis)
source [file join [file dirname [info script]] ibdebug.tcl]

######################################################################
#****h* IB Debug Tools/ibdiagnet
#  NAME
#     ibdiagnet
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
#  FUNCTION
#     ibdiagnet discovers the entire network providing text display of the result as well as subnet.lst, 
#     LFT dump (same format as osm.fdbs) and Multicast dump (same as osm.mcfdbs). 
#     The discovery exhaustively routes through all the fabric links multiple times, 
#     tracking and reporting packet drop statistics - indicating bad links if any.
#
#  AUTHOR
#	Ariel Libman. Mellanox Technologies LTD.
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
### Initialize ibis
InitalizeIBdiag
InitalizeINFO_LST
startIBDebug
### Discover the cluster
set G(detect.bad.links) 1
if {[catch {DiscoverFabric} e]} { puts "\n\nERROR $errorInfo $e"}
DiscoverHiddenFabric
CheckBadLidsGuids
CheckSM

RereadLongPaths
set G(detect.bad.links) 0

### Write the .lst, .fdbs and .mcfdbs files
writeLstFile
writeFdbsFile 
writeMcfdbsFile
writeMasksFile
#writeNeighborFile
writeSMFile

### match topology (if topology is given)
matchTopology $G(outfiles,.lst)
### output info about bad/broken links
BadLinksUserInform

### report the results of topology matching (after bad links report)
reportTopologyMatching

### report fabric qualities
reportFabQualities

### Finishing
finishIBDebug
######################################################################
package provide $G(tool)

