#!/bin/sh 

cd ${0%*/*}
\rm -rf autom4te.cache
\rm -rf aclocal.m4
\rm -f config/missing config/install-sh config/depcomp config/mkinstalldirs config/ltmain.sh config/config.sub config/config.guess
# make sure autoconf is up-to-date
ac_ver=`autoconf --version | head -1 | awk '{print $NF}'`
ac_maj=`echo $ac_ver|sed 's/\..*//'`
ac_min=`echo $ac_ver|sed 's/.*\.//'`
if [[ $ac_maj < 2 ]]; then 
    echo "autoconf version is too old:$ac_maj.$ac_min < required 2.59"
    exit
fi
if [[ $ac_maj = 2 && $ac_min < 59 ]]; then 
    echo "autoconf version is too old:$ac_maj.$ac_min < required 2.59"
    exit
fi
# make sure automake is up-to-date
am_ver=`automake --version | head -1 | awk '{print $NF}'`
am_maj=`echo $am_ver|sed 's/\..*//'`
am_min=`echo $am_ver|sed 's/.*\.\([^\.]*\)\..*/\1/'`
am_sub=`echo $am_ver|sed 's/.*\.//'`
if [[ $am_maj < 1 ]]; then 
    echo Min automake version is 1.9.2
    exit
fi
if [[ $am_maj = 1 && $am_min < 9 ]]; then 
    echo "automake version is too old:$am_maj.$am_min.$am_sub < required 1.9.2"
    exit
fi
if [[ $am_maj = 1 && $am_min = 9 && $am_sub < 2 ]]; then 
    echo "automake version is too old:$am_maj.$am_min.$am_sub < required 1.9.2"
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

aclocal -I config 2>&1 | grep -v "warning: underquoted definition "
libtoolize --automake --copy --force 
automake --add-missing --copy --gnu --force
autoconf
