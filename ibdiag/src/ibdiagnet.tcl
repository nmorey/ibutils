### This script is running over ibis (/usr/bin/ibis)
source [file join [file dirname [info script]] ibdebug.tcl]

######################################################################
#
# Copyright (c) 2004 Mellanox Technologies LTD. All rights reserved.
#
# This software is available to you under a choice of one of two
# licenses.  You may choose to be licensed under the terms of the GNU
# General Public License (GPL) Version 2, available from the file
# COPYING in the main directory of this source tree, or the
# OpenIB.org BSD license below:
#
#     Redistribution and use in source and binary forms, with or
#     without modification, are permitted provided that the following
#     conditions are met:
#
#      - Redistributions of source code must retain the above
#        copyright notice, this list of conditions and the following
#        disclaimer.
#
#      - Redistributions in binary form must reproduce the above
#        copyright notice, this list of conditions and the following
#        disclaimer in the documentation and/or other materials
#        provided with the distribution.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# $Id: node.h,v 1.23 2005/07/07 21:15:29 eitan Exp $
#
######################################################################

######################################################################
### Action 
######################################################################
### Initialize ibis
startIBDebug

### Discover the cluster
set G(detect.bad.links) 1
discoverFabric
discoverHiddenFabric
checkBadLidsGuids

# HERE
rereadLongPaths
set G(detect.bad.links) 0

### Write the .lst, .fdbs and .mcfdbs files
write.lstFile
write.fdbsFile 
write.mcfdbsFile

### match topology (if topology is given)
matchTopology $G(outfiles,.lst)
### output info about bad/broken links
badLinksUserInform

### report the results of topology matching (after bad links report)
reportTopologyMatching

### report fabric qualities
reportFabQualities

### Finishing
finishIBDebug
######################################################################
package provide $G(tool)

