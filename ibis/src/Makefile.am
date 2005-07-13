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
# $Id: Makefile.am,v 1.14 2005/05/24 11:59:20 eitan Exp $
#--

## Makefile.am -- Process this file with automake to produce Makefile.in

# Support debug mode through config variable
if DEBUG
DBG = -O0 -g -Wall -Werror
else
DBG = -O6 -Wall -Werror
endif

INCLUDES		= -I$(with_osm)/include $(TCL_CPPFLAGS)

AM_CFLAGS = -I$(top_srcdir)/datamodel $(OSM_DEBUG_FLAGS) $(DBG) 

# Complib uses new POSIX for rwlocks
AM_CFLAGS += -D_XOPEN_SOURCE=600 -D_BSD_SOURCE=1

# based on the vendor declare some defines:
if OSM_VENDOR_MTL
AM_CFLAGS += -DOSM_VENDOR_INTF_MTL
OSM_LIB = -losmsvc_mtl
endif
if OSM_VENDOR_TS
AM_CFLAGS += -DOSM_VENDOR_INTF_TS
OSM_LIB = -losmsvc_ts
endif
if OSM_VENDOR_SIM
AM_CFLAGS += -DOSM_VENDOR_INTF_SIM
OSM_LIB = -losmsvc_sim
endif

# ibis shared library version triplet is:
# API_ID:API_VER:NUM_PREV_API_SUP = x:y:z
# * change of API_ID means new API
# * change of AGE means how many API backward compt 
# * change of API_VER is required every version
# Results with SO version: x-z:z:y
LIB_VER_TRIPLET="1:0:0"
LIB_FILE_TRIPLET=1.0.0

lib_LTLIBRARIES = libibiscom.la libibis.la 

libibiscom_la_SOURCES = ibbbm.c ibcr.c	ibis.c ibis_gsi_mad_ctrl.c \
	ibpm.c ibsac.c ibsm.c ibvs.c

# client library to be used by IBIS TCL package:
libibis_la_SOURCES = ibis_wrap.c 

#  -Wl,-rpath -Wl,$(TCL_PREFIX)/lib
libibis_la_LDFLAGS = -version-info $(LIB_VER_TRIPLET) -no-undefined  \
	.libs/libibiscom.a -Wl,-rpath -Wl,$(with_osm)/lib \
	-L$(with_osm)/lib -lcomplib $(OSM_LIB) $(TCL_LIBS)

bin_PROGRAMS = ibis

LDADD = -L$(with_osm)/lib -lcomplib
# AM_LDFLAGS = -static

ibis_SOURCES = ibissh_wrap.c

ibis_LDFLAGS = -static -Wl,-rpath -Wl,$(TCL_PREFIX)/lib \
	-Wl,-rpath -Wl,$(with_osm)/lib $(OSM_LIB)

ibis_LDADD = -L$(with_osm)/lib -lcomplib $(TCL_LIBS) -libiscom


# SWIG FILES:
SWIG_IFC_FILES= $(srcdir)/ibbbm.i \
	$(srcdir)/ibcr.i \
	$(srcdir)/ibis.i \
	$(srcdir)/ibis_typemaps.i \
	$(srcdir)/ibpm.i \
	$(srcdir)/ibsac.i \
	$(srcdir)/ibsm.i \
	$(srcdir)/ibvs.i

# only generate the swig wrappers if they do not exist...
# so we avoid un-needed swig dependency
if HAS_SWIG
ibis_wrap.c: @MAINTAINER_MODE_TRUE@ $(SWIG_IFC_FILES)
	swig -I$(srcdir) -dhtml -tcl8 -o swig_wrap.c $(srcdir)/ibis.i
	$(srcdir)/fixSwigWrapper -g -s -p -o ibis_wrap.c
	cp ibis_wrap.c $(srcdir)/ibis_wrap.c
	rm -f swig_wrap.c	

ibissh_wrap.c: @MAINTAINER_MODE_TRUE@ $(SWIG_IFC_FILES)
	swig -I$(srcdir) -dhtml -tcl8  -ltclsh.i -o swig_wrap.c $(srcdir)/ibis.i
	$(srcdir)/fixSwigWrapper -g -s -p -r ibis -o ibissh_wrap.c
	cp ibissh_wrap.c $(srcdir)/ibissh_wrap.c
	rm -f swig_wrap.c
endif

swigclean:
	rm -f $(srcdir)/ibis_wrap.c $(srcdir)/ibissh_wrap.c *wrap.o

# we need there extra in the distribution as their dependency is not defined
EXTRA_DIST = swig_extended_obj.c fixSwigWrapper pkgIndex.tcl

# we do not want the temporary and the archive libs installed:
install-libLTLIBRARIES:

# this actually over write the lib install
install-exec-am: install-binPROGRAMS 
	mkdir -p $(libdir)/ibis$(VERSION)
	cp .libs/libibis.so.$(LIB_FILE_TRIPLET) $(libdir)/ibis$(VERSION)/libibis.so.$(VERSION)
	sed 's/%VERSION%/'$(VERSION)'/' $(srcdir)/pkgIndex.tcl > $(libdir)/ibis$(VERSION)/pkgIndex.tcl

