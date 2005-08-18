
dnl osm.m4: an autoconf for OpenSM (vendor and complib) reference
dnl
dnl
dnl To use this macro, just do OPENIB_APP_OSM.  
dnl The following variables are defined:
dnl with-osm - the osm installation prefix
dnl OSM_CFLAGS - CFLAGS additions required (-I and debug )
dnl OSM_LDFLAGS - a variable holding link directives
dnl OSM_VENDOR - The type of vendor library available (ts, sim)
dnl OSM_STACK - either gen1 or openib
dnl
dnl Several conditionals are also defined:
dnl OSM_STACK_OPENIB - set when the stack is openib (gen2)
dnl OSM_VENDOR_TS - should use gen1/gen2 API
dnl OSM_VENDOR_SIM - interface a simulator vendor
dnl If successful, these have stuff in them.  If not, they're empty.
dnl If not successful, with_osm has the value "no".

AC_DEFUN([OPENIB_APP_OSM], [
# --- BEGIN OPENIB_APP_OSM ---
dnl To link against OpenSM Vendor or Complib, configure does several
dnl things to make my life "easier".
dnl
dnl * if the user did define where opensm is look for it in "standard" places
dnl * if can not be found - ask the user for --with-osm
dnl * figure out if OpenSM was compiles in debug mode or not
dnl

dnl Define a way for the user to provide path to OpenSM 
AC_ARG_WITH(osm,
[  --with-osm=<dir> define where to find OSM],
AC_MSG_NOTICE(Using OSM from:$with_osm),
with_osm="none")

dnl if the user did not provide --with-osm look for it in reasonable places
if test "x$with_osm" = xnone; then 
   if test -d /usr/local/ibgd/apps/osm; then
      with_osm=/usr/local/ibgd/apps/osm
   elif test -d /usr/mellanox/osm; then
      with_osm=/usr/mellanox
   elif test -d /usr/local/include/infiniband; then
      with_osm=/usr/local
      OSM_STACK=openib
   else
      AC_MSG_ERROR([--with-osm must be provided - fail to find standard OpenSM installation])
   fi
   AC_MSG_NOTICE(Found OSM in:$with_osm)
else
   if test -d $with_osm/include/infiniband; then
      OSM_STACK=openib
   fi
fi

OSM_LDFLAGS="-Wl,-rpath -Wl,$with_osm/lib -L$with_osm/lib"
dnl based on the with_osm dir we can try and decide what vendor was used:
if test -f $with_osm/lib/libosmsvc_ts.so; then
   OSM_VENDOR=ts
   OSM_STACK=gen1
   OSM_LDFLAGS="$OSM_LDFLAGS -losmsvc_ts -lcomplib"
   osm_vendor_sel="-DOSM_VENDOR_INTF_TS"
elif test -f $with_osm/lib/libosmsvc_mtl.so; then
   OSM_VENDOR=mtl
   OSM_STACK=gen1
   OSM_LDFLAGS="$OSM_LDFLAGS -losmsvc_mtl -lcomplib " 
   osm_vendor_sel="-DOSM_VENDOR_INTF_MTL"
elif test -f $with_osm/lib/libosmsvc_sim.so; then
   OSM_STACK=gen1
   OSM_VENDOR=sim
   OSM_LDFLAGS="$OSM_LDFLAGS -losmsvc_sim -lcomplib"
   osm_vendor_sel="-DOSM_VENDOR_INTF_SIM"
elif test -f $with_osm/lib/libosmvendor.a; then
   OSM_VENDOR=ts
   osm_vendor_sel="-DOSM_VENDOR_INTF_OPENIB"
   OSM_LDFLAGS="$OSM_LDFLAGS -lopensm -losmvendor -losmcomp -libcommon"
else
   AC_MSG_ERROR([fail to find any valid OSM vendor library in $with_osm/lib])
fi

AM_CONDITIONAL(OSM_VENDOR_TS, test $OSM_VENDOR = ts)
AM_CONDITIONAL(OSM_VENDOR_MTL, test $OSM_VENDOR = mtl)
AM_CONDITIONAL(OSM_VENDOR_SIM, test $OSM_VENDOR = sim)
AM_CONDITIONAL(OSM_STACK_OPENIB, test $OSM_STACK = openib)

dnl the header file should have the string debug if OpenSM is debug mode:
if test $OSM_STACK = openib; then
   osm_include_dir="$with_osm/include/infiniband"
else
   osm_include_dir="$with_osm/include"
fi

dnl validate the defined path
AC_CHECK_FILE($osm_include_dir/opensm/osm_build_id.h,,
   AC_MSG_ERROR([ could not find $with_osm/include/opensm/osm_build_id.h]))

dnl now figure out somehow if the build was for debug or not

if test `grep debug $osm_include_dir/opensm/osm_build_id.h | wc -l` = 1; then
   dnl why did they need so many ???
   osm_debug_flags='-DDEBUG -D_DEBUG -D_DEBUG_ -DDBG'
   AC_MSG_NOTICE(OSM compiled in DEBUG mode)
else
   osm_debug_flags=
fi

OSM_CFLAGS="-I$osm_include_dir $osm_debug_flags $osm_vendor_sel -D_XOPEN_SOURCE=600 -D_BSD_SOURCE=1"

AC_SUBST(with_osm)
AC_SUBST(OSM_CFLAGS)
AC_SUBST(OSM_LDFLAGS)
AC_SUBST(OSM_VENDOR)
AC_SUBST(OSM_STACK)

# --- OPENIB_APP_OSM ---
]) dnl OPENIB_APP_OSM

