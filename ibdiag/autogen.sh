#!/bin/bash

# We change dir since the later utilities assume to work in the project dir
cd ${0%*/*}
# remove previous
\rm -rf autom4te.cache
\rm -rf aclocal.m4
# make sure autoconf is up-to-date
ac_ver=`autoconf --version | head -n 1 | awk '{print $NF}'`
ac_maj=`echo $ac_ver|sed 's/\..*//'`
ac_min=`echo $ac_ver|sed 's/.*\.//'`
if [[ $ac_maj -lt 2 ]]; then
    echo Min autoconf version is 2.59
    exit 1
elif [[ $ac_maj -eq 2 && $ac_min -lt 59 ]]; then
    echo Min autoconf version is 2.59
    exit 1
fi
# make sure automake is up-to-date
am_ver=`automake --version | head -n 1 | awk '{print $NF}'`
am_maj=`echo $am_ver|sed 's/\..*//'`
am_min=`echo $am_ver|sed 's/[^\.]*\.\([^\.]*\)\.*.*/\1/'`
am_sub=`echo $am_ver|sed 's/[^\.]*\.[^\.]*\.*//'`
if [[ $am_maj -lt 1 ]]; then
    echo Min automake version is 1.9.2
    exit 1
elif [[ $am_maj -eq 1 && $am_min -lt 9 ]]; then
    echo "automake version is too old:$am_maj.$am_min.$am_sub < required 1.9.2"
    exit 1
elif [[ $am_maj -eq 1 && $am_min -eq 9 && $am_sub -lt 2 ]]; then
    echo "automake version is too old:$am_maj.$am_min.$am_sub < required 1.9.2"
    exit 1
fi
# make sure libtool is up-to-date
lt_ver=`libtool --version | head -n 1 | awk '{print $4}'`
lt_maj=`echo $lt_ver|sed 's/\..*//'`
lt_min=`echo $lt_ver|sed 's/[^\.]*\.\([^\.]*\)\.*.*/\1/'`
lt_sub=`echo $lt_ver|sed 's/[^\.]*\.[^\.]*\.*//'`
if [[ $lt_maj -lt 1 ]]; then
    echo Min libtool version is 1.4.2
    exit 1
elif [[ $lt_maj -eq 1 && $lt_min -lt 4 ]]; then
    echo "libtool version is too old:$lt_maj.$lt_min.$lt_sub < required 1.4.2"
    exit 1
elif [[ $lt_maj -eq 1 && $lt_min -eq 4 && $lt_sub -lt 2 ]]; then
    echo "libtool version is too old:$lt_maj.$lt_min.$lt_sub < required 1.4.2"
    exit 1
fi

aclocal -I config 2>&1 | grep -v "warning: underquoted definition "
libtoolize --automake
automake --add-missing --gnu
autoconf
