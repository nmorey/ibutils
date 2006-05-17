dnl This macro checks for the existance of ibis library and defines the 
dnl corresponding path variable
dnl 
dnl Synopsys:
dnl    CHECK_IBIS_TCLLIB()
dnl
dnl Result:
dnl    IBIS_TCLLIB - points to the directory holding the ibisX.Y library
dnl
AC_DEFUN([CHECK_IBIS_TCLLIB],[

dnl Define a way for the user to provide the path
AC_ARG_WITH(ibis-lib,
[  --with-ibis-lib=<dir> define where to find IBIS TCL library],
AC_MSG_NOTICE(IBIS: given path:$with_ibis_lib),
with_ibis_lib="none")

dnl if we were not given a path - try finding one:
if test "x$with_ibis_lib" = xnone; then
   dirs="/usr/lib /usr/local/lib /usr/local/ibgd/lib /usr/local/ibg2/lib /usr/local/ibed/lib /usr/local/ofed/lib"
   for d in $dirs; do
     if test -d $d/ibis1.0; then
        with_ibis_lib=$d
        AC_MSG_NOTICE(IBIS: found in:$with_ibis_lib)
     fi
   for d in $dirs; do
     if test -d $d64/ibis1.0; then
        with_ibis_lib=$d64
        AC_MSG_NOTICE(IBIS: found in:$with_ibis_lib)
     fi
   done
fi

if test "x$libcheck" != "xfalse"; then
   if test "x$with_ibis_lib" = xnone; then
      AC_MSG_ERROR([IBIS: --with-ibis-lib must be provided - fail to find standard IBIS TCL lib installation])
   fi
fi

AC_MSG_NOTICE(IBIS: using TCL lib from:$with_ibis_lib)
AC_SUBST(with_ibis_lib)
])
