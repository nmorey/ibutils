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
# $Id: Makefile.am,v 1.9 2005/03/20 11:22:55 eitan Exp $
#--

## Makefile.am -- Process this file with automake to produce Makefile.in

# Support debug mode through config variable
if DEBUG
DBG = -O0 -g
else
DBG = -O2
endif

AM_CXXFLAGS = $(DBG)

INCLUDES		= -I$(with_ibdm)/include -I$(with_osm)/include $(TCL_CPPFLAGS)

AM_CPPFLAGS = -I$(top_srcdir)/datamodel $(OSM_DEBUG_FLAGS)

bin_PROGRAMS = ibmssh ibmsquit #ibmgtsim test_msgmgr test_client test_server ibmgt_client 

LDADD = -L$(with_ibdm)/lib -libdmcom -L$(with_osm)/lib -lcomplib
# AM_LDFLAGS = -static

# this is the main simulator
#ibmgtsim_SOURCES = sim.cpp server.cpp node.cpp dispatcher.cpp \
#	msgmgr.cpp simmsg.cpp tcpcomm.cpp sma.cpp 
#ibmgtsim_CPPFLAGS = -DBUILD_STANDALONE_SIM=1

ibmssh_SOURCES = sim.cpp server.cpp node.cpp dispatcher.cpp \
	 ibmssh_wrap.cpp sma.cpp 

ibmssh_LDFLAGS = -static -Wl,-rpath -Wl,$(TCL_PREFIX)/lib \
	-Wl,-rpath -Wl,$(with_osm)/lib \
	-Wl,-rpath -Wl,$(with_ibdm)/lib 

ibmssh_LDADD = -libmscli -L$(with_ibdm)/lib -libdmcom -L$(with_osm)/lib -lcomplib $(TCL_LIBS) 

# SWIG FILES:
SWIG_IFC_FILES= $(srcdir)/sim.i $(srcdir)/ib_types.i $(srcdir)/ibdm.i

# only generate the swig wrappers if they do not exist...
# so we avoid un-needed swig dependency
if HAS_SWIG
$(srcdir)/ibms_wrap.cpp: @MAINTAINER_MODE_TRUE@ $(SWIG_IFC_FILES)
	swig -I$(srcdir) -c++ -dhtml -tcl8 -o swig_wrap.c $(srcdir)/sim.i
	$(srcdir)/../utils/fixSwigWrapper -g -s -p -o $@
	rm -f swig_wrap.c	

$(srcdir)/ibmssh_wrap.cpp: @MAINTAINER_MODE_TRUE@ $(SWIG_IFC_FILES)
	swig -I$(srcdir) -c++ -dhtml -tcl8  -ltclsh.i -o swig_wrap.c $(srcdir)/sim.i
	$(srcdir)/../utils/fixSwigWrapper -g -s -p -r ibms -o $@
	rm -f swig_wrap.c
endif

swigclean:
	rm -f $(srcdir)/ibms_wrap.cpp $(srcdir)/ibmssh_wrap.cpp *wrap.o

# we need there extra in the distribution as their dependency is not defined
EXTRA_DIST = swig_alternate_mangling.cpp fixSwigWrapper pkgIndex.tcl

# Quiter for the server
ibmsquit_SOURCES = client.cpp msgmgr.cpp simmsg.cpp tcpcomm.cpp
ibmsquit_CPPFLAGS = -DBUILD_QUIT_CLIENT=1

# tester of the client code 
#ibmgt_client_SOURCES = client.cpp msgmgr.cpp simmsg.cpp tcpcomm.cpp
#ibmgt_client_CPPFLAGS = -DBUILD_TEST_CLIENT=1

# simple client program for testing
#test_client_SOURCES = tcpcomm.cpp msgmgr.cpp
#test_client_CPPFLAGS = -DBUILD_TCP_COMM_CLIENT=1

# simple server program for testing
#test_server_SOURCES = tcpcomm.cpp msgmgr.cpp
#test_server_CPPFLAGS = -DBUILD_TCP_COMM_SERVER=1

# testing message manager 
#test_msgmgr_SOURCES = msgmgr.cpp simmsg.cpp
#test_msgmgr_CPPFLAGS = -DMSG_MGR_TEST=1

# client library to be used by OSMV type sim:

# ibms shared library version triplet is:
# API_ID:API_VER:NUM_PREV_API_SUP = x:y:z
# * change of API_ID means new API
# * change of AGE means how many API backward compt 
# * change of API_VER is required every version
# Results with SO version: x-z:z:y
LIB_VER_TRIPLET="1:0:0"
LIB_FILE_TRIPLET=1.0.0

lib_LTLIBRARIES = libibmscli.la

libibmscli_la_SOURCES = client.cpp simmsg.cpp msgmgr.cpp tcpcomm.cpp
#  -Wl,-rpath -Wl,$(TCL_PREFIX)/lib
libibmscli_la_LDFLAGS = -version-info $(LIB_VER_TRIPLET) -no-undefined

# we would like to export these headers during install
pkginclude_HEADERS = ibms_client_api.h simmsg.h ib_types_extend.h

# Don't distribute common.h, since it is build host dependent!
#dist-hook:
#	rm -f $(distdir)/common.h
