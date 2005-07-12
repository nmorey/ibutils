
dnl osm.m4: an autoconf for OpenSM (vendor and complib) reference
dnl
dnl
dnl To use this macro, just do OPENIB_APP_OSM.  It outputs
dnl with-osm, and OSM_DEBUG_FLAGS.  
dnl If successful, these have stuff in them.  If not, they're empty.
dnl If not successful, with_osm has the value "no".

AC_DEFUN([OPENIB_APP_OSM], [
# --- BEGIN OPENIB_APP_OSM ---
dnl To link against OpenSM Vendor or Complib, configure does several things to make my life
dnl "easier".
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
   else
      AC_MSG_ERROR([--with-osm must be provided - failde to find standard OpenSM installation])
   fi
fi

dnl validate the defined path
AC_CHECK_FILE($with_osm/include/opensm/osm_build_id.h,,
   AC_MSG_ERROR([ could not find $with_osm/include/opensm/osm_build_id.h]))

AC_SUBST(with_osm)

dnl now figure out somehow if the build was for debug or not
dnl the header file should have the string debug if OpenSM is debug mode:
if test `grep debug $with_osm/include/opensm/osm_build_id.h | wc -l` = 1; then
   dnl why did they need so many ???
   OSM_DEBUG_FLAGS='-DDEBUG -D_DEBUG -D_DEBUG_ -DDBG'
   AC_MSG_NOTICE(OSM compiled in DEBUG mode)
else
   OSM_DEBUG_FLAGS=
fi
AC_SUBST(OSM_DEBUG_FLAGS)

# --- OPENIB_APP_OSM ---
]) dnl OPENIB_APP_OSM

