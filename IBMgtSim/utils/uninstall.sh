#!/bin/bash 
#
# This software is available to you under a choice of one of two
# licenses.  You may choose to be licensed under the terms of the GNU
# General Public License (GPL) Version 2, available at
# <http://www.fsf.org/copyleft/gpl.html>, or the OpenIB.org BSD
# license, available in the LICENSE.TXT file accompanying this
# software.  These details are also available at
# <http://openib.org/license.html>.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# Copyright (c) 2004 Mellanox Technologies Ltd.  All rights reserved.
#

function cleanup_ibmgtsim_files() {
    # Clean old distribution
    binApps="IBMgtSim  ibmsquit  ibmssh  mkSimNodeDir  RunSimTest"

    echo "Removing Executables from : .......... $PREFIX/bin." 
    for f in $binApps; do 
        rm -f ${PREFIX}/bin/$f 2&>1 > /dev/null; 
        if [ $? == 0 ]; then
            echo " Removed : ${PREFIX}/bin/$f" 
        fi
    done
   
    echo "Removing Include Files from : ........ $PREFIX/include."
    rm -rf ${PREFIX}/include/ibmgtsim 2&>1 > /dev/null
    if [ $? == 0 ]; then
        echo " Removed : ${PREFIX}/include/ibmgtsim" 
    fi
    
    echo "Removing Libs from : ................. $PREFIX/lib."
    libs="libibmscli.a libibmscli.la libibmscli.so libibmscli.so.1 
          libibmscli.so.1.0.0"
    for f in $libs; do 
        rm -rf ${PREFIX}/lib/$f 2&>1 > /dev/null; 
        if [ $? == 0 ]; then
            echo " Removed : ${PREFIX}/lib/$f" 
        fi
    done
}

PREFIX=/usr
NO_BAR=0

# parse parameters
while [ "$1" ]; do
#  echo "Current parsed param is : $1"
  case $1 in
    "--prefix") 
          PREFIX=$2
          shift
          ;;
    *)
     echo "Usage: $0 [--prefix <install-dir>]"
     echo ""
     echo "Options:"
     echo "   --prefix <dir> : the prefix used for the IBMgtSim instalaltion"
     exit 1
  esac
  shift
done

cleanup_ibmgtsim_files
