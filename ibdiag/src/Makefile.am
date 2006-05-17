#--
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
# $Id: Makefile.am,v 1.13 2005/03/23 16:15:39 eitan Exp $
#--

bin_SCRIPTS = ibdiagnet ibdiagpath
EXTRA_DIST = ibdebug_if.tcl ibdebug.tcl ibdiagnet.in ibdiagnet.pkg ibdiagnet.tcl \
	ibdiagpath.pkg ibdiagpath.tcl

ibdiagnet: ibdiagnet.in
	sed -e 's=%ibdiag_libdir%='$(DESTDIR)$(libdir)'=' \
	    -e 's=%with_ibdm_lib%='$(with_ibdm_lib)'=' $(srcdir)/ibdiagnet.in \
	    -e 's=%with_ibis%='$(with_ibis)'=' $(srcdir)/ibdiagnet.in > ibdiagnet

NET_LIB_DIR=$(DESTDIR)/$(libdir)/ibdiagnet$(VERSION)
PATH_LIB_DIR=$(DESTDIR)/$(libdir)/ibdiagpath$(VERSION)
install-exec-am: install-binSCRIPTS
	mkdir -p $(NET_LIB_DIR)
	cp $(srcdir)/ibdiagnet.pkg $(NET_LIB_DIR)/pkgIndex.tcl
	cp $(srcdir)/ibdebug.tcl $(NET_LIB_DIR)/ibdebug.tcl
	cp $(srcdir)/ibdebug_if.tcl $(NET_LIB_DIR)/ibdebug_if.tcl
	cp $(srcdir)/ibdiagnet.tcl $(NET_LIB_DIR)/ibdiagnet.tcl
	mkdir -p $(PATH_LIB_DIR)
	cp $(srcdir)/ibdiagpath.pkg $(PATH_LIB_DIR)/pkgIndex.tcl
	cp $(srcdir)/ibdebug.tcl $(PATH_LIB_DIR)/ibdebug.tcl
	cp $(srcdir)/ibdebug_if.tcl $(PATH_LIB_DIR)/ibdebug_if.tcl
	cp $(srcdir)/ibdiagpath.tcl $(PATH_LIB_DIR)/ibdiagpath.tcl
