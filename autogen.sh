#!/bin/bash 
cd ${0%*/*}

# make sure autoconf is up-to-date
ac_ver=`autoconf --version | head -1 | awk '{print $NF}'`
ac_maj=`echo $ac_ver|sed 's/\..*//'`
ac_min=`echo $ac_ver|sed 's/.*\.//'`
if [[ $ac_maj < 2 ]]; then 
    echo Min autoconf version is 2.59
    exit
fi
if [[ $ac_maj = 2 && $ac_min < 59 ]]; then 
    echo Min autoconf version is 2.59
    exit
fi

# make sure automake is up-to-date
am_ver=`automake --version | head -1 | awk '{print $NF}'`
am_maj=`echo $am_ver|sed 's/\..*//'`
am_min=`echo $am_ver|sed 's/.*\.\([^\.]*\)\..*/\1/'`
am_sub=`echo $am_ver|sed 's/.*\.//'`
if [[ $am_maj < 1 ]]; then 
    echo Min automake version is 1.9.3
    exit
fi
if [[ $am_maj = 1 && $am_min < 9 ]]; then 
    echo "automake version is too old:$am_maj.$am_min.$am_sub < required 1.9.3"
    exit
fi
if [[ $am_maj = 1 && $am_min = 9 && $am_sub < 3 ]]; then 
    echo "automake version is too old:$am_maj.$am_min.$am_sub < required 1.9.3"
    exit
fi

# make sure libtool is up-to-date
lt_ver=`libtool --version | head -1 | awk '{print $4}'`
lt_maj=`echo $lt_ver|sed 's/\..*//'`
lt_min=`echo $lt_ver|sed 's/.*\.\([^\.]*\)\..*/\1/'`
lt_sub=`echo $lt_ver|sed 's/.*\.//'`
if [[ $lt_maj < 1 ]]; then 
    echo Min libtool version is 1.4.2
    exit
fi
if [[ $lt_maj = 1 && $lt_min < 4 ]]; then 
    echo "automake version is too old:$lt_maj.$lt_min.$lt_sub < required 1.4.2"
    exit
fi
if [[ $lt_maj = 1 && $lt_min = 4 && $lt_sub < 2 ]]; then 
    echo "automake version is too old:$lt_maj.$lt_min.$lt_sub < required 1.4.2"
    exit
fi

# cleanup
find . \( -name Makefile.in -o -name aclocal.m4 -o -name autom4te.cache -o -name configure -o -name aclocal.m4 \) -exec \rm -rf {} \; -prune

# handle our own autoconf:
aclocal -I config 2>&1 |  grep -v "arning: underquoted definition of"
automake --add-missing --gnu --copy --force
autoconf

# visit all sub directories with autogen.sh    
anyErr=0
for a in `ls */autogen.sh`; do
    echo Visiting $a
    $a 2>&1 | sed 's/^/|/'
    if test $? != 0; then
        echo $a failed
        anyErr=1
    fi
done

exit $anyErr
