dnl This macro checks for the existance of ibis executable and defines the 
dnl corresponding path variable
dnl 
dnl Synopsys:
dnl    CHECK_IBIS_EXEC_DIR()
dnl
dnl Result:
dnl    IBIS_EXEC_DIR - points to the directory holding the ibis executable
dnl
AC_DEFUN([CHECK_IBIS_EXEC_DIR],[

dnl Define a way for the user to provide the path
AC_ARG_WITH(ibis,
[  --with-ibis=<dir> define directory which holds the ibis executable],
AC_MSG_NOTICE(IBIS: given path:$with_ibis),
with_ibis="none")

dnl if we were not given a path - try finding one:
if test "x$with_ibis" = "xnone"; then
   dirs="/usr/bin /usr/local/bin /usr/local/ibgd/bin /usr/local/ibg2/bin /usr/local/ibed/bin /usr/local/ofed/bin"
   for d in $dirs; do
     if test -e $d/ibis; then
        with_ibis=$d
        AC_MSG_NOTICE(IBIS: found in:$with_ibis)
     fi
   done
fi

if test "x$libcheck" != "xfalse"; then
   if test "x$with_ibis" = xnone; then
      AC_MSG_ERROR([IBIS: --with-ibis must be provided - fail to find standard ibis executable file])
   fi
fi

AC_MSG_NOTICE(IBIS: using executable from:$with_ibis)
AC_SUBST(with_ibis)
])
