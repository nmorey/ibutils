######################################################################
#
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
# $Id: node.h,v 1.23 2005/07/07 21:15:29 eitan Exp $
#
######################################################################

##############################
set G(version.num) 1.1.0rc2
##############################

### TODO: beautify-tcl-buffer macro...

######################################################################
### List of procs
##############################
### GENERAL PURPOSE PROCs
##############################
# bgerror
# wordInList
# wordAfterFlag
# bar
# zeroesPad
# zeroesErase
# hex2bin
# guidsDifferBy1
# parseOptionsList
# debug
##############################
### Sending MADs
##############################
# smMadGetByDr
# pmListGet
##############################
### Handling bad links
##############################
# pathIsBad
# detectBadLinks
# comparePMCounters
# badLinksUserInform
##############################
### Farbic Discovery
##############################
# discoverFabric
# checkDuplicateGuids
# checkBadLidsGuids
# discoverHiddenFabric
# discoverPath
# rereadLongPaths
##############################
### handling topology file
##############################
# matchTopology
# reportTopologyMatching
# linkNamesGet
# getArgvPortNames
# name2Lid
# reportFabQualities
##############################
### format fabric info
##############################
# lstGetParamValue
# linkAtPathEnd
# lstInfo
# write.lstFile
# write.fdbsFile
# write.mcfdbsFile
##############################
### Initial and final actions
##############################
# startIBDebug
# listG
# finishIBDebug
######################################################################


######################################################################
### General Settings
set G(tool) [file rootname [file tail $argv0]]
source [file join [file dirname [info script]] ibdebug_if.tcl]
set G(start.clock.seconds) [clock seconds]
set G(detect.bad.links) 0
set G(argv,debug) [expr [lsearch -exact $argv "--debug"] >= 0 ]
fconfigure stdout -buffering none

### configuration of constants
set G(config,badpath,maxnErrors)	3
set G(config,badpath,retriesStart)	100
set G(config,badpath,retriesEnd)	10000
set G(config,badpath,retriesGrowth)	10
# if topology matching results have more lines than the foillowing constant,
# notify the user that his cluster is messed up
set G(config,warn.long.matchig.results)	20
# The largest value for integer-valued parameters
set G(config,maximal.integer)	1000000
######################################################################


######################################################################
### GENERAL PURPOSE PROCs
######################################################################
proc bgerror args {
   global errorInfo
   puts "$args $errorInfo"
}
##############################
#  SYNOPSIS	wordInList word list 
#  FUNCTION	Indicates whether $word is a word in $list
#  INPUTS	a string $word and a list $list#
#  OUTPUT	1 or 0 - if $word is or isn't a word in $list (resp.)
proc wordInList { word list } {
    return [expr [lsearch -exact $list $word] >= 0 ] 
}
##############################

##############################
#  SYNOPSIS	RemoveElementFromList  
#  FUNCTION	remove an entry from a list
#  INPUTS	original list _word and the unrequierd entry _element
#  OUTPUT	the orignal list if if $_element isn't in $_list.
proc RemoveElementFromList {_list _element } {
    set tmpIndex [lsearch -exact $_list $_element]
    if {$tmpIndex == -1} { return $_list}
    return [lreplace $_list $tmpIndex $tmpIndex]
}
##############################

##############################
#  SYNOPSIS	wordAfterFlag list flag 
#  FUNCTION	Returns the entry in $list that is right after $flag (if exists)
#  INPUTS	a list $list and a string $flag
#  OUTPUT	a srting, which is the word in $list which is right after $flag 
#		- if exists - if not, the empty string is returned.
proc wordAfterFlag { list flag } {
    if {[set index [expr [lsearch -exac $list $flag] +1]]} { 
	return [lindex $list $index]
    }
    return
}
##############################

##############################
#  SYNOPSIS	bar char length 
#  FUNCTION	Return a string made of $length times $char
#  INPUTS	a string $char and an integer $length
#  OUTPUT	a srting, which is made of $length times duplicates of $char
proc bar { char length } {
    return [string repeat $char $length]
}
##############################

##############################
#  SYNOPSIS	zeroesPad num length 
#  FUNCTION	adds zeroes to the LHS of $number for it to be of string length
#		$length
#  INPUTS	a number $num and an integer $length
#  OUTPUT	a srting, of length $length made of padding $num with zeroes on
#		the LHS.If the length of $num is greater than $length, 
#		the procedure will return $num.
proc zeroesPad { num length } {
    return "[bar 0 [expr $length - [string length $num]]]$num"
}
##############################

##############################
#  SYNOPSIS	zeroesErase num
#  FUNCTION	erase all zeroes at the LHS of $num. The number "0" returns "0"
#		(and not "")
#  INPUTS	an integer $length
#  OUTPUT	a number, that is made of erasing all zeroes at the LHS of $num.
#		If $num == 0, the procedure returns 0
proc zeroesErase { num } {
    regsub {^0*(.+)$} $num {\1} num
    return $num
}
##############################

##############################
#  SYNOPSIS	hex2bin hex_list 
#  FUNCTION	turns a list of hexa munbers into a list of binary numbers
#  INPUTS	a list $list of hexadecimal numbers
#  OUTPUT	a list, which is made of the numbers of $list, represented in 
#		Binary base.
proc hex2bin { hex_list } {
    set bin_list ""
    array set hexbit2bin { 
	0 0000  1 0001  2 0010  3 0011
	4 0100  5 0101  6 0110  7 0111
	8 1000  9 1001  a 1010  b 1011
	c 1100  d 1100  e 1110  f 1111
    }
    foreach hex $hex_list {
	regsub {^0x} [string tolower $hex] {} hex
	set bin ""
	foreach hbit [split $hex ""] { 
	    append bin $hexbit2bin($hbit)
	}
	lappend bin_list $bin
    }
    return $bin_list
}
##############################

##############################
#  SYNOPSIS	guidsDifferBy1 guid0 guid1
#  FUNCTION	tells whether the (64 bit) guids differ by 1
#  INPUTS	two guids - in hexa, with at most 16 hexa digits
#  OUTPUT	0/1 - according to whether the guids do/don't differ by 1
proc guidsDifferBy1 { guid0 guid1 } { 
    set len 16
    # first we format the guids: 
    # remove the prefix "0x" and make their length $len
    regsub {0x} $guid0 {} guid0
    regsub {0x} $guid1 {} guid1
    set guid0 [zeroesPad $guid0 $len]
    set guid1 [zeroesPad $guid1 $len]

    # then we swap the guids is $guid0 > $guid1
    for { set i 0 } { $i < $len } { incr i } { 
	set diff [expr 0x[string index $guid0 $i] - 0x[string index $guid1 $i]]
	if { $diff > 0 } { scan "$guid1 $guid0" "%s %s" guid0 guid1 }
	if { $diff != 0 } { break }
    }

    # finally, we check if $guid0 + 1 == $guid1
    set carry 1
    for { set i [expr $len -1] } { $i >= 0 } { incr i -1} { 
	set diff [expr 0x[string index $guid0 $i] + $carry \
		      - 0x[string index $guid1 $i]]
	if {[expr $diff % 0x10]} { return 0 }
	set carry [expr $diff == 0x10]
    }
    return 1
}
##############################

##############################
#  SYNOPSIS	parseOptionsList list 
#  FUNCTION	defines the database (in uplevel) bearing the values of the
#		options in a list
#  INPUTS	a list $list of options (= strings starting with "-") and their
#		values
#  OUTPUT	NULL
#  RESULT	the array $cfg() is defined in the level calling the procedure.
#		$cfg(option) is the value of the option
proc parseOptionsList { list } { 
    catch { uplevel unset cfg }
    set cfgArrayList ""
    while { [llength $list] > 0 } {
	set flag  [lindex $list 0]
	set value [list [lindex $list 1]]
	set list  [lreplace $list 0 1]
	if {[regexp {^\-([^ ]+)$} $flag . flag ]} { 
	    lappend cfgArrayList "$flag" "$value"
	} else { 
	    return -code 1 -errorcode $flag
	}
    }
    uplevel array set cfg \"$cfgArrayList\"
    return
}
##############################

##############################
#  SYNOPSIS	
#	debug msgId args 
#  FUNCTION	
#	provides verbosity for tool's debug
#  INPUTS	
#	$msgId - message id (I usually use the line number in the script)
#	$args - a list of arguments which may be any of the kind:
#	- names of variables
#	- commands to run
#	- the special argument "-header"
#  OUTPUT	NULL
#  DATAMODEL	
#	the proc uses the global variable $G(argv,debug) - indicating
#	whether we are running in debug mode
#  RESULT: TODO: fix this
#	writes a message to the standard output, according to $type 
#	(and to the file ${tool}.dbg ??)
#	if type=="header", write the calling proc's name and values of arguments
#	if type=="vars", write the names and values of variables denoted by $args
#	otherwise, write the message $type with optional printing parameters 
#	(e.g., "-nonewline") $args
proc debug { msgId args } {
    global G
    if { ! $G(argv,debug) } { return }
    # set args [lsort -dictionary $args]

    set srcProcName [procName 1]
    set message "-D- $msgId $srcProcName"
    if {[regsub " -header " " $args " { } args ]} {
	append message " header:"
	set varNames [concat [info args $srcProcName] $args]
    } else {
	append message ":"
	set varNames $args
    }
    foreach var $varNames {
	catch { unset value }
	catch { set value [uplevel set . [join $var]] }
	catch { set value [uplevel set . $$var] }
	catch { regsub {^\$} $value {} value }
	if { ! [info exists value] } { 
	    continue 
	} elseif { $var == $value } { 
	    continue 
	} elseif { $var == "args" } {
	    append message " $var = $value (len=[llength $value]);"
	} else {
	    append message " $var = $value ;"
	}
    }
    puts "$message"
    return
}
##############################

##############################
#  SYNOPSIS	procName args (<- args may be a positive integer)
#  FUNCTION	Return the name of the calling proc 
#  INPUTS	optinally - a positive integer
#  OUTPUT	the name of the calling proc 
#		(if $args != "" -> the name of the calling proc $args levels up)
proc procName { args } {
    set upLevels 0
    if { $args != "" } { set upLevels $args }
    return [lindex [info level [expr [info level] -1 -$upLevels]] 0]
}
######################################################################

##############################
#  SYNOPSIS	listG
#  FUNCTION	displays (compactly) the entries in the global vars array G
#		if the --G flag was specified in the comand line.
#		This is used for debug purposes.
#		Ran from finishIBDebug.
#  INPUTS	NULL
#  OUTPUT	NULL
proc listG {} {
    global G argv
    if { ! [wordInList "--G" $argv] } { return }
    set Glist ""
    foreach entry [lsort [array names G]] { 
	regsub {,[^,]*$} $entry {,*} head1
	regsub {,[^,]*$} [lindex $Glist end] {,*} head0
	regsub {^PortInfo,[0-9a-fx]+,\*} $head1 {PortInfo,*,*} head1
	regsub {^PortInfo,[0-9a-fx]+,\*} $head0 {PortInfo,*,*} head0
	if { "$head0" == "$head1" } { set Glist [lreplace $Glist en end $head1]
	} else { lappend Glist "$entry" }
    }
    puts "-G- G entries: [join [lsort $Glist] "; "]"
    return
}
##############################
proc initOutfile { } {
    global G 
    regsub {File$} [file extension [procName 1]] {} ext
    set outfile $G(outfiles,$ext)
    if { [file exists $outfile] && ! [file writable $outfile] } {
	inform "-W-outfile:not.writable" -file0 $outfile -file1 $outfile.[pid]
	append G(outfiles,$ext) ".[pid]"
    }
    inform "-V-outfiles:$ext"
    return [open $G(outfiles,$ext) w]
}
##############################

######################################################################
### Sending queries (MADs and pmGetPortCounters) over the fabric
######################################################################

##############################
#  SYNOPSIS	
#	smMadGetByDr mad cget args
#  FUNCTION	
#	returns the info of the Direct Route Mad: sm${cmd}Mad getByDr $args.
#	Getting MAD info should always be done using this proc 
#	- since it MAD sending handles failures
#  INPUTS	
#	$mad - the type of MAD to be sent - e.g., NodeInfo, PortInfo, etc.
#	$cget - the requested field of the mad ("dump" returns the all mad info)
#	$args - the direct route (and, optionally, the port) for sending the MAD
#  OUTPUT	
#	the relevant field (or - all fields) of the MAD info
#  DATAMODEL	
#	the proc uses $G(argv,failed.retry) - for stopping failed retries 
#	and $G(detect.bad.links) to decide whether to run detectBadLinks
proc smMadGetByDr { mad cget args } {
    # TODO: with each MAD sending, report to statistic gathering about number of
    # successes/fails
    global G
    # Setting the send and cget commands
    set getCmd [concat "sm${mad}Mad getByDr $args"]
    if [regexp {^-} $cget] {
        set cgetCmd "sm${mad}Mad cget $cget"
    } else {
        set cgetCmd "sm${mad}Mad $cget"
    }
    # Sending the mads (with up to $G(argv,failed.retry) retries)
    inform "-V-mad:sent" -command "$getCmd"
    set status -1
    for { set retry 0 } { $retry < $G(argv,failed.retry) } { incr retry } { 
	if { [set status [eval $getCmd]] == 0 } { incr retry ; break }
    }
    inform "-V-mad:received" -status $status -attempts $retry

    # handling the results
    if { $G(detect.bad.links) && ( $retry > 1 ) } {
        # the following command may fail -> then proc will return with code 1
        return [detectBadLinks $status "$cgetCmd" $mad $args]
    } elseif { $status != 0 } {
        return -code 1 -errorcode $status
    } else {
        set res [eval $cgetCmd]
        return $res
    }
}
##############################

##############################
#  SYNOPSIS	
#	pmListGet Lid:Port
#  FUNCTION	
#	returns the info of PM info request : pmGetPortCounters $Lid $Port
#  INPUTS	
#	$LidPort - the lid and port number for the pm info request
#		format: lid:port (the semicolon - historic)
#  OUTPUT	
#	the relevant PM (Performance Monitors) info for the $port at $lid
#  DATAMODEL	
#	the proc uses $G(argv,failed.retry) - for stopping failed retries 
proc pmListGet { LidPort } {
    global G

    # Setting Lid, Port and the pm command
    regexp {^(.*):(.*)$} $LidPort D Lid Port
    if { $Lid == 0 } { return }
    set cmd [concat "pmGetPortCounters $Lid $Port"]

    # Sending the pm info request
    inform "-V-mad:sent" -command $cmd
    set pm_list -1
    for { set retry 1 } { $retry <= $G(argv,failed.retry) } { incr retry } { 
	if { [regexp "ERROR" [set pm_list [join [eval $cmd]]]]==0 } { 
	    break 
	}
    }
    inform "-V-mad:received" -attempts $retry

    # handling the results
    if {[regexp "ERROR" $pm_list]} {
	return -code 1 -errorcode 1 -errorinfo "$pm_list"
    } else { 
	return $pm_list
    }
}
######################################################################

######################################################################
### Detecting bad links on a path on which a packet was lost
######################################################################
set G(list,badpaths) ""

##############################
#  SYNOPSIS	
#	pathIsBad path
#  FUNCTION	
#	returns 1 if the direct path $path contains a link that was found to be
#	"bad"; it returns 0 otherwise.
#  INPUTS	
#	$path - a direct path: a list of integers separated by spaces - denoting
#	a direct route in the fabric (= a list of exit ports, starting at the 
#	fabric's source node).
#  OUTPUT	
#	0/1 - according to whether $path has a bad link or not
#  DATAMODEL	
#	the proc uses the database $G(bad,paths,<DirectPath>), which is set in
#	proc detectBadLinks, and that denotes the reasons (errors) why the link
#	at the end of DirectPath was found to be bad.
proc pathIsBad { path } { 
    global G
    for { set i 0 } { $i < [llength $path] } { incr i } { 
	if { [info exists G(bad,paths,[lrange $path 0 $i])] } { return 1 }
    }
    return 0
}
##############################

##############################
#  SYNOPSIS	
#	detectBadLinks starting cgetCmd cmd args
#  FUNCTION	
#	Explores the direct route on which $cmd failed, and detects bad link(s)
#	along this path.
#	The exploration algorithm:... TODO: fill this in ...
#	The bad are then written to the database $G(bad,links,*).
#	This proc is called by the proc "smMadGetByDr", when the global variable 
#	$G(detect.bad.links) is set.
#  INPUTS	
#	$status - the last exit status of $cmd
#	$cgetCmd - the command that returns the result of $cmd
#	$cmd - the name of the command that failed
#	$args - the arguments of $cmd
#  OUTPUT	
#	the result data of running $cmd $args - if available;
#	if the data in not available, returns with error code 1.
#  DATAMODEL	
#	$G(config,badpath,*) - a database used, which defines various
#	 parameters for the bad paths exploration: limits and growth rate for
#	 the retries of trying to run $cmd $args and error threshold to stop it.
#	$G(bad,paths,<DirectPath>) - a database used, that denotes the reasons
#	 (errors) why the link at the end of DirectPath was found to be bad.
#	$G(list,badpaths) - a database updated by the proc. It is the list of 
# 	 bad paths. I need this list, in addition to [array names G bad,paths,*],
#	 because it will be used in proc "discoverHiddenFabric".
#	$InfoPm(<PM>) - the width-in-bits of each PM and its error threshold

proc detectBadLinks { status cgetCmd cmd args } { 
    # debug "476" -header
    global G env
    set args [join $args]
    set DirectPath [join [lindex $args 0]]
    if  {$status == 0}  { set data [eval $cgetCmd] }
    inform "-V-ibdiagnet:detect.bad.links" -path "$DirectPath"

    # preparing database for reading PMs
    set LidPortList ""
    for { set I 0 } { $I < [llength $DirectPath] } { incr I } {
	set ShortPath [lrange $DirectPath 0 $I]
	if {[info exists G(bad,paths,$ShortPath)]} { break } 
	set path0 [lreplace $ShortPath end end]
	set port0 [lindex $ShortPath end]
	if {![catch {set LID0 [lstGetParamValue LID $path0 $port0 -noread]}]} { 
	    if { $LID0 != 0 } { lappend LidPortList "$LID0:$port0:$ShortPath" }
	}
	set path1 $ShortPath
	catch { unset port1 }
	catch { set port1 [lstGetParamValue PortNum $ShortPath -noread] }
	if {![catch {set LID1 [lstGetParamValue LID $path1 $port1 -noread]}]} { 
	    if { $LID1 != 0 } { lappend LidPortList "$LID1:$port1:$ShortPath" }
	}
    }

    # Initial reading of Performance Counters
    foreach LidPortPath $LidPortList {
	set LidPort [join [lrange [split $LidPortPath :] 0 1] :]
	catch { set oldValues($LidPort) [join [pmListGet $LidPort]] }
    }
    
    # setting retriesStart, retriesEnd, maxnErrors, retriesGrowth
    foreach entry [array names G config,badpath,*] {
	set name [lindex [split $entry ,] end]
	set $name $G($entry)
    }

    inform "-V-ibdiagnet:incremental.bad.links" -path "$DirectPath"
    for	{ set maxnRetries $retriesStart ; set errors 0 } \
	{ ( $maxnRetries <= $retriesEnd ) && ( $errors < $maxnErrors ) } \
	{ set maxnRetries [expr $maxnRetries * $retriesGrowth] } {
	    # This loop (2nd) stops when some error occurs, or
	    for { set I 0 ; set errors 0 } \
		{ ($I < [llength $DirectPath]) && ($errors == 0) } \
		{ incr I } \
		{
		    set ShortPath [lrange $DirectPath 0 $I]
		    set getCmd [concat "smNodeInfoMad getByDr [list $ShortPath]"]
		    if {[info exists G(bad,paths,$ShortPath)]} { break }
		    for { set retry 0 }\
			{ ($retry < $maxnRetries) && ($errors < $maxnErrors) }\
			{ incr retry } {
			    incr errors [expr [eval $getCmd] != 0]
			}
		    if { ($ShortPath==$DirectPath) && ($retry>$errors)} {
			set data [eval $cgetCmd]
		    }
		}
	}

    # Final reading of Performance Counters
    foreach LidPortPath $LidPortList {
	regexp {^([^:]+):([^:]+):([^:]+)$} $LidPortPath . Lid Port Path
	if {[info exists G(bad,paths,$Path)]} { break }
	if {[catch { set newValues [join [pmListGet $Lid:$Port]] }]} { continue }
	foreach entry [comparePMCounters $oldValues($Lid:$Port) $newValues] {
	    if { ! [wordInList "$Path" $G(list,badpaths)] } {
		lappend G(list,badpaths) $Path
	    }
	    scan $entry {%s %s %s} parameter err value
	    # TODO: reformat the error info for the bad links
	    switch -exact -- $err {
		"valueChange" {
		    set cmd [concat "pmGetPortCounters $Lid $Port"]
		    lappend G(bad,paths,$Path) \
			"-error badPMs -PMcounter $parameter -valueChange $value -command \{$cmd\}"
		}
		"overflow" {
		    lappend G(bad,paths,$Path) "-error badPMs -PMcounter $parameter value-overflow=$value"
		}
	    }
	}
    }

    # If errors count did not reach $maxnErrors, the path is considered to be OK
    if { $errors < $maxnErrors } { return $data }

    # If it did - the link at the end of ShortPath is "bad"
    if { [llength $ShortPath] <= 1 } {
	if { ( $retry == $errors ) } {
	    inform "-E-discover:local.port.crashed" -command "$getCmd"
	} else {
	    inform "-E-discover:local.port.failed" \
		-fails "$errors" -attempts $retry -command "$getCmd"
	}
    }

    if { ( $retry == $errors ) } {
	lappend G(bad,paths,$ShortPath) "-error noInfo -command \{$getCmd\}"
	inform "-V-badPathRegister" -error noInfo -command "$getCmd"
    } else {
	lappend G(bad,paths,$ShortPath) \
	    "-error madsLost -ratio $errors:$retry -command \{$getCmd\}"
    }
    if { ! [wordInList "$ShortPath" $G(list,badpaths)] } {
	lappend G(list,badpaths) $ShortPath
    }
    return $data
}
######################################################################

proc comparePMCounters { oldValues newValues args } {
    global G

    array set InfoPm { 
	port_select			{ -width 8  -thresh 0  }
	counter_select			{ -width 16 -thresh 0  }
	symbol_error_counter		{ -width 16 -thresh 30 }
	link_error_recovery_counter	{ -width 8  -thresh 10 }
	link_down_counter		{ -width 8  -thresh 5  }
	port_rcv_errors			{ -width 16 -thresh 10 }
	port_rcv_remote_physical_errors { -width 16 -thresh 10 }
	port_rcv_switch_relay_errors	{ -width 16 -thresh 0  }
	port_xmit_discard		{ -width 16 -thresh 10 }
	port_xmit_constraint_errors	{ -width 8  -thresh 10 }
	port_rcv_constraint_errors	{ -width 8  -thresh 10 }
	local_link_integrity_errors	{ -width 4  -thresh 10 }
	excesive_buffer_errors		{ -width 4  -thresh 10 }
	vl15_dropped			{ -width 16 -thresh 10 }
	port_xmit_data			{ -width 32 -thresh 0  }
	port_rcv_data			{ -width 32 -thresh 0  }
	port_xmit_pkts			{ -width 32 -thresh 0  }
	port_rcv_pkts			{ -width 32 -thresh 0  }
    }

    set errList ""
	
    foreach parameter [array names InfoPm] {
	parseOptionsList $InfoPm($parameter)
	if { ! [info exists cfg(thresh)] } { continue }
	if { $cfg(thresh) == 0 } { continue }

	set oldValue	[wordAfterFlag $oldValues $parameter]
	set newValue	[wordAfterFlag $newValues $parameter]
	set delta	[expr $newValue - $oldValue]
	set overflow	0x[bar f [expr $cfg(width) / 4]]

	if { ( $delta > $cfg(thresh) ) || ( $oldValue > $newValue ) } {
	    lappend errList "$parameter valueChange $oldValue->$newValue"
	} elseif { ( $oldValue == $overflow ) || ( $newValue == $overflow ) } {
	    lappend errList "$parameter overflow $overflow"
	}
    }
    return $errList
}

##############################
#  SYNOPSIS	
#	setNeighbor
#  FUNCTION	
#	setting the Neighbor info on the two end node 
#  INPUTS	
#	_directPath _nodeGuid _entryPort 
#  OUTPUT	
#       return 0/1 if Neighbor exists/not exists (resp.)
#  DATAMODEL	
#   G(Neighbor,<NodeGuid>:<PN>) 
proc setNeighbor {_directPath _nodeGuid _entryPort} {
    global G
    set previousDirectPath [lrange $_directPath 0 end-1]
    set tmpRemoteSidePortGuid $G(GuidByDrPath,$previousDirectPath)
    set tmpRemoteSideNodeGuid $G(NodeGuid,$tmpRemoteSidePortGuid)
    if {[info exists G(Neighbor,$_nodeGuid:$_entryPort)]} {
        return 0
    }
    if {[info exists G(Neighbor,$tmpRemoteSideNodeGuid:[lindex $_directPath end])]} {
        return 0
    }
    set G(Neighbor,$_nodeGuid:$_entryPort) "$tmpRemoteSideNodeGuid:[lindex $_directPath end]"
    set G(Neighbor,$tmpRemoteSideNodeGuid:[lindex $_directPath end]) "$_nodeGuid:$_entryPort"
    return 1
}


##############################
#  SYNOPSIS	
#	badLinksUserInform
#  FUNCTION	
#	Pretty-printing of the bad links information
#  INPUTS	
#	NULL
#  OUTPUT	
#	Prints to the standard output the list of bad links, with proper
#	indentation, and - optionally - with infromation why this link was 
#       found to be bad.
#  DATAMODEL	
#	$G(bad,paths,<DirectPath>) - a database used, that denotes the reasons
#	 (errors) why the link at the end of DirectPath was found to be bad.
proc badLinksUserInform { } { 
    global G

    if { ! [llength [array names G "bad,paths,*"]] } { 
	inform "-I-ibdiagnet:no.bad.paths.header"
	return 
    }
    inform "-I-ibdiagnet:bad.links.header"

    foreach entry [array names G "bad,paths,*"] {
	set DirectPath [lindex [split $entry ,] end]
	if { [set linkNames [linkNamesGet $DirectPath]] == "" } { 
	    set linkNames "Link at the end of direct route \{$DirectPath\}"
	}
	array set BadPathsLinksArray "\{$linkNames\} \{$G($entry)\}"
    }

    ### pretty-printing of a list of links
    set LinksList [array names BadPathsLinksArray]

    foreach item $LinksList { 
	set link [lindex $item end]
	lappend llen [string length [lindex $link 0]] [string length [lindex $link 1]] 
    }
    set maxLen1 [lindex [lsort -integer $llen] end]

    set space(0)	"   "
    set space(1)	[bar " " [string length $space(0)]]
    array set prefix {
	"names:external" "Cable:"
	"names:internal" "Internal link:"
    }
    foreach kind [array names prefix] { 
	lappend prefix_llen [string length $prefix($kind)]
    }
    foreach kind [array names prefix] {
	set maxLen0	 [lindex [lsort -integer $prefix_llen] end]
	set rubberLen0	 [expr $maxLen0 - [string length $prefix($kind)]]
	set space($kind) "$space(0) $prefix($kind)[bar " " $rubberLen0]"
    }
    array set sym { 
	names:external,conn	"="
	names:external,cable	"-"
	names:internal,conn	"."
	names:internal,cable	"."
    }

    foreach item $LinksList { 
	set kind [lindex $item 0]
	set link [lsort -dictionary [lindex $item end]]
	if { [llength $link] == 1 } { lappend link "? (unknown port)" }
	if { ! [regexp {[^ ]} [lindex $link 0]] } { 
	    set link [list [lindex $link 1] "? (unknown port)"]
	}

	if { ! [info exists prefix($kind)] } { ; # then it is not a named link - output it as is
	    lappend portsList "Z.$item"
	    set stdoutList(Z.$item) "$space(0) $item" 
	    set stdoutErrs(Z.$item) $BadPathsLinksArray($item)
	} else { 
	    regsub {^[^\(]*\((.*)\)$} [lindex $link 0] {\1} p0
	    lappend portsList $p0
	    set rubberLen1 [expr $maxLen1 - [string length [lindex $link 0]] + 3]
	    set cable "$sym($kind,conn)[bar $sym($kind,cable) $rubberLen1]$sym($kind,conn)"
	    set stdoutList($p0) "$space($kind) [lindex $link 0] $cable [lindex $link 1]"
	    set stdoutErrs($p0) $BadPathsLinksArray($item)
	}
    }

    set line ""
    foreach item [lsort -dictionary $portsList] {
	if { $line != [set line $stdoutList($item)] } {
	    inform "-I-ibdiagnet:bad.link" -link "$line"
	    inform "-I-ibdiagnet:bad.link.errors" \
		-errors " $space(1) Errors:\n $space(1)  [join $stdoutErrs($item) "\n $space(1)  "]"
	}
    }
    inform "-I-ibdiagnet:bad.links.err.types"
    return
}
######################################################################

######################################################################
### Farbic Discovery
######################################################################

set G(list,DirectPath) { "" }
set G(list,NodeGuids) [list ]
set G(list,PortGuids) [list ]
set G(Counter,SW) 0
set G(Counter,CA) 0
##############################
#  SYNOPSIS	
#	discoverFabric 
#  FUNCTION & DATAMODEL
#	Using a BFS algorithm (staring at the local node), discovers the entire
#	fabric and sets up a few databases:
#       G(list,DirectPath):
#       G(list,NodeGuids):
#       G(list,PortGuids):
#       G(GuidByDrPath,<DirectPath>)    : <PortGuid> 
#       G(DrPathOfGuid,<PortGuid>)      : <DirectPath> 
#       G(PortInfo,<PortGuid>)          : <SmPortInfoMad>
#       G(NodeGuid,<PortGuid>)          : <NodeGuid>
#       G(NodeInfo,<NodeGuid>):         : <smNodeInfoMad>
#       G(NodeDesc,<NodeGuid>)          : 
#       G(PortGuid,<NodeGuid>:<PN>)     : <PortGuid>
#       G(Neighbor,<NodeGuid>:<PN>)     : <NodeGuid>:<PN>
#  INPUTS NULL
#  OUTPUT NULL

proc discoverFabric { } {
    global G
    debug "771" -header
    inform "-V-discover:start.discovery.header"
    set index [expr [llength $G(list,DirectPath)] -1]
    set possibleDuplicatePortGuid 0

    while { $index < [llength $G(list,DirectPath)] } {
        set DirectPath [lindex $G(list,DirectPath) $index]
        incr index
        # if DirectPath, or its son are bad - continue
        if {[pathIsBad $DirectPath]} { continue }
        inform "-V-discover:discovery.status" -index $index -path "$DirectPath"
        inform "-I-discover:discovery.status"
        # Reading NodeInfo across $DirectPath (continue if failed)
        if {[catch {set NodeInfo [smMadGetByDr NodeInfo dump "$DirectPath"]}]} {
            continue
        }

        set NodeGuid [wordAfterFlag $NodeInfo "-node_guid"]
        set PortGuid [wordAfterFlag $NodeInfo "-port_guid"]
        set EntryPort [wordAfterFlag $NodeInfo "-port_num_vendor_id"]
        set EntryPort [format %d [GetEntryPort  $EntryPort]]
        set G(GuidByDrPath,$DirectPath) $PortGuid
        # check for duplicate port guids, and skip to the next loop itteration
        if {[lsearch $G(list,PortGuids) $PortGuid]!= -1} {
            set possibleDuplicatePortGuid 1
            if {$NodeGuid != $G(NodeGuid,$PortGuid)} {
                set name [array name G PortGuid,$G(NodeGuid,$PortGuid):*]
                if {[llength $name ] > 2} {
                    set prePN 0
                } else {
                    set prePN [lindex [split $name :] end]
                }
                inform "-E-discover:duplicated.guids" -guid $PortGuid \
                    -DirectPath0 $G(DrPathOfGuid,$PortGuid) \
                    -DirectPath1 $DirectPath -port_or_node port -PN0 $prePN \
                    -PN1 $EntryPort
            }
        }
        # check for duplicate node guids, and skip to the next loop itteration
        if {[lsearch $G(list,NodeGuids) $NodeGuid]!= -1} {
            # Check if dealing with the same device type
            set boolDuplicateGuidsFound 0
            if {!$possibleDuplicatePortGuid} {
                set tmpPortGuid [lindex [array get G PortGuid,$NodeGuid:*] 1]
                set preDrPath $G(DrPathOfGuid,$tmpPortGuid)
            } else {
                set preDrPath $G(DrPathOfGuid,$PortGuid)
                set possibleDuplicatePortGuid 0
            }
            set type_1 [lstGetParamValue Type $preDrPath -byDr]
            set type_2 [lstGetParamValue Type $DirectPath -byDr]
            if {$type_2 != "SW"} {
                if {$type_1 != $type_2} {
                    puts "\nTYPE"
                    set boolDuplicateGuidsFound 1
                }
                if {[info exists G(Neighbor,$NodeGuid:$EntryPort)]} {
                    puts "\nNeighbor Exists"
                    set boolDuplicateGuidsFound 1
                }
            } elseif {[checkDuplicateGuids $NodeGuid $DirectPath 1]} {
                puts "\nDuplicate Fail"
                set boolDuplicateGuidsFound 1
            }
            if {$boolDuplicateGuidsFound} {
                inform "-E-discover:duplicated.guids" -guid $NodeGuid \
                    -DirectPath0 $preDrPath \
                    -DirectPath1 $DirectPath -port_or_node node
            }
            # check if the new link allready marked - if so removed $DirectPath
            # happens in switch systems and when a switch connects to himself
            if {![setNeighbor $DirectPath $NodeGuid $EntryPort]} {
                set G(list,DirectPath) [RemoveElementFromList $G(list,DirectPath) $DirectPath ]
                unset G(GuidByDrPath,$DirectPath)
                incr index -1
            } else {
                set G(PortGuid,$NodeGuid:$EntryPort) $PortGuid
            }
            continue
        }
        lappend G(list,NodeGuids)  $NodeGuid 
        lappend G(list,PortGuids)  $PortGuid 
        set G(DrPathOfGuid,$PortGuid) $DirectPath
        set G(NodeGuid,$PortGuid) $NodeGuid
        set G(NodeInfo,$NodeGuid) $NodeInfo
        set G(PortGuid,$NodeGuid:$EntryPort) $PortGuid
        set NodeType [lstGetParamValue Type $DirectPath -byDr]
        incr G(Counter,$NodeType)
        # Update Neighbor entry In the Array
        if {[llength $DirectPath] > 0} {
            setNeighbor $DirectPath $NodeGuid $EntryPort
        }
 
        if {[catch {set tmpNodeDesc [smMadGetByDr NodeDesc -description "$DirectPath"]}]} {
            set G(NodeDesc,$NodeGuid) "UNKNOWN"
        } else {
            set G(NodeDesc,$NodeGuid) $tmpNodeDesc
        }
        
        if { $NodeType != "SW" } {
            set PortsList $EntryPort
        } else {
            set Ports [lstGetParamValue Ports $DirectPath -byDr]
            set PortsList ""
            for { set port 0 } { $port <= $Ports } { incr port } {
                lappend PortsList $port
            }
        }

        foreach port $PortsList {
            if {[catch { set G(PortInfo,$NodeGuid:$port) \
                [smMadGetByDr PortInfo dump "$DirectPath" $port]} ]} { 
                    break
                }

        # The loop for non-switch devices ends here.
        # This is also an optimization for switches ..
            if { ( ($index != 1) && ($port == $EntryPort) ) || ($port == 0) } {
                continue
            }
            if { ( [lstGetParamValue LOG $DirectPath $port] == "DWN" ) } {
                if { $index == 1 } { 
                    inform "-E-discover:local.port.down" -port $port
                }
                continue
            }
        # "$DirectPath $port" is added to the DirectPath list only if the
           # device is a switch (or the root HCA), the link at $port is not 
           # DOWN, $port is not 0 and not the entry port 
           lappend G(list,DirectPath) [join "$DirectPath $port"]
        }
    }
    inform "-I-discover:discovery.status"
    inform "-I-exit:\\r"
    inform "-V-discover:end.discovery.header"
    return
}

proc discoverHiddenFabric {} { 
    global G
    debug "1049" -header G(list,badpaths)

    foreach badPath $G(list,badpaths) {
	set allPaths $G(list,DirectPath)
	debug "1046" allPaths badPath
	while {[set idx [lsearch -regexp $allPaths "^$badPath \[0-9\]"]]>=0} {
	    set longerPath [lindex $allPaths $idx]
	    set allPaths [lreplace $allPaths 0 $idx]
	    if {[pathIsBad $longerPath]} { continue }
            set tmpPortGuid $G(GuidByDrPath,$longerPath) 

            if {[catch {set NodeGuid $G(NodeGuid,$tmpPortGuid)}]} { continue }
	    foreach path2guid $G(DrPathOfGuid,$tmpPortGuid) {
		if {[pathIsBad $path2guid]} { continue }
		set GoodPath $path2guid
	    }
	    lappend G(list,DirectPath) $path2guid
	    discoverFabric
	    break
	}
    }
}

# check if the node guid neighbors (by guid) match the 
# neighbors of that node by DR
# _checks is the number of neighbors to check
proc checkDuplicateGuids { _NodeGuid _DirectPath {_checks 1}} { 
    global G 
    set i 0

    # we can not DR out of HCA so we can return 1 anyway
    ## If Checking a HCA, one cannot enter and exit the HCA,
    ### So instead we will run the smNodeInfoMad on the partiel Dr.
    foreach name [array names G Neighbor,$_NodeGuid:*] {
        if {$i >= $_checks} { break }
        incr i
        if {[regexp {Neighbor,0x[0-9a-fA-F]+:([0-9]+)} $name all PN]} {
            lappend portList $PN

            if { [lstGetParamValue LOG $_DirectPath $PN] == "DWN"} {
                #Found A port that once wasn't down and now it isn't
                #return 1
            }
            set NodeInfo [smMadGetByDr NodeInfo dump "$_DirectPath $PN"]
            set NodeGuid [wordAfterFlag $NodeInfo "-node_guid"]
            set EntryPort [format %d [GetEntryPort [wordAfterFlag $NodeInfo "-port_num_vendor_id"] ]]
            if {$G($name) != "$NodeGuid:$EntryPort"} {
                return 1
            }
        }
    }
    return 0
}

proc checkBadLidsGuids { args } {
    global G
    array set valueHash {}

    foreach entry [array names G "DrPathOfGuid,*"] {
        set DirectPath $G($entry)
        if {[pathIsBad $DirectPath]} { continue }

        set NodeGuid [lindex [split $entry ,] end]

        if { [lstGetParamValue Type $DirectPath] == "SW" }  {
	    set allPorts 0
	} else {
	    set allPorts ""
	    foreach item [array name G PortInfo,$NodeGuid:*] {
		lappend allPorts [lindex [split $entry :] end]
	    }
	}
	
        foreach ID "SystemGUID NodeGUID PortGUID LID" {
            switch $ID {
                "SystemGUID" -
                "NodeGUID" {set ListPorts 0 }
                "PortGUID" -
                "LID" {set ListPorts $allPorts}
            }
            foreach port $allPorts {
                set value [lstGetParamValue $ID $DirectPath $port]
                catch {set value [expr $value]}
                lappend valueHash($value:$ID) "$DirectPath:$port"
            }
        }
    }

    ### Checking for zero and duplicate IDs
    foreach entry [lsort [array names valueHash]] {
        regexp {^([^:]*):([^:]*)$} $entry . value ID
        # llength will be diffrent then 1 when duplicate guids acored
        if { ( ( [llength $valueHash($entry)]==1 ) || ( $ID=="SystemGUID" ) ) \
		 && ( $value != 0 ) } {
            continue
	}
        set idx 0
	set paramList ""
        foreach PathPort $valueHash($entry) {
	    regexp {^([^:]*):([^:]*)$} $PathPort . DirectPath port
	    append paramList " -DirectPath${idx} \{$DirectPath\}"
            if { $port != 0 } {
		append paramList " -port${idx} $port"
	    }
	    incr idx
	}
        eval inform "-E-discover:zero/duplicate.IDs.found" -ID $ID -value $value $paramList
    }
}

##############################

##############################
#  SYNOPSIS	
#	discoverPath Path2Start node
#  FUNCTION
#	Traverses a path between two fabric nodes, reading info regarding the 
#	nodes passed, and writing this data into various databases.
#	This proc is used whenever a tool should traverse some path: 
#	ibtrace, ibcfg, ibping,ibmad.
#	The path is defined by its two end points: the source node and the 
#	destination node. The path between the endpoints will be a direct route
#	- in case of by-direct-path-addressing - or lid-route in case of by-name
#	or by-lid addressing.
#  INPUTS 
#	$Path2Start is a direct route to the source node. In case of lid routing
#	it will be a part of the lid route to the destination node.
#	$node points to the destination is specified - either by a Direct route
#	(by-direct-path-addressing), or by LID (by-lid or by-name addressing).
#  OUTPUT
#	A direct route starting at the local node, passing through the source
#	node, ending at the destination node, 
#	that agrees with the addressing mode
#  DATAMODEL
#	Similarly to discoverFabric, the prod uses and updates these arrays 
#	G(NodeInfo,<NodeGuid>)
#	G(list,DirectPath)
#	Additionally, the following database is maintained:
#	G(DrPath2LID,<DirectPath>): 
#		the LID of the entry port at the end of <DirectPath>
#	Also used: G(argv,* ) (= the parsed command line arguments) is used to
#	specify the addressing mode; and the pointer to the merged fabric 
#	G(fabric,merged) (= the ibdm merging of topo file and .lst file)
proc discoverPath { Path2Start node } {
    ### TODO: there is a special case when addressing the local node;
    # for every tool, check that this case is properly treated.
    # ibdiagnet - not relevant
    # ibtrace - OK
    debug "943" -header
    global G errorCode

    if {[set byDrPath [info exists G(argv,direct.route)]]} { 
	set Path2End [join $node]
    } else { 
	set destinationLid $node
	set blockNum [expr $destinationLid / 64]
	set LidMod64 [expr $destinationLid % 64]
    }

    ### Fix for bug #32708
    # When the source node is a remote HCA, if I don't do the following 
    # then my MADs will get stuck upon "entering-and-exiting" this node
    if { ($Path2Start != "") && [lstGetParamValue Type $Path2Start] != "SW" } {
	set Path2Start [lreplace $Path2Start end end]
    }
    set DirectPath $Path2Start

   while { 1 } {
       # Step #1: get the NodeGuid of $DirectPath
       if {[catch { set NodeGuid $G(DrPath2Guid,$DirectPath) }]} {
	   if {[catch {set NodeInfo [smMadGetByDr NodeInfo dump "$DirectPath"]}]} {
	       break
	   }
	   if {[pathIsBad $DirectPath]} { break }
	   debug "981" DirectPath NodeInfo
	   set NodeGuid [wordAfterFlag $NodeInfo "-node_guid"]
	   set G(DrPath2Guid,$DirectPath) $NodeGuid
	   set G(NodeInfo,$NodeGuid) $NodeInfo
	   set G(byDr,NodeInfo,$DirectPath) $NodeInfo
	   
	   if { ! [wordInList $DirectPath $G(list,DirectPath)] } { 
	       lappend G(list,DirectPath) $DirectPath 
	   }
       }

       set EntryPort	[format %d [lstGetParamValue PortNum $DirectPath]]
       set NodeType	[lstGetParamValue Type $DirectPath -byDr]
       set NodePorts	[lstGetParamValue Ports $DirectPath -byDr]

       set NodeLid	[lstGetParamValue LID $DirectPath $EntryPort]
       if { $NodeLid == "0x" } { break }
       if { $NodeType == "SW" } { 
	   set G(DrPath2LID,$DirectPath:0) $NodeLid 
       } else { 
	   set G(DrPath2LID,$DirectPath:$EntryPort) $NodeLid
       }

       set lidGuidDev	"[DrPath2Name $DirectPath -lidGuidDev]"
       if { $DirectPath != $Path2Start } {
	   set portName1 [lindex [lindex [linkNamesGet $DirectPath] end] 1]
	   regsub {\(} $portName1 " (" portName1
	   inform "-I-ibtrace:read.lft.to" "$portName1 $lidGuidDev port=$EntryPort"
       }
       
       debug "1028" exitPort NodePorts NodeType EntryPort NodeDevID NodeLid linkNames NodeName
       ############################################################
       ### If we "discover" by means of direct route
       if {$byDrPath} {
	   # This is the stopping condition for direct routing
	   if { $DirectPath == $Path2End } { break }
	   set exitPort [lindex $Path2End [llength $DirectPath]]


	   # if the user gives a direct path passing through a HCA
	   if { ( $NodeType != "SW" ) && ( $DirectPath != $Path2Start ) } {
	       inform "-E-ibtrace:direct.route.deadend" \
		   -DirectPath "$DirectPath"
	   }

	   # if port number is wrong (it exceeds the node's number of ports)
	   if { $exitPort > $NodePorts } { 
	       inform "-E-ibtrace:direct.path.no.such.port" \
		   -DirectPath "$DirectPath" -port $exitPort
	   }

       ############################################################
       } else { 
       ############################################################
       # If we discover by means of lid-route
       
	   # This is the good stopping condition for lid routing
	   if { $NodeLid == $destinationLid } { break } 
	   
	   # If we reached LID 0
	   if { $NodeLid == 0 } { 
	       inform "-E-ibtrace:reached.lid.0" -DirectPath "$DirectPath"
	   } 
	   
	   # If we reached a HCA
	   if { ( $NodeType != "SW" ) && ( $DirectPath != $Path2Start ) } {
	       inform "-E-ibtrace:lid.route.deadend" \
		   -DirectPath "$DirectPath" -lid $destinationLid 
	   } 
	   
	   # If we returned to an already-visited node: we are in a lid-loop -> exit
	   if { [info exists Guid2DrPath($NodeGuid)] } {
	       inform "-E-ibtrace:lid.route.loop" \
		   -DirectPath "$Guid2DrPath($NodeGuid)" -lid $destinationLid 
	   } else { 
	       set Guid2DrPath($NodeGuid) $DirectPath
	   }
	   
	   if { $NodeType != "SW" } {
	       set exitPort $EntryPort
	   } else {
	       if [catch {set FDBsBlock \
			      [smMadGetByDr LftBlock dump "$DirectPath" $blockNum]}] {
		   if { $errorCode == 0x801c } {
		       inform "-E-ibtrace:fdb.block.unreachable" \
			   -errorcode $errorCode -command "$cmd"
		   }
		   break 
	       }
	       if {[pathIsBad $DirectPath]} { break }
	       
	       set exitPort [expr [lindex $FDBsBlock $LidMod64]]
	       if { $exitPort == "0xff" } {
		   inform "-E-ibtrace:fdb.value.ffs" \
		       -lid $destinationLid \
		       -command "smLftBlockMad getByDr \{$DirectPath\} $blockNum" \
		       -entry "\#$LidMod64"
	       }
	   }
       }
       # if exitPort is down
       if { [lstGetParamValue LOG $DirectPath $exitPort] == "DWN" } {
	   inform "-E-ibtrace:link.down" \
	       -DirectPath "$DirectPath" -port $exitPort
       }
       set DirectPath [join "$DirectPath $exitPort"]
       set portName0 [lindex [lindex [linkNamesGet $DirectPath] end] 0]
       regsub {\(} $portName0 " (" portName0
       # Note that lidGuidDev are corresponding to the "old" DirectPath
       inform "-I-ibtrace:read.lft.from" "$portName0 $lidGuidDev port=$exitPort"
       ############################################################
   }

    # TODO: How to handle the situation when [pathIsBad $DirectPath] ?
    if {[pathIsBad $DirectPath]} { 
	badLinksUserInform
	catch { close $G(logFileID) }
	exit $G(status,discovery.failed)
    }
    return [list $DirectPath]
}

proc rereadLongPaths {} { 
    # TODO: use a "fluding" algorithm:
    # send $G(argv,count) MADs that don't wait for replies (! <- this should be coded into IBADM) on all long path 
    # and then read all performance counters

    ## Retrying discovery multiple times (according to the -c flag)
    global G 
    # HACK: this can also be done after writing the output files
    # The initial value of count is set to 4, since every link is traversed at least 3 times:
    # 1 NodeInfo, 1 PortInfo (once for every port), 1 NodeDesc
    # I don't use the above heuristic - I'm not 100% (only 99%) sure it's correct. 
    # I'm sure that at least 1 NodeInfo MAD is sent over each link. 
    set InitCnt 2
    if { $InitCnt > $G(argv,count) } { return }
    inform "-V-discover:long.paths"
    foreach DirectPath [lrange $G(list,DirectPath) 1 end] {
	# start from the second path in $G(list,DirectPath), because the first is ""
	# For the retries we use only the longest paths
	if { [lsearch -regexp $G(list,DirectPath) "^$DirectPath \[0-9\]"] == -1 } { 
	    for { set count $InitCnt } { $count <= $G(argv,count) } { incr count } {
		if {[pathIsBad $DirectPath]} { break }
		if {[catch { smMadGetByDr NodeDesc dump "$DirectPath"}]} { break }
	    }
	}
    }
    return
}
######################################################################

######################################################################
### If a topology file is given
######################################################################
proc matchTopology { lstFile args } {
    global G

    putsIn80Chars " "
    if { [info exists G(argv,report)] || [info exists G(argv,topo.file)] } {
	set G(fabric,.lst) [new_IBFabric]
	IBFabric_parseSubnetLinks $G(fabric,.lst) $lstFile
    }
    if { ! [info exists G(argv,topo.file)] } { return }

    # initilizing pointers for defined, discovered and merged fabrics
    # foreach fabric { ".lst" "merged" } { ; # ".topo" 
    #	set G(fabric,$fabric)	[new_IBFabric]
    # }

    # Loading defined and discovered fabrics
    # puts ""
    # IBFabric_parseTopology $G(fabric,.topo) $G(argv,topo.file) <- this already done in parseArgv
    # IBFabric_parseSubnetLinks $G(fabric,.lst) $lstFile 

    # Matching defined and discovered fabric
    set MatchigResult \
	[ibdmMatchFabrics $G(fabric,.topo) $G(fabric,.lst) \
	     $G(argv,sys.name) $G(argv,port.num) $G(RootPort,Guid) ]
    set G(MatchigResult) ""
    set old_line ""
    set G(missing.links) ""
    foreach line [split $MatchigResult \n] {

	if { [regexp {[^ ]} $line] || [regexp {[^ ]} $old_line] } { 
	    lappend G(MatchigResult) "  $line" 
	}
	# $G(missing.links) is the list of links found to be missing by topology
	# matching;
	# a pair of entries (0 & 1 , 2 & 3 etc.) are ports at the link's end
	set missingSysExp \
	    {^ *Missing System:([^ \(]+).*from port: *([^ ]+) to: *([^ ]+) *$}
	set missingLinkExp \
	    {^ *Missing internal Link connecting: *([^ ]+) to: *([^ ]+) *$}
	if { [regsub $missingSysExp "$old_line $line" {\1/\2 \3} link] || \
		 [regsub $missingLinkExp  "$line" {\1 \2} link] } {
	    set G(missing.links) [concat $G(missing.links) $link]
	}
	set old_line $line
    }

    set G(fabric,merged) [new_IBFabric]
    if [catch {ibdmBuildMergedFabric \
		   $G(fabric,.topo) $G(fabric,.lst) $G(fabric,merged)} ] {
        return
    }

    # HACK need to copy the min lid
    IBFabric_minLid_set $G(fabric,merged) [IBFabric_minLid_get $G(fabric,.lst)]

    return
}

proc reportTopologyMatching { args } {
    global G
    if { ! [info exists G(argv,topo.file)] } { return }
    set noheader [wordInList "-noheader" $args] 
    if { ! $noheader } { inform "-I-topology:matching.header" }

    set MatchigResultLen [llength $G(MatchigResult)]
    if { $MatchigResultLen == 0 } {
	inform "-I-topology:matching.perfect"
    } else { 
	if { ! $noheader } { inform "-I-topology:matching.note" }
	if { $MatchigResultLen > $G(config,warn.long.matchig.results) } { 
	    inform "-W-topology:matching.bad"
	}
    }
    putsIn80Chars \n[join $G(MatchigResult) \n]
}

proc DrPath2Name { DirectPath args } {
    global G 
    
    set lidGuidDev [wordInList "-lidGuidDev" $args]
    set fullName [wordInList "-fullName" $args]
    if {[set getPortName [wordInList "-port" $args]]} { 
	set port [wordAfterFlag $args "-port"]
    }
    if { $fullName || $lidGuidDev } { 
	set NodeGuid	[lstGetParamValue NodeGUID $DirectPath -byDr]]
	set NodeDevID	[expr [lstGetParamValue DevID $DirectPath -byDr]]
	set NodePorts	[lstGetParamValue Ports $DirectPath -byDr]
	set EntryPort   [format %d [lstGetParamValue PortNum $DirectPath -byDr]]
	set NodeLid	[lstGetParamValue LID $DirectPath $EntryPort]
	set lidGuidDev	"lid=$NodeLid guid=$NodeGuid dev=$NodeDevID"
    } else {
	set lidGuidDev	""
    }
	
    if { ( 0==[info exists G(argv,topo.file)] ) || ( 1==$lidGuidDev ) } {
	return $lidGuidDev
    }
    
    # set nodeName $G(argv,sys.name)
    set path $DirectPath
    set topoNodesList [join [IBFabric_NodeByName_get $G(fabric,.topo)]]
    if { [set nodePointer [wordAfterFlag $topoNodesList $G(argv,sys.name)]] == "" } {
	return $lidGuidDev
    }

    while { [llength $path] > 0 } { 
        set port [lindex $path 0]
	set path [lrange $path 1 end]
	set nodePorts	[IBNode_Ports_get $nodePointer]
        set portPointer	[lindex $nodePorts [lsearch -regexp $nodePorts "/$port$"]]

        if {[catch {set remPortPointer [IBPort_p_remotePort_get $portPointer]} msg]} {
            return $lidGuidDev
	} elseif { $remPortPointer == "" } { 
            return $lidGuidDev
	} elseif {[catch {set nodePointer [IBPort_p_node_get $remPortPointer]}]} { 
            return $lidGuidDev
	} elseif { $nodePointer == "" } { 
            return $lidGuidDev
	}
    }

    if {[catch {set nodeName [IBNode_name_get $nodePointer]}]} { 
	return $lidGuidDev
    } elseif { $nodeName == "" } { 
	return $lidGuidDev
    } elseif { $fullName } {  
	return "name=$nodeName $lidGuidDev"
    } else { 
	return "$nodeName"
    }
}


proc linkNamesGet { DirectPath args } { 
    # debug "189" -header
    global G
    # when topology is not given, we report links by (the end of) direct route
    if { ! [info exists G(argv,topo.file)] } {
	return ; # "Link at the end of direct route \{$DirectPath\}"
    }

    set DirectPath	[join $DirectPath]
    if { [set Port0 [lindex $DirectPath end]] == "" } { 
	set Port0 $G(argv,port.num)
    }

    set PortGuid $G(GuidByDrPath,[lreplace $DirectPath end end])
    set NodeGuid $G(NodeGuid,$PortGuid)
    if { [set Pointer(node0) \
	      [IBFabric_getNodeByGuid $G(fabric,merged) $NodeGuid]] == "" } {
	return ; # "Link at the end of direct route $DirectPath"
    }
    set node0Ports	[IBNode_Ports_get $Pointer(node0)]
    set Pointer(port0)	[lindex $node0Ports [lsearch -regexp $node0Ports "/$Port0$"]]
    catch { set Pointer(port1)	[IBPort_p_remotePort_get $Pointer(port0)] }

    set linkKind "external"
    foreach I { 0 1 } { 
	if { $Pointer(port${I}) == "" } { continue }

	set Name(port${I}) [IBPort_getName $Pointer(port${I})]
	set Pointer(sysport${I}) [IBPort_p_sysPort_get $Pointer(port${I})]
	if {[wordInList "-node" $args]} { 
	    set Pointer(node${I}) [IBPort_p_node_get $Pointer(port${I})]
	    set Name(node${I})  [IBNode_name_get   $Pointer(node${I})]
	    lappend link "$Name(node${I})"
	} elseif { $Pointer(sysport${I}) == "" } {
	    lappend link $Name(port${I})
	    set linkKind "internal"
	} else { 
	    set Pointer(node${I}) [IBPort_p_node_get $Pointer(port${I})]
	    set Num(port${I})	  [IBPort_num_get    $Pointer(port${I})]
	    set Name(node${I})	  [IBNode_name_get   $Pointer(node${I})]
	    lappend link "$Name(port${I})($Name(node${I})/P$Num(port${I}))"
	    # = $Name(system${I})/$Name(sysport${I})()
	}
    }

    # processing the result
    switch -exact [llength $link] { 
	0 {;# just to be on the safe side: if both link ends are UNKNOWN
	    return
	}
	1 {;# look for the info of the other side of the link in the 
	    # "missing links" of topo matching
	    # lsearch ^ 1 = the index of the other-in-pair 
	    # (note: if lsearch = -1 then index = -2)
	    # TODO: should I not report these links, 
	    # as the topology matching already reported abo
	    set index [expr [lsearch -exact $G(missing.links) $link] ^ 1]
	    lappend link [lindex $G(missing.links) $index]
	}
    }
    # debug "252" link
    return "names:$linkKind [list $link]"
}

# extract the name(s) of the port(s) from the -n flag
proc getArgvPortNames {} {
    global G argv

    # TODO: What do I do when -n specifies a HCA that has 2 ports connected to the fabric???

    if { ! [info exists G(argv,by-name.route)] } { return }
    set flag "-n"

    array set topoNodesArray [join [IBFabric_NodeByName_get $G(fabric,.topo)]]
    array set topoSysArray   [join [IBFabric_SystemByName_get $G(fabric,.topo)]]
    foreach nodeName [array names topoNodesArray] {
	foreach portPtr [join [IBNode_Ports_get $topoNodesArray($nodeName)]] {
	    set portName [IBPort_getName $portPtr] 
	    set portNum	 [IBPort_num_get $portPtr]
	    array set topoPortsArray	"$portName $portPtr"
	    # for node ports
	    array set topoPortsArray	"$nodeName/P${portNum} $portPtr"
	}
    }

    foreach name [split $G(argv,by-name.route) ,] {
	# debug "121" name
	catch { unset portPointer portPointers }

	if { ! [catch { set portPointer $topoPortsArray($name) }] } {
	} elseif { ! [catch { set nodePointer $topoNodesArray($name) }] } {
	    if { [IBNode_type_get $nodePointer] == 1 } { ; # 1=SW 2=CA 3=Rt
		set portPointer [lindex [IBNode_Ports_get $nodePointer] 0]
	    }
	} elseif { ! [catch { set sysPointer $topoSysArray($name) }] } { 
	    if { [llength [set sys2node \
			       [IBSystem_NodeByName_get $sysPointer]]] == 1 } {
		set nodePointer [lindex [join $sys2node] end]
	    }
	} else {
	    inform "-E-argv:bad.node.name" \
		-flag $flag -value "$name" \
		-names [lsort -dictionary [array names topoNodesArray]]
	}

	if {[info exists portPointer]} {
	    if { [IBPort_p_remotePort_get $portPointer] == "" } {
		inform "-E-argv:specified.port.not.connected" \
		    -flag $flag -value "$name"
	    }
	} else { 
	    if {[info exists nodePointer]} {
		set W0 [list "node [IBNode_name_get $nodePointer]"]
		foreach pointer [IBNode_Ports_get $nodePointer] { 
		    if { [IBPort_p_remotePort_get $pointer] != "" } { 
			lappend portPointers $pointer
		    }
		}
	    } else { 
		set W0 [list "system [IBSystem_name_get $sysPointer]"]
		foreach sysPpointer [IBSystem_PortByName_get $sysPointer] { 
		    set pointer [IBSysPort_p_nodePort_get $sysPointer]
		    if { [IBPort_p_remotePort_get $pointer] != "" } { 
			lappend portPointers $pointer
		    }
		}
	    }

	    if { ! [info exists portPointers] } { 
		inform "-E-argv:hca.no.port.is.connected" -flag $flag -value $W0
	    } elseif { [llength $portPointers] > 1 } { 
		inform "-W-argv:hca.many.ports.connected" -flag $flag -value $W0 \
		    -port [IBPort_num_get [lindex $portPointers 0]]
	    } 
	    set portPointer [lindex $portPointers 0]
	}
	lappend portNames [IBPort_getName $portPointer]
    }
    return $portNames
}

proc name2Lid { portName } {
    global G
    debug "102" -header
    if { ! [info exists G(argv,topo.file)] } {
	return -code 1
    }
    if { $portName == $G(argv,sys.name) } {
	return $G(RootPort,Lid)
    }

    array set mergedNodesArray \
	[join [IBFabric_NodeByName_get $G(fabric,merged)]]
    foreach nodePointer [array names mergedNodesArray] {
	foreach pointer \
	    [join [IBNode_Ports_get $mergedNodesArray($nodePointer)]] {
		if { $portName == [IBPort_getName $pointer] } {
		    set portPointer $pointer
		    break
		}
	    }
	if {[info exists portPointer]} { break }
    }
    if { ! [info exists portPointer] } {
	debug "-E- DB:190: portPointer not found"
	return -code 1
    }
    return [IBPort_base_lid_get $portPointer]
}

proc reportFabQualities { } { 
    global G
    if { ! [info exists G(argv,report)] } { return }
    set nodesNum [llength [array names G "NodeInfo,*"]]
    set swNum [llength [array names G "PortInfo,*:0"]]
    if { [set hcaNum [expr $nodesNum - $swNum]] == 1 } { 
	inform "-W-report:one.hca.in.fabric"
	return
    }

    if {[info exists G(argv,topo.file)]} { 
	set fabric $G(fabric,merged)
    } else { 
	set fabric $G(fabric,.lst)
    }
    inform "-I-ibdiagnet:report.fab.qualities.header"
    # general reports
    # TODO : what else do I need to report?
    IBFabric_parseFdbFile $fabric $G(outfiles,.fdbs)
    IBFabric_parseMCFdbFile $fabric $G(outfiles,.mcfdbs)
    # verifying CA to CA routes
    set report [ibdmVerifyCAtoCARoutes $fabric]
    append report [ibdmCheckMulticastGroups $fabric]

    inform "-I-ibdiagnet:check.credit.loops.header"

    # report credit loops 
    ibdmCalcMinHopTables $fabric
    set roots [ibdmFindRootNodesByMinHop $fabric]
    if {[llength $roots]} {
        puts "-I- Found [llength $roots] Roots:"
        foreach r $roots {
            puts " $r"
        }
        ibdmReportNonUpDownCa2CaPaths $fabric $roots
    } else {
        ibdmAnalyzeLoops $fabric
    }




    # Multicast mlid-guid-hcas report
    set mcPtrList [sacMCMQuery getTable 0]
    if { [llength $mcPtrList] > 0 } {
	inform "-I-ibdiagnet:mgid.mlid.hca.header"
	putsIn80Chars "mgid [bar " " 32] | mlid   | HCAs\n[bar - 80]"
	foreach mcPtr $mcPtrList {
	    # debug "1546" mcPtr
	    if {[catch {sacMCMRec OBJECT -this $mcPtr} msg]} {
                puts $msg
	    } else {
		catch {OBJECT cget} attributes
		foreach attr [lindex $attributes 0] {
		    set [string range $attr 1 end] [OBJECT cget $attr]
		}
		rename OBJECT ""
	    }
	    ### TODO: format the HCAs in G(mclid2DrPath,*) nicely
            set mlidHex 0x[format %x $mlid]
            if {[info exists G(mclid2DrPath,$mlidHex)]} {
                set mlidHcas $G(mclid2DrPath,$mlidHex)
            } else {
                set mlidHcas NONE
            }
            putsIn80Chars "$mgid | 0x[format %x $mlid] | [join $mlidHcas ,]"
        }
    }

    return
}
######################################################################

######################################################################
### .lst format settings
######################################################################
# The pocedure lstGetParamValue needs the database $G(list,DirectPath) 
# returns the value of a parameter of a port in .lst file format

## The source for parameters values
array set infoLst { 
    Type	{ -source NodeInfo -flag node_type -width 8
		  -substitution "1=CA 2=SW 3=Rt" -string 1 }
    Ports	{ -source NodeInfo -flag num_ports   -width 8 }
    SystemGUID	{ -source NodeInfo -flag sys_guid   -width 64 }
    NodeGUID	{ -source NodeInfo -flag node_guid   -width 64 }
    PortGUID	{ -source NodeInfo -flag port_guid   -width 64 }
    DevID	{ -source NodeInfo -flag device_id   -width 16 }
    Rev		{ -source NodeInfo -flag revision    -width 32 }
    PN		{ -width 8 }
    PortNum	{ -source NodeInfo -flag port_num_vendor_id -width 8 -offset 0:32}
    VenID	{ -source NodeInfo -flag port_num_vendor_id -width 24 -offset 8:32}
    NodeDesc	{ -source NodeDesc -flag description -width words -string 1 }
    LID		{ -source PortInfo -flag base_lid    -width 16 -fromport0 1 }
    PHY		{ -source PortInfo -flag link_width_active -width 8
	          -substitution "1=1x 2=4x 4=8x 8=12x" -string 1 }
    LOG		{ -source PortInfo -flag state_info1 -width 4 -offset 4:8
	          -substitution "1=DWN 2=INI 3=ARM 4=ACT" -string 1 }
    SPD		{ -source PortInfo -flag link_speed  -width 4 -offset 0:8
	          -substitution "1=2.5 2=5 4=10" -string 1 }
}
### These used to be a part of infoLst
# LinFDBTop { -source SwitchInfo -flag lin_top  -width 16 }
# FDBs	 { -source LftBlock -width 0 }
proc GetEntryPort {_port_num_vendor_id} {
    global G infoLst
    parseOptionsList $infoLst(PortNum) 
    catch { set value [format %x $_port_num_vendor_id] }
    regsub {^0x} $value {} value
    if {[catch { set width [expr $cfg(width) / 4] }]} { set width "" }
    scan $cfg(offset) {%d%[:]%d} offset D bigwidth
    regexp {^([0-9]+):([0-9]+)$} $cfg(offset) dummy offset bigwidth
    set bigwidth [expr $bigwidth / 4] 
    set offset [expr $offset / 4] 
    set value [zeroesPad $value $bigwidth]

    set value [string range $value $offset [expr $offset + $width -1]]
    set value "0x$value"
    
    return $value
}


proc lstGetParamValue { parameter DirectPath args } {
    global G infoLst
    # debug "1198" -header
    set DirectPath "[join $DirectPath]"
    if { ! [wordInList $DirectPath $G(list,DirectPath)] } {
        return -code 1 -errorinfo "Direct Path \"$DirectPath\" not in $G(list,DirectPath)"
    }

    if {[catch {set PortGuid $G(GuidByDrPath,$DirectPath)} ]} {
        return -code 1 -errorinfo "Could not set PortGuid"
    }

    set PortGuid $G(GuidByDrPath,$DirectPath)
    if {[info exists G(NodeGuid,$PortGuid)]} {
        set NodeGuid $G(NodeGuid,$PortGuid)
    }

    foreach flag "noread byDr" { 
	if { [set index [lsearch -exac $args "-$flag"]] >= 0 } { 
	    set $flag 1
	    set args [lreplace $args $index [expr $index + 1]]
	} else { 
	    set $flag 0
	}
    }

    if {[wordInList $parameter "PortNum PortGuid"]} { 
	set byDr 1
    }

    ## Setting the parameter flags
    parseOptionsList $infoLst($parameter) 
    ## Setting the port number
    set port [lindex $args 0]
    if {[info exists cfg(fromport0)]} { 
	if { [lstGetParamValue Type $DirectPath] == "SW" }  {
	    set port 0
	}
    }
    ### Getting the parameter value 
    switch -exact -- $parameter { 
	"PN"	   { set value $port }
	"NodeDesc" { set value $G(NodeDesc,$NodeGuid) }
	default {
            set addPort2Cmd [regexp {(Port|Lft)} $cfg(source)]
            if {[info exists NodeGuid]} {
                if {$cfg(source) == "NodeInfo"} {
                    set InfoSource "$cfg(source),$NodeGuid"
                }
	        set InfoSource "$cfg(source),$NodeGuid"
                if {$addPort2Cmd} { append InfoSource ":$port" }
                if {$byDr} { set InfoSource "byDr,$cfg(source),$DirectPath" }
            } else {
                set InfoSource DZ
            }
            if {[info exists G($InfoSource)]} { 
                set value [wordAfterFlag $G($InfoSource) -$cfg(flag)]
	    } elseif {$noread} { 
		return -code 1 
	    } elseif { [pathIsBad $DirectPath] } {
		return -code 1 -errorinfo "Direct Path \"$DirectPath\" is bad"
	    } else {
                set Cmd [list smMadGetByDr $cfg(source) -$cfg(flag) "$DirectPath"]
                if {$addPort2Cmd} { append Cmd " $port" }
                if {[catch { set value [eval $Cmd]}]} { return -code 1 }
	    }
	}
    }
    ## Formatting $value
    catch { set value [format %x $value] }
    regsub {^0x} $value {} value
    # bits -> bytes
    if {[catch { set width [expr $cfg(width) / 4] }]} { set width "" }
    if { ( $width == 0 ) || ( ! [regexp {^[0-9]+} $width] ) } {
	# do nothing
    } elseif {[info exists cfg(offset)]} { 
	scan $cfg(offset) {%d%[:]%d} offset D bigwidth
# 	regexp {^([0-9]+):([0-9]+)$} $cfg(offset) dummy offset bigwidth
	set bigwidth [expr $bigwidth / 4] ;# bits -> bytes
	set offset [expr $offset / 4] ;# bits -> bytes
        set value [zeroesPad $value $bigwidth]
        set value [string range $value $offset [expr $offset + $width -1]]
    } else { 
	set value [zeroesPad $value $width]
    }
    if {[info exists cfg(substitution)]} { 
	regsub -all { *= *} [join $cfg(substitution)] {= } substitution
        set value [zeroesErase $value]
	set value [wordAfterFlag $substitution "$value="] 
    } 
    if { ! [info exists cfg(string)] } {
	set value "0x$value"
    }
    # debug "336" value
    return $value
}

proc linkAtPathEnd { Path } {
    if { [catch { set port1 [format %d [lstGetParamValue PortNum $Path]] } ] } { 
	return -code 1
    }
    
    uplevel  1 set path0 \"[lreplace $Path end end]\"
    uplevel  1 set port0 [lindex $Path end]
    uplevel  1 set path1 \"$Path\"
    uplevel  1 set port1 $port1
}
######################################################################

######################################################################
# returns the info of one of a port in .lst format
proc lstInfo { type DirectPath port } {
    global G
    set DirectPath [join $DirectPath]
    set Info ""
    ## The lists of parameters
    switch -exact -- $type { 
	"port" { 
	    set sep ":" 
	    append lstItems "Type Ports SystemGUID NodeGUID PortGUID VenID"
	    append lstItems " DevID Rev NodeDesc LID PN"
	} "link" { 
	    set sep "="
	    append lstItems "PHY LOG SPD" 
	}
    }

    foreach parameter $lstItems {
	# The following may fail - then the proc will return with error
	regsub {^0x} [lstGetParamValue $parameter $DirectPath $port] {} value
	# set value [lstGetParamValue $parameter $DirectPath $port]
	# .lst formatting of parameters and their values
	if {[wordInList $parameter "VenID DevID Rev LID PN"]} {
	    set value [string toupper $value]
	}
	switch -exact -- $parameter {
	    "Type"	{ lappend Info "$value" }
	    "NodeDesc"	{ lappend Info "\{$value\}" }
	    "DevID"	{ lappend Info "${parameter}${sep}${value}0000" }
	    "VenID"	{ lappend Info "${parameter}${sep}00${value}" }
	    default	{ lappend Info "${parameter}${sep}${value}" }
	}
    }
    return [join $Info]
}



proc write.lstFile { args } { ; # Do not change proc name - initOutfile uses it
    global G

    set FileID [initOutfile]
    foreach DirectPath $G(list,DirectPath) {
        if { ( [llength $DirectPath] == 0 ) || [pathIsBad $DirectPath] || [catch {linkAtPathEnd $DirectPath}] } { 
	    continue 
	}
        catch {
	    set lstLine ""
	    append lstLine "\{ [lstInfo port $path0 $port0] \} "
	    append lstLine "\{ [lstInfo port $path1 $port1] \} "
	    append lstLine "[lstInfo link $path0 $port0]"
	    puts $FileID "$lstLine"
	}
    }
    close $FileID
    return
}

##############################
#  SYNOPSIS	write.dbsFile
#  FUNCTION
#	writes the $G(tool).fdbs file, which lists the Linear Forwarding Tables
#	of all the switches in the discovered faric.
#	Writing this file is part of the flow of ibdiagnet.
#	The data is obtained by sending LftBlock MADs to read all the entires
#	of the Linear Forwarding Tables to all the switches.
#	The file has the following format for each switch of the IB fabric:
#	   Switch <NodeGuid>
#	   LID    : Out Port(s)
#	   0xc000   0x002 0x00f
#		...
#  INPUTS	NULL
#  OUTPUT	the file $G(tool).mcfdbs
#  DATAMODEL	
#	the proc uses the global arrays
#	$G(PortInfo,<NodeGuid>:0) - as a list of all the switches
#	and $G(Guid2DrPath,<NodeGuid>) - to translate node-guids to direct paths
#	it sets the global array $G(mclid2DrPath,<mcLid>) - a list of (direct
#	paths to) HCAs belonging to a multicast-lid - to be used later by
#	reportFabQualities.
proc write.fdbsFile { args } { ; # Do not change proc name - initOutfile uses it
    global G

    set FileID [initOutfile]

    foreach entry [array names G "DrPathOfGuid,*"] {
        set NodeType [lstGetParamValue Type $G($entry) -byDr]
        if {$NodeType != "SW"} { continue }
        set DirectPath $G($entry)
	if {[pathIsBad $DirectPath]} { continue }

        set PortGuid [lindex [split $entry ,] end]
        set NodeGuid $G(NodeGuid,$PortGuid) 

        set thisSwLid [lstGetParamValue LID $DirectPath X -noread]
	if {[pathIsBad $DirectPath]} { continue }
	if [catch {set LinFDBTop \
		       [smMadGetByDr SwitchInfo -lin_top "$DirectPath"]}] { 
	    continue 
	}
	### TODO: What if lin_cap < lin_top ?
	set FDBs ""
	for { set I 0 } { [expr $I *64] <= $LinFDBTop } { incr I } {
	    # Note "<=" - because LinFDBTop indicates the INDEX of the last 
	    # valid entry 
	    if [catch {set NewFDBs \
			   [smMadGetByDr LftBlock dump "$DirectPath" $I] }] { 
		set FDBs [concat $FDBs [bar "0xff " 64]]
	    } else { 
		set FDBs [concat $FDBs $NewFDBs] 
	    }
	}
	puts -nonewline $FileID "osm_ucast_mgr_dump_ucast_routes: "
	puts $FileID "Switch $NodeGuid"
	puts $FileID "LID    : Port : Hops : Optimal"
	for { set lid 1 } { $lid <= $LinFDBTop } { incr lid 1 } { 
	    scan [lindex $FDBs $lid] %x port
	    puts -nonewline $FileID "0x[string toupper [format %04x $lid]] : "
	    if { $port == "0xff" } { 
		puts $FileID "UNREACHABLE"
	    } elseif { ( $port == "0x00" ) && ( $lid != $thisSwLid ) } {
		puts $FileID "UNREACHABLE"
	    } else { 
		puts $FileID "[zeroesPad $port 3]  : 00   : yes"
	    }
	}
	puts $FileID ""
    }
    close $FileID
}

##############################
#  SYNOPSIS	write.mcfdbsFile
#  FUNCTION
#	writes the $G(tool).mcfdbs file, which lists the Multicast Forwarding
#	Tables of all the switches in the discovered faric.
#	Writing this file is part of the flow of ibdiagnet.
#	The data is obtained by sending MftBlock MADs to read all the entires
#	of the MC Forwarding Tables. Note the tables are read in blocks of
#	16 ports x 64 mcLids blocks, thus if a deviec has more than 16 ports
#	then reading its mc table is a bit tricky...
#	The file has the following format for each switch of the IB fabric:
#	   Switch <NodeGuid>
#	   LID    : Out Port(s)
#	   0xc000   0x002 0x00f
#		...
#  INPUTS	NULL
#  OUTPUT	the file $G(tool).mcfdbs
#  DATAMODEL	
#	the proc uses the global arrays
#	$G(PortInfo,<NodeGuid>:0) - as a list of all the switches
#	and $G(Guid2DrPath,<NodeGuid>) - to translate node-guids to direct paths
#	it sets the global array $G(mclid2DrPath,<mcLid>) - a list of (direct
#	paths to) HCAs belonging to a multicast-lid - to be used later by
#	reportFabQualities.
proc write.mcfdbsFile { } { ; # Do not change proc name - initOutfile uses it
   global G

   set FileID [initOutfile]

    foreach entry [array names G "DrPathOfGuid,*"] {
        set NodeType [lstGetParamValue Type $G($entry) -byDr]
        if {$NodeType != "SW"} { continue }
        set DirectPath $G($entry)
        if {[pathIsBad $DirectPath]} { continue }
        set PortGuid [lindex [split $entry ,] end]
        set NodeGuid $G(NodeGuid,$PortGuid) 

        if [catch { set McFDBCap \
            [smMadGetByDr SwitchInfo -mcast_cap "$DirectPath"] }] { 
                continue
            }
        set NumPorts [lstGetParamValue Ports $DirectPath]
        puts $FileID "\nSwitch $NodeGuid\nLID    : Out Port(s) "
        for {set LidGrp 0xc000} {$LidGrp < 0xc000 + $McFDBCap} {incr LidGrp 0x20} {
            set McFDBs ""
            set LidGroup "0x[format %x $LidGrp]"
            # read the entire McFDBs data for Lids $LidGroup .. $LidGroup + 0x1f
            for {set PortGroup 0} {$PortGroup <= $NumPorts} {incr PortGroup 16} {
                if [catch {
                    set newBlock \
                    [smMadGetByDr MftBlock dump "$DirectPath" $LidGroup $PortGroup]
                }] { break }
                append McFDBs " " [hex2bin $newBlock]
            }
            # figure out - and print to file - the mc ports for each Lid 
            # in the lid group
            for { set lidIdx 0 } { $lidIdx < 0x20 } { incr lidIdx } {
                set mask ""
                for { set PortGroup 0; set idx 0 } \
                    { $PortGroup <= $NumPorts } \
                    { incr PortGroup 16; incr idx 32 } {
                    set mask "[lindex $McFDBs [expr $lidIdx + $idx]]$mask"
                }

                if { ! [regexp "1" $mask] } { continue }
                set mcLid [format %04x [expr $lidIdx + $LidGroup]]
                set outputLine "0x[string toupper $mcLid] :"
                for { set Port 0; set maskIdx [expr [string length $mask]-1] } \
                    { $Port <= $NumPorts } \
                    { incr Port 1 ; incr maskIdx -1 } {
                    # set portMaskIndex [expr [string length $mask]-1-$Port]
                    if { [string index $mask $maskIdx] == 1 } { 
                        append outputLine " 0x[string toupper [format %03x $Port]] "
                        set LongPath [join "$DirectPath $Port"]
                        catch { 
                            if { [lstGetParamValue Type $LongPath -byDr] != "SW" } { 
                                lappend G(mclid2DrPath,0x$mcLid) $LongPath
                            }
                        }
                    }
                }
                puts $FileID "$outputLine"
            }
        }
    }
    close $FileID
}
######################################################################

######################################################################
### Initial and final actions
######################################################################

proc Initialize_ibis {} {
    catch { ibis_set_transaction_timeout 100 }
    if {[info exists env(IBMGTSIM_DIR)]} {
	ibis_opts configure -log_file [file join $env(IBMGTSIM_DIR) ibis.log]
    } else {
	if {[catch {set ID [open /tmp/ibis.log w]}]} {
	    ibis_opts configure -log_file /tmp/ibis.log.[pid]
	}
	catch { close $ID }
    }
    if {[catch { ibis_init } ErrMsg]} {
        inform "-E-ibis:init" "$ErrMsg"
    }
    if {[catch { ibis_get_local_ports_info } ibisInfo ]} {
	if { $ibisInfo == "" } {
	    inform "-E-ibis:no.hca"
	} else {
	    inform "-E-ibis:info" "$ibisInfo"
	}
    }
    return $ibisInfo
}

proc Port_And_Idx_Settings {_ibisInfo} {
    global G env
    ### Parsing ibisInfo (the output of ibis_get_local_ports_info) 
    # - to set G(argv,port.num) (if it was not specified by user) 
    # and check that the port is not DOWN
    # Also, the global variables G(RootPort,Guid) and G(RootPort,Lid) are set

    set ibisInfo $_ibisInfo
    set hcaIndex 0
    set upPorts 0
    set oldPortGuid [lindex [lindex $ibisInfo 0] 0]
    set portNumSet  [info exists G(argv,port.num)]
    foreach entry $ibisInfo {
	scan $entry {%s %s %s} PortGuid PortLid PortState
	# Note that this is used for the 1st iteration, too
        # TODO - FIX the differes by one algo
        if { ! [guidsDifferBy1 $PortGuid $oldPortGuid] } {
	    incr hcaIndex
	    set PortNum 0
	}
	set oldPortGuid $PortGuid
	incr PortNum

	if { $hcaIndex != $G(argv,dev.idx) } { continue }
	if {$portNumSet} {
	    if { $PortNum != $G(argv,port.num) } { continue }

	    if { $PortState == "DOWN" } { 
		inform "-E-discover:local.port.down" -port $PortNum 
	    } elseif { ( $PortState != "ACTIVE" ) && ( $G(tool) == "ibtrace" ) } {
		inform "-E-ibtrace:local.port.not.active" \
		    -port $PortNum -state $PortState
	    } else { 
		set G(RootPort,Guid) $PortGuid
		set G(RootPort,Lid) $PortLid
		break
	    }
	} else {
	    if {   ( $PortState == "DOWN"   ) \
		|| ( $PortState != "ACTIVE" ) && ( $G(tool) == "ibtrace" ) } {
		continue
	    }
	    incr upPorts
	    if { ! [info exists G(argv,port.num)] } {
		set G(argv,port.num) $PortNum
		set G(RootPort,Guid) $PortGuid
		set G(RootPort,Lid)  $PortLid
	    }
	}
    }

    ### Checking the validity of G(argv,dev.idx) and G(argv,port.num)
    if { $hcaIndex < $G(argv,dev.idx) } {
	inform "-E-localPort:dev.not.found" -flag "-i" -value "$G(argv,dev.idx)"
    } elseif { $hcaIndex > 1 } { 
	inform "-I-localPort:using.dev.index"
    }
    if { $portNumSet } {
	if { $PortNum != $G(argv,port.num) } {
	    inform "-E-localPort:port.not.found" -flag "-p" -value $G(argv,port.num)
	} elseif {[info exists G(-p.set.by.-d)]} {
	    inform "-I-localPort:is.dr.path.out.port"
	}
    } else {
	if { ! [info exists G(argv,port.num)] } {
	    inform "-E-localPort:all.ports.down" -flag "-p" -value "" 
	} else { # Fix for bug #32686
	    if { $upPorts > 1 } {
		inform "-W-localPort:few.ports.up" -flag "-p" -value ""
	    } elseif { $PortNum > 1 } {
		inform "-I-localPort:one.port.up"
	    }
	}
    }
    ibis_set_port $G(RootPort,Guid)
}

proc Topology_And_SysName_Settings {} {
    global G 
    ### If topology is given, check that $G(argv,sys.name) is a name of an 
    # existing system, or try to smartly guess it, if it was not given...
    # Note that $G(argv,sys.name) is, actually, the name of the source NODE!
    if { ! [info exists G(argv,topo.file)] } { return }
    if {[catch { set namesList $G(argv,sys.name) }]} {
	# Trying to guess the local system name:
	# check if the hostname, or any word in the node description, 
	# is a valid system (or node) name.
	set namesList [lindex [split [info hostname] .] 0]
	catch { append namesList " " [smMadGetByDr NodeDesc -description {}] }
    }
    array set topoNodesArray [join [IBFabric_NodeByName_get $G(fabric,.topo)]]
    array set topoSysArray   [join [IBFabric_SystemByName_get $G(fabric,.topo)]]
    set sysNameSet [info exists G(argv,sys.name)]
    foreach item $namesList {
	if {[info exists topoNodesArray($item)]} {
	    set G(argv,sys.name) $item
	    if { ! $sysNameSet } { 
		inform "-W-localPort:node.inteligently.guessed" 
	    }
	    return
	} elseif {[info exists topoSysArray($item)]} {
	    set nodesNames [IBSystem_NodeByName_get $topoSysArray($item)]
	    set nodesNames [lsort -dictionary $nodesNames]
	    set G(argv,sys.name) \
		[lindex [lindex $nodesNames [expr $G(argv,dev.idx) -1]] 0]
	    if { ! $sysNameSet } { 
		inform "-W-localPort:node.inteligently.guessed" 
	    }
	    return
	}
    }

    ## If local system name was not idetified
    # (I advertise only the HCA-System names)
    set HCAnames ""
    foreach sysName [array names topoSysArray] {
	set sysPointer $topoSysArray($sysName)
	# The system is considered a HCA-sys if at least one HCA node
	foreach item [IBSystem_NodeByName_get $sysPointer] {
	    if { [IBNode_type_get [lindex $item 1]] != 1 } { # 1=SW 2=CA 3=Rt
		lappend HCAnames $sysName 
		break 
	    }
	}
    }

    # If the source node name was not found - exit with error
    if {[info exists G(argv,sys.name)]} {
	inform "-E-argv:bad.sys.name" \
	    -flag "-s" -value $G(argv,sys.name) -names [lsort $HCAnames]
    } else { 
	inform "-E-argv:unknown.sys.name" -names [lsort $HCAnames]
    }
}
##############################
#  SYNOPSIS	startIBDebug
#  FUNCTION	
#	executes the following initial actions when starting to run any tool:
#	- parsing the command line (running proc parseArgv)
#	- initianlize ibis: 
#	    ibis_opts configure -log_file (if necessary)
#	    ibis_init, 
#	    ibis_get_local_ports_info
#	- parsing the result of ibis_get_local_ports_info:
#	   - If local hca-index was specified, check that such device exists
#	   - If local port-num was specified, check that this port is not DOWN
#	     (ACTIVE, in case of ibtrace)
#	   - If local port-num was not specified, set it to be the first not 
#	     DOWN (ACTIVE) port of the local device.
#	- if the above is OK, run ibis_set_port
#	- if a topology file is specified, check that the local system name is a
#	   valid system name, or - if the latter was not specified - try to
#	   guess it (if the host name or a word in the local node description
#	   are valid system names).
#  INPUTS	NULL
#  OUTPUT	NULL
#  DATAMODEL
#	the proc uses $env(IBMGTSIM_DIR) - if it exists, we are in simulation mode
#	the proc uses the following global variables:
#	   $G(argv,dev.idx) - the local-device-index
#	   $G(argv,port.num) - the local-port-num (this var may also be set here)
#	   $G(fabric,.topo) - the ibdm pointer to the fabric described in the topology file
#	   $G(-p.set.by.-d) - if set, then the port-num was not explicitly
#	     specified and it was set to be the output port of the direct route
#	the proc also sets the global vars G(RootPort,Guid) and G(RootPort,Lid)
#	- the node-guid and LID of the local port.	
proc startIBDebug {} {
    global G env

    debug "2053" {[pwd]}
    ### parsing command line arguments
    parseArgv
    
    ### Initialize ibis
    set ibisInfo [Initialize_ibis]
    
    ### denoting the default port
    if {[llength [lsearch -all -start 1 $ibisInfo [lindex $ibisInfo 0]]] > 0} {
        set ibisInfo [lrange $ibisInfo 1 end]
    }

    debug "2042" ibisInfo

    ### Setting the local port and device index
    Port_And_Idx_Settings $ibisInfo

    ### Setting the local system name 
    Topology_And_SysName_Settings

    return
}
##############################

##############################
#  SYNOPSIS	finishIBDebug
#  FUNCTION	executes final actions for a tool:
#		- runs the proc listG
#		- displays the "-I-done" info ("Done" + run time)
#		- exits the program
#  INPUTS	NULL
#  OUTPUT	NULL
#  DATAMODEL	I use $G(start.clock.seconds) to tell the total run time
proc finishIBDebug {} { 
    global G
    listG
    # catch { close $G(DBId) }
    inform "-I-done" $G(start.clock.seconds)
    catch { close $G(logFileID) }
    exit 0
}
##############################
