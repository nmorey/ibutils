############################################################
### List of procs

##############################
### Initializ Databases
##############################
# InitalizeIBdiag
# initOutputFile
# parseOptionsList

##############################
### Initial and final actions
##############################
# Initialize_ibis
# Port_And_Idx_Settings
# Topology_And_SysName_Settings
# finishIBDebug

##############################
### GENERAL PURPOSE PROCs
##############################
# WordInList
# RemoveElementFromList
# RemoveDirectPath     
# WordAfterFlag        
# bar                  
# ZeroesPad            
# ZeroesErase          
# Hex2Bin              
# LengthMaxWord        
# AddSpaces            
# ProcName        

##############################
### Sending MADs
##############################
# SmMadGetByDr
# PmListGet

##############################
### Handling Duplicated Guids
##############################
# AdvncedMaskGuid
# BoolIsMaked                                   
# RetriveRealPort   

##############################
### Handling bad links
##############################
# PathIsBad
# DetectBadLinks
# ComparePMCounters
# BadLinksUserInform
# RemoveDirectPath

##############################
### Farbic Discovery
##############################
# DiscoverFabric
# SetNeighbor
# DiscoverHiddenFabric
# CheckDuplicateGuids
# CheckBadLidsGuids
# DiscoverPath
# RereadLongPaths

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
# GetParamValue
# linkAtPathEnd
# lstInfo
# writeLstFile
# write.fdbsFile
# write.mcfdbsFile

##############################
### Debug
##############################
# listG
# debug

######################################################################
### GENERAL PURPOSE PROCs
######################################################################
##############################
#  SYNOPSIS	WordInList word list 
#  FUNCTION	Indicates whether $word is a word in $list
#  INPUTS	a string $word and a list $list#
#  OUTPUT	1 or 0 - if $word is or isn't a word in $list (resp.)
proc WordInList { word list } {
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
#  SYNOPSIS	  
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc RemoveDirectPath {_drPath } {
   global G
   set tmpList $G(list,DirectPath)
   set tmpList [RemoveElementFromList $G(list,DirectPath) $_drPath ]
   set G(list,DirectPath) $tmpList
}
##############################

##############################
#  SYNOPSIS	WordAfterFlag list flag 
#  FUNCTION	Returns the entry in $list that is right after $flag (if exists)
#  INPUTS	a list $list and a string $flag
#  OUTPUT	a srting, which is the word in $list which is right after $flag 
#		- if exists - if not, the empty string is returned.
proc WordAfterFlag { list flag } {
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
#  SYNOPSIS	ZeroesPad num length 
#  FUNCTION	adds zeroes to the LHS of $number for it to be of string length
#		$length
#  INPUTS	a number $num and an integer $length
#  OUTPUT	a srting, of length $length made of padding $num with zeroes on
#		the LHS.If the length of $num is greater than $length, 
#		the procedure will return $num.
proc ZeroesPad { num length } {
   return "[bar 0 [expr $length - [string length $num]]]$num"
}
##############################

##############################
#  SYNOPSIS	ZeroesErase num
#  FUNCTION	erase all zeroes at the LHS of $num. The number "0" returns "0"
#		(and not "")
#  INPUTS	an integer $length
#  OUTPUT	a number, that is made of erasing all zeroes at the LHS of $num.
#		If $num == 0, the procedure returns 0
proc ZeroesErase { num } {
   regsub {^0*(.+)$} $num {\1} num
   return $num
}
##############################

##############################
#  SYNOPSIS	Hex2Bin hex_list 
#  FUNCTION	turns a list of hexa munbers into a list of binary numbers
#  INPUTS	a list $list of hexadecimal numbers
#  OUTPUT	a list, which is made of the numbers of $list, represented in 
#		Binary base.
proc Hex2Bin { hex_list } {
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
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc LengthMaxWord {_list} {
   set maxLength 0
   foreach field $_list {
      if {[string length $field] > $maxLength } {
         set maxLength [string length $field]
      }
   }
   return $maxLength
}
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc AddSpaces {_word _desiredLength} {
   set wordLength [string length $_word]
   if {$wordLength >= $_desiredLength } {
      return $_word
   } else {
      return "$_word[string repeat " " [expr $_desiredLength - $wordLength]]"
   }
}
##############################

##############################
#  SYNOPSIS	ProcName args (<- args may be a positive integer)
#  FUNCTION	Return the name of the calling proc 
#  INPUTS	optinally - a positive integer
#  OUTPUT	the name of the calling proc 
#		(if $args != "" -> the name of the calling proc $args levels up)
proc ProcName { args } {
   set upLevels 0
   if { $args != "" } { set upLevels $args }
   return [lindex [info level [expr [info level] -1 -$upLevels]] 0]
}
##############################
proc cutDown { str symbol maxLength} {
   if {[string length $str] <= $maxLength} { return $str}
   for {set i [string first $symbol $str] ;set y 0} {$i < [string length $str] && $i!= -1} \
      {set y $i ;set i [string first $symbol $str $i]} {
         puts "$i $y [expr $i -$y] X[string index $str $i]X"
      }
}
##############################
# get a list of numbers and generate a nice consolidated sub list
proc groupNumRanges {nums} {
   if {[llength $nums] <= 1} {
      return [lindex $nums 0]
   }

   set start -1
   set res ""
   set snums [lsort -integer $nums]
   set last [lrange $snums end end]
   set start [lindex $snums 0]
   set end $start
   foreach n $snums {
      if {($n > $end + 1)} {
         if {$start == $end} {
            append res "$end,"
         } else {
            append res "$start..$end,"
         }
         set start $n
         set end $n
      } else {
         set end $n
      }
   }
   if {$start == $end} {
      append res "$end,"
   } else {
      append res "$start..$end,"
   }
   return "\[[string range $res 0 end-1]\]"
}

# process every group by splitting it to pre num and post
# then look for matches and build next groups
proc groupingEngine {groups} {
   set res {}
   foreach group $groups {
      set idx [lindex $group 0]
      set word [lindex $group 1]

      # try to find a number on the right of the idx:
      set prefix [string range $word 0 [expr $idx -1]]
      set suffix [string range $word $idx end]
      if {![regexp {([^0-9]*)([0-9]+)(.*)} $suffix d1 w1 num w3]} {
         # no number - just keep this group
         lappend res $group
         continue
      }

      append prefix $w1
      set suffix $w3
      set key "$prefix $suffix"
      lappend NEW_GROUPS($key) $num
   }

   # go over all new groups and see if we can collapse them:
   foreach pNs [lsort [array names NEW_GROUPS]] {
      set ranges [groupNumRanges $NEW_GROUPS($pNs)]
      foreach range $ranges {
         set prefix [lindex $pNs 0]
         set suffix [lindex $pNs 1]
         set gIdx [expr [string length $prefix] + [string length $range]]
         lappend res "$gIdx $prefix$range$suffix"
      }
   }
   return $res
}

# Algorithm:
# split the given words on the first number
# then group on the leading string and sort for continoues
proc compressNames {words} {
   # we need to prepare the first stage which is a list of words and
   # simply the index 0 for were to start the search for integers
   foreach word $words {
      lappend groups [list 0 $word]
   }

   # now call the grouping engine
   set prevGroups 0
   while {$prevGroups != [llength $groups]} {
      set prevGroups [llength $groups]
      set groups [groupingEngine $groups]
   }

   set res ""
   foreach group $groups {
      append res [lindex $group 1] " "
   }
   return $res
}


######################################################################
### Sending queries (MADs and pmGetPortCounters) over the fabric
######################################################################

##############################
#  SYNOPSIS	
#	SmMadGetByDr mad cget args
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
#	and $G(detect.bad.links) to decide whether to run DetectBadLinks
proc SmMadGetByDr { mad cget args } {
   global G errorInfo
   # Setting the send and cget commands
   set getCmd [concat "sm${mad}Mad getByDr $args"]
   if {[regexp {^-} $cget]} {
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
      return [DetectBadLinks $status "$cgetCmd" $mad $args]
   } elseif { $status != 0 } {
      return -code 1 -errorcode $status
   } else {
      return [eval $cgetCmd]
   }
   
}
##############################
proc SmMadGetByLid { mad cget args } {
   global G errorInfo
   # Setting the send and cget commands
   set getCmd [concat "sm${mad}Mad getByLid $args"]
   if {[regexp {^-} $cget]} {
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
   if { $status != 0 } {
      return -code 1 -errorcode $status
   } else {
      return [eval $cgetCmd]
   }
}



##############################
#  SYNOPSIS	
#	PmListGet Lid:Port
#  FUNCTION	
#	returns the info of PM info request : pmGetPortCounters $Lid $Port
#  INPUTS	
#	$LidPort - the lid and port number for the pm info request
#		format: lid:port (the semicolon - historic)
#  OUTPUT	
#	the relevant PM (Performance Monitors) info for the $port at $lid
#  DATAMODEL	
#	the proc uses $G(argv,failed.retry) - for stopping failed retries 
proc PmListGet { LidPort } {
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
### Handling Duplicated Guids
######################################################################
##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc AdvncedMaskGuid { {_increment 1}} {
   #ASSUME MASK GUID FORMAT IS HARD CODED 
   global MASK
   if {![string is integer $_increment]} {
      puts "$_increment is not a valid value"
      return 0
   }
   incr MASK(CurrentMaskGuid) $_increment
}
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc GetCurrentMaskGuid {} {
   global MASK
   set tmp $MASK(CurrentMaskGuid)
   set tmp [format %08x $tmp]
   set tmp "0xFFFFFFFF${tmp}"
   return $tmp
}
##############################


##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc BoolIsMaked { _currentMaskGuid} {
   return [string equal MASK [string range $_currentMaskGuid 0 3]]
}
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc RetriveRealPort { _currentMaskGuid} {
   global MASK
   set tmpGuid $_currentMaskGuid
   while {[BoolIsMaked $tmpGuid]} {
      if {![info exists MASK(PortMask,$tmpGuid)]} {
         return -1
      }
      set tmpGuid $MASK(PortMask,$tmpGuid)
   }
   return $tmpGuid
}

######################################################################
### Detecting bad links on a path on which a packet was lost
######################################################################

##############################
#  SYNOPSIS	
#	PathIsBad path
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
#	proc DetectBadLinks, and that denotes the reasons (errors) why the link
#	at the end of DirectPath was found to be bad.
proc PathIsBad { path } { 
   global G
   for { set i 0 } { $i < [llength $path] } { incr i } { 
      if { [info exists G(bad,paths,[lrange $path 0 $i])] } { return 1 }
   }
   return 0
}
##############################

##############################
#  SYNOPSIS	
#	DetectBadLinks starting cgetCmd cmd args
#  FUNCTION	
#	Explores the direct route on which $cmd failed, and detects bad link(s)
#	along this path.
#	The exploration algorithm:... TODO: fill this in ...
#	The bad are then written to the database $G(bad,links,*).
#	This proc is called by the proc "SmMadGetByDr", when the global variable 
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
#	 because it will be used in proc "DiscoverHiddenFabric".
#	$InfoPm(<PM>) - the width-in-bits of each PM and its error threshold

proc DetectBadLinks { status cgetCmd cmd args } { 
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
      if {![catch {set LID0 [GetParamValue LID $path0 $port0 -noread]}]} { 
         if { $LID0 != 0 } { lappend LidPortList "$LID0:$port0:$ShortPath" }
      }
      set path1 $ShortPath
      catch { unset port1 }
      catch { set port1 [GetParamValue PortNum $ShortPath -noread] }
      if {![catch {set LID1 [GetParamValue LID $path1 $port1 -noread]}]} { 
         if { $LID1 != 0 } { lappend LidPortList "$LID1:$port1:$ShortPath" }
      }
   }
   # Initial reading of Performance Counters
   foreach LidPortPath $LidPortList {
      set LidPort [join [lrange [split $LidPortPath :] 0 1] :]
      catch { set oldValues($LidPort) [join [PmListGet $LidPort]] }
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
      if {[catch { set newValues [join [PmListGet $Lid:$Port]] }]} { continue }
      foreach entry [ComparePMCounters $oldValues($Lid:$Port) $newValues] {
         if { ! [WordInList "$Path" $G(list,badpaths)] } {
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
   if { ! [WordInList "$ShortPath" $G(list,badpaths)] } {
      lappend G(list,badpaths) $ShortPath
   }
   return $data
}
######################################################################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	

proc ComparePMCounters { oldValues newValues args } {
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

      set oldValue	[WordAfterFlag $oldValues $parameter]
      set newValue	[WordAfterFlag $newValues $parameter]
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

##############################
#  SYNOPSIS	
#	BadLinksUserInform
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
proc BadLinksUserInform { } { 
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
##############################
#  SYNOPSIS	
#	DiscoverFabric 
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
#       
#       MASK(CurrentMaskGuid)           : <MaskGuid>
#       MASK(PortMask,<PortMask>)       : <PortGuid>
#       MASK(NodeMask,<NodeMask>)       : <NodeGuid>
#       MASK(PortGuid,<PortGuid>)       : <PortMask>
#       MASK(NodeGuid,<NodeGuid>)       : <NodeMask>
#  INPUTS NULL
#  OUTPUT NULL

proc DiscoverFabric { } {
   global G DUP MASK Neighbor SM
   debug "771" -header
   inform "-V-discover:start.discovery.header"
   set index [expr [llength $G(list,DirectPath)] -1]
   set possibleDuplicatePortGuid 0
   set MASK(CurrentMaskGuid) 1
   set listBadPath [list ]
   while { $index < [llength $G(list,DirectPath)] } {
      set DirectPath [lindex $G(list,DirectPath) $index]
      incr index
      # if DirectPath, or its son are bad - continue
      if {[PathIsBad $DirectPath]} { 
         RemoveDirectPath $DirectPath
         continue 
      }

      inform "-V-discover:discovery.status" -index $index -path "$DirectPath"
      inform "-I-discover:discovery.status"
      # Reading NodeInfo across $DirectPath (continue if failed)
      if {[catch {set NodeInfo [SmMadGetByDr NodeInfo dump "$DirectPath"]}]} {
         RemoveDirectPath $DirectPath
         continue
      }
      if {[PathIsBad $DirectPath]} { 
         RemoveDirectPath $DirectPath
         continue 
      }
      set NodeGuid [WordAfterFlag $NodeInfo "-node_guid"]
      set PortGuid [WordAfterFlag $NodeInfo "-port_guid"]
      set EntryPort [GetEntryPort $DirectPath -byNodeInfo $NodeInfo]
      set boolNodeGuidknowen [expr ([lsearch $G(list,NodeGuids) $NodeGuid]!= -1)]
      set boolPortGuidknowen [expr ([lsearch $G(list,PortGuids) $PortGuid]!= -1)]

      set duplicatedGuidsFound ""

      if {$boolPortGuidknowen && !$boolNodeGuidknowen} {
         set preDrPath $G(DrPathOfGuid,$PortGuid)
         lappend duplicatedGuidsFound port
      }
      if {!$boolPortGuidknowen && $boolNodeGuidknowen} {
         set tmpPortGuid [lindex [array get G PortGuid,$NodeGuid:*] 1]
         set preDrPath $G(DrPathOfGuid,$tmpPortGuid)

         set type_1 [GetParamValue Type $preDrPath]
         set type_2 [GetParamValue Type $DirectPath -byDr]

         if {$type_1 != $type_2} { lappend duplicatedGuidsFound node }

         if {$type_2 != "SW"} {
            if {[info exists Neighbor($NodeGuid:$EntryPort)]} {
               lappend duplicatedGuidsFound node
            }
         } elseif {[CheckDuplicateGuids $NodeGuid $DirectPath 1]} {
            lappend duplicatedGuidsFound node
         }
      }
      if {$boolPortGuidknowen && $boolNodeGuidknowen } {
         set boolMatchedBefore  [expr ($NodeGuid == $G(NodeGuid,$PortGuid))]
         if {!$boolMatchedBefore} {
            set tmpPortGuid [lindex [array get G PortGuid,$NodeGuid:*] 1]
            set preDrPath $G(DrPathOfGuid,$tmpPortGuid)
         } else {
            set preDrPath $G(DrPathOfGuid,$PortGuid)
         }

         set type_1 [GetParamValue Type $preDrPath]
         set type_2 [GetParamValue Type $DirectPath -byDr]

         if {$type_1 != $type_2} { lappend duplicatedGuidsFound node port }

         if {$type_2 != "SW"} {
            if {[info exists Neighbor($NodeGuid:$EntryPort)]} {
               lappend duplicatedGuidsFound node port
            }
         } elseif {[CheckDuplicateGuids $NodeGuid $DirectPath 1]} {
            lappend duplicatedGuidsFound node port
         }
      }
      foreach element $duplicatedGuidsFound {
         if {$element == "port"} {
            set tmpGuid $PortGuid
            lappend DUP($PortGuid,PortGUID) $preDrPath
            lappend DUP($PortGuid,PortGUID) $DirectPath
         } else {
            set tmpGuid $NodeGuid
            lappend DUP($NodeGuid,NodeGUID) $preDrPath
            lappend DUP($NodeGuid,NodeGUID) $DirectPath
         }
         # Add The folloing lines to get real time report on duplicate guids
         #inform "-E-discover:duplicated.guids" -guid $tmpGuid \
            #    -DirectPath0 $G(DrPathOfGuid,$PortGuid) \
            #    -DirectPath1 $DirectPath -port_or_node $element
      }

      if {[lsearch $duplicatedGuidsFound port]!= -1} {
         set currentMaskGuid [GetCurrentMaskGuid]
         set G(GuidByDrPath,$DirectPath)  $currentMaskGuid
         set MASK(PortMask,$currentMaskGuid) $PortGuid
         set MASK(PortGuid,$PortGuid) $currentMaskGuid 
         set PortGuid $currentMaskGuid
         AdvncedMaskGuid
      }
      if {[lsearch $duplicatedGuidsFound node]!= -1} {
         set currentMaskGuid [GetCurrentMaskGuid]
         set MASK(NodeMask,$currentMaskGuid) $NodeGuid
         set MASK(NodeGuid,$NodeGuid) $currentMaskGuid
         set NodeGuid $currentMaskGuid
         AdvncedMaskGuid
      }

      set G(GuidByDrPath,$DirectPath) $PortGuid

      # check if the new link allready marked - if so removed $DirectPath
      # happens in switch systems and when a switch connects to himself
      if {![SetNeighbor $DirectPath $NodeGuid $EntryPort]} {
         set G(list,DirectPath) [RemoveElementFromList $G(list,DirectPath) $DirectPath ]
         unset G(GuidByDrPath,$DirectPath)
         incr index -1
         continue
      }

      set NodeType [GetParamValue Type $DirectPath -byDr]
      set boolNodeGuidknowen [expr ([lsearch $G(list,NodeGuids) $NodeGuid]!= -1)]
      # The next condition means - if we reached to allready visited Switch
      if {($boolNodeGuidknowen) && ($NodeType == "SW")} {
         continue
      }

      # The next line makes sure we only count the unknowen Nodes
      if {!(($boolNodeGuidknowen) && ($NodeType == "CA"))} {
         incr G(Counter,$NodeType)
      }

      set G(DrPathOfGuid,$PortGuid) $DirectPath
      if {!$boolNodeGuidknowen} {lappend G(list,NodeGuids)  $NodeGuid}
      if {!$boolPortGuidknowen} {lappend G(list,PortGuids)  $PortGuid}

      set G(NodeGuid,$PortGuid) $NodeGuid
      set G(NodeInfo,$NodeGuid) $NodeInfo
      set G(PortGuid,$NodeGuid:$EntryPort) $PortGuid

      foreach ID "SystemGUID LID" {
         set value [GetParamValue $ID $DirectPath 0]
         lappend DUP($value,$ID) "$DirectPath"
      }

      # Update Neighbor entry In the Array
      if {[llength $DirectPath] > 0} {
         SetNeighbor $DirectPath $NodeGuid $EntryPort
      }
      if {[catch {set tmpNodeDesc [SmMadGetByDr NodeDesc -description "$DirectPath"]}]} {
         set G(NodeDesc,$NodeGuid) "UNKNOWN"
      } else {
         set G(NodeDesc,$NodeGuid) $tmpNodeDesc
      }
      
      if { $NodeType != "SW" } {
         set PortsList $EntryPort
      } else {
         set Ports [GetParamValue Ports $DirectPath -byDr]
         set PortsList ""
         for { set port 0 } { $port <= $Ports } { incr port } {
            lappend PortsList $port
         }
      }

      # TODO : fix this
      foreach port $PortsList {
         if {[catch {set tmpPortInfo [SmMadGetByDr PortInfo dump "$DirectPath" $port]}]} {
            break
         }
         if { $NodeType == "CA" } {
            set tmpCapabilityMask [WordAfterFlag $tmpPortInfo -capability_mask]    
            if {[expr 2 & $tmpCapabilityMask]} {
               set tmpLID [GetParamValue LID $DirectPath $port]
               if {![catch {set tmpSMInfo [SmMadGetByLid SMInfo dump $tmpLID ]}]} {
                  set tmpPriState [format %x [WordAfterFlag $tmpSMInfo -pri_state]]
                  set SM(PriState,$DirectPath) $tmpPriState
               }
            }
         }
         set G(PortInfo,$NodeGuid:$port) $tmpPortInfo
         
         # The loop for non-switch devices ends here.
         # This is also an optimization for switches ..
         if { ( ($index != 1) && ($port == $EntryPort) ) || ($port == 0) } {
            continue
         }
         if { ( [GetParamValue LOG $DirectPath $port] == "DWN" ) } {
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
##############################

##############################
#  SYNOPSIS	
#	SetNeighbor
#  FUNCTION	
#	setting the Neighbor info on the two end node 
#  INPUTS	
#	_directPath _nodeGuid _entryPort 
#  OUTPUT	
#       return 0/1 if Neighbor exists/not exists (resp.)
#  DATAMODEL	
#   G(Neighbor,<NodeGuid>:<PN>) 
proc SetNeighbor {_directPath _nodeGuid _entryPort} {
   global G Neighbor
   set previousDirectPath [lrange $_directPath 0 end-1]
   if {![llength $_directPath] } {
      return 1
   }
   if {![info exists G(GuidByDrPath,$previousDirectPath)]} {
      return 1
   }
   set tmpRemoteSidePortGuid $G(GuidByDrPath,$previousDirectPath)
   if {![info exists G(NodeGuid,$tmpRemoteSidePortGuid)]} {
      return 1
   }
   set tmpRemoteSideNodeGuid $G(NodeGuid,$tmpRemoteSidePortGuid)
   if {[info exists Neighbor($_nodeGuid:$_entryPort)]} {
      return 0
   }
   if {[info exists Neighbor($tmpRemoteSideNodeGuid:[lindex $_directPath end])]} {
      return 0
   }
   set Neighbor($_nodeGuid:$_entryPort) "$tmpRemoteSideNodeGuid:[lindex $_directPath end]"
   set Neighbor($tmpRemoteSideNodeGuid:[lindex $_directPath end]) "$_nodeGuid:$_entryPort"
   return 1
}
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc DiscoverHiddenFabric {} { 
   global G
   debug "1049" -header G(list,badpaths)

   foreach badPath $G(list,badpaths) {
      set allPaths $G(list,DirectPath)
      debug "1046" allPaths badPath
      while {[set idx [lsearch -regexp $allPaths "^$badPath \[0-9\]"]]>=0} {
         set longerPath [lindex $allPaths $idx]
         set allPaths [lreplace $allPaths 0 $idx]
         if {[PathIsBad $longerPath]} { continue }
         set tmpPortGuid $G(GuidByDrPath,$longerPath) 

         if {[catch {set NodeGuid $G(NodeGuid,$tmpPortGuid)}]} { continue }
         foreach path2guid $G(DrPathOfGuid,$tmpPortGuid) {
            if {[PathIsBad $path2guid]} { continue }
            set GoodPath $path2guid
         }
         lappend G(list,DirectPath) $path2guid
         DiscoverFabric
         break
      }
   }
}
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
# check if the node guid neighbors (by guid) match the 
# neighbors of that node by DR
# _checks is the number of neighbors to check
proc CheckDuplicateGuids { _NodeGuid _DirectPath {_checks 1}} { 
   global Neighbor
   set i 0

   # we can not DR out of HCA so we can return 1 anyway
   ## If Checking a HCA, one cannot enter and exit the HCA,
   ### So instead we will run the smNodeInfoMad on the partiel Dr.
   foreach name [array names Neighbor $_NodeGuid,*] {
      if {$i >= $_checks} { break }
      incr i
      if {[regexp {0x[0-9a-fA-F]+:([0-9]+)} $name all PN]} {
         lappend portList $PN

         if { [GetParamValue LOG $_DirectPath $PN] == "DWN"} {
            #Found A port that once wasn't down and now it isn't
            #return 1
         }
         if {[catch {set NodeInfo [SmMadGetByDr NodeInfo dump "$_DirectPath $PN"]}]} {
            continue
         }
         set NodeGuid [WordAfterFlag $NodeInfo "-node_guid"]
         set EntryPort [GetEntryPort "$_DirectPath $PN" -byNodeInfo $NodeInfo]
         if {$Neighbor($name) != "$NodeGuid:$EntryPort"} {
            return 1
         }
      }
   }
   return 0
}
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc CheckBadLidsGuids { args } {
   global G DUP

   ### Checking for zero and duplicate IDs
   foreach entry [lsort [array names DUP]] {
      regexp {^([^:]*),([^:]*)$} $entry all value ID
      # llength will be diffrent then 1 when duplicate guids acored
      if { ( ( [llength $DUP($entry)]==1 ) || ( $ID=="SystemGUID" ) ) \
              && ( $value != 0 ) } {
         continue
      }
      set idx 0
      set paramList ""
      foreach DirectPath $DUP($entry) {
         append paramList " -DirectPath${idx} \{$DirectPath\}"
         incr idx
      }
      # use eval on the next line because $paramList is a list 
      eval inform "-E-discover:zero/duplicate.IDs.found" -ID $ID -value $value $paramList
   }
}
##############################

##############################
#  SYNOPSIS	
#	DiscoverPath Path2Start node
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
#	Similarly to DiscoverFabric, the prod uses and updates these arrays 
#	G(NodeInfo,<NodeGuid>)
#	G(list,DirectPath)
#	Additionally, the following database is maintained:
#	G(DrPath2LID,<DirectPath>): 
#		the LID of the entry port at the end of <DirectPath>
#	Also used: G(argv,* ) (= the parsed command line arguments) is used to
#	specify the addressing mode; and the pointer to the merged fabric 
#	G(fabric,merged) (= the ibdm merging of topo file and .lst file)
proc DiscoverPath { Path2Start node } {
   ### TODO: there is a special case when addressing the local node;
   # for every tool, check that this case is properly treated.
   # ibdiagnet - not relevant
   # ibtrace - OK
   debug "943" -header
   global G errorCode errorInfo

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
   if { ($Path2Start != "") && [GetParamValue Type $Path2Start] != "SW" } {
      set Path2Start [lreplace $Path2Start end end]
   }
   set DirectPath $Path2Start

   while { 1 } {
      # Step #1: get the NodeGuid of $DirectPath
      if {[catch {set NodeInfo [SmMadGetByDr NodeInfo dump "$DirectPath"]}]} {
         break
      }
      if {[PathIsBad $DirectPath]} { break }
      debug "981" DirectPath NodeInfo

      set NodeGuid [WordAfterFlag $NodeInfo "-node_guid"]
      set PortGuid [WordAfterFlag $NodeInfo "-port_guid"]
      set EntryPort [GetEntryPort $DirectPath -byNodeInfo $NodeInfo]

      set G(GuidByDrPath,$DirectPath) $PortGuid
      set G(DrPathOfGuid,$PortGuid)   $DirectPath
      set G(NodeGuid,$PortGuid)       $NodeGuid
      set G(NodeInfo,$NodeGuid)       $NodeInfo
      set DirectPath [join $DirectPath]
      set G(NodeInfoByDr,$DirectPath) $NodeInfo

      if {[catch {set tmpNodeDesc [SmMadGetByDr NodeDesc -description "$DirectPath"]}]} {
         set G(NodeDesc,$NodeGuid) "UNKNOWN"
      } else {
         set G(NodeDesc,$NodeGuid) $tmpNodeDesc
      }
      if { ! [WordInList $DirectPath $G(list,DirectPath)] } { 
         lappend G(list,DirectPath) $DirectPath 
      }

      set NodeType	[GetParamValue Type $DirectPath -byDr]
      set NodePorts	[GetParamValue Ports $DirectPath -byDr]

      set NodeLid	[GetParamValue LID $DirectPath -port $EntryPort]
      if { $NodeLid == "0x" } { break }
      if { $NodeType == "SW" } { 
         set G(DrPath2LID,$DirectPath:0) $NodeLid 
      } else { 
         set G(DrPath2LID,$DirectPath:$EntryPort) $NodeLid
      }
      
      set lidGuidDev "[DrPath2Name $DirectPath -lidGuidDev]"

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
                          [SmMadGetByDr LftBlock dump "$DirectPath" $blockNum]}] {
               if { $errorCode == 0x801c } {
                  inform "-E-ibtrace:fdb.block.unreachable" \
                     -errorcode $errorCode -command "$cmd"
               }
               break 
            }
            if {[PathIsBad $DirectPath]} { break }
            
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
      if { [GetParamValue LOG $DirectPath $exitPort] == "DWN" } {
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

   # TODO: How to handle the situation when [PathIsBad $DirectPath] ?
   if {[PathIsBad $DirectPath]} { 
      BadLinksUserInform
      catch { close $G(logFileID) }
      exit $G(status,discovery.failed)
   }
   return [list $DirectPath]
}
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc RereadLongPaths {} { 
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
            if {[PathIsBad $DirectPath]} { break }
            if {[catch { SmMadGetByDr NodeDesc dump "$DirectPath"}]} { break }
         }
      }
   }
   return
}
######################################################################

######################################################################
### If a topology file is given
######################################################################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc matchTopology { lstFile args } {
   global G

   putsIn80Chars " "
   if { [info exists G(argv,report)] || [info exists G(argv,topo.file)] } {
      set G(fabric,.lst) [new_IBFabric]
      IBFabric_parseSubnetLinks $G(fabric,.lst) $lstFile
   }
   if { ! [info exists G(argv,topo.file)] } { return }

   # Matching defined and discovered fabric
   if { [info exists G(LocalDeviceDuplicated)] } { 
      if {[info exists G(argv,topo.file)] && [info exists G(sys.name.guessed)]} {
         inform "-W-topology:localDevice.Duplicated" 
      }
   }
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
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc reportTopologyMatching { args } {
   global G
   if { ! [info exists G(argv,topo.file)] } { return }
   set noheader [WordInList "-noheader" $args] 
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
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
# support LID , PortGUID , NodeGUID , EntryPort , Type , DevID ,Name
proc DrPath2Name { DirectPath args } {
   global G 
   set lidGuidDev [WordInList "-lidGuidDev" $args]
   set fullName [WordInList "-fullName" $args]
   # TODO : the next two lines have no affect
   if {[set getPortName [WordInList "-port" $args]]} { 
      set port [WordAfterFlag $args "-port"]
   }
   if { $fullName || $lidGuidDev } { 
      set NodeGuid	[GetParamValue NodeGUID $DirectPath -byDr]
      set NodeDevID	[expr [GetParamValue DevID $DirectPath -byDr]]
      set NodePorts	[GetParamValue Ports $DirectPath -byDr]
      set EntryPort   [GetEntryPort $DirectPath]
      set NodeLid	[GetParamValue LID $DirectPath $EntryPort]
      set lidGuidDev	"lid=$NodeLid guid=$NodeGuid dev=$NodeDevID"
   } else {
      set lidGuidDev	""
   }
	
   if { ( ![info exists G(argv,topo.file)] ) || ( 1==$lidGuidDev ) } {
      if {![catch {set deviceType [GetParamValue Type $DirectPath -byDr]}]} {
         if {$deviceType == "CA"} {
            if {![catch {set nodeDesc [lindex [GetParamValue NodeDesc $DirectPath] 0]}]} {
               set res $nodeDesc
               if {[llength $lidGuidDev] != 0} {
                  append res " $lidGuidDev"
               }
               return $res
            }
         }
      }

      return $lidGuidDev
   }
   # set nodeName $G(argv,sys.name)
   set path $DirectPath
   set topoNodesList [join [IBFabric_NodeByName_get $G(fabric,.topo)]]
   if { [set nodePointer [WordAfterFlag $topoNodesList $G(argv,sys.name)]] == "" } {
      return $lidGuidDev
   }

   while { [llength $path] > 0 } { 
      set port [lindex $path 0]
      set path [lrange $path 1 end]

      set nodePorts	[IBNode_Ports_get $nodePointer]
      set portPointer [IBNode_getPort $nodePointer $port]

      if {$portPointer != ""} {
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
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
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
      if {[WordInList "-node" $args]} { 
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

##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
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
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
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
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc reportFabQualities { } { 
   global G SM
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

   # SM report
   set totalSM [llength [array names SM]]
   inform "-I-ibdiagnet:SM.header"
   if {$totalSM == 0} {
      inform "-W-ibdiagnet:no.SM"
   } else {
      for {set i 0} {$i < [llength [array get SM *]]} {incr i 2} {
         set tmpValue [lindex [array get SM *] [expr $i +1]]
         set tmpEntry "[expr $tmpValue%10][expr $tmpValue/10]"
         lappend SMList "{[lindex [array get SM *] $i]} $tmpEntry"
      }
      set SMList [lsort -index 1 -decreasing $SMList]
      set tmpStateList "not-active dicovering standby master"
      foreach element $SMList {
         set tmpDirectPath [lindex [split [lindex $element 0] ,] end]
         if { $tmpDirectPath == "" } {
            set nodeName "Local Device/P[GetEntryPort $tmpDirectPath]"
         } else {
            set DrPath2Name_1 [DrPath2Name $tmpDirectPath]
            set nodeName "$DrPath2Name_1/P[GetEntryPort $tmpDirectPath]"
         }
         set tmpPriState [lindex $element 1]
         set tmpState [lindex $tmpStateList [expr $tmpPriState/10]]
         puts "\t$nodeName\tstate:$tmpState\tpriorty:[expr $tmpPriState%10]"
      }
   }

   inform "-I-ibdiagnet:report.fab.qualities.header"


   # general reports
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
         putsIn80Chars "$mgid | 0x[format %x $mlid] | [compressNames $mlidHcas]"
      }
   }
   return
}
######################################################################

######################################################################
### .lst format settings
######################################################################
# The pocedure GetParamValue needs the database $G(list,DirectPath) 
# returns the value of a parameter of a port in .lst file format

### These used to be a part of infoLst
# LinFDBTop { -source SwitchInfo -flag lin_top  -width 16 }
# FDBs	 { -source LftBlock -width 0 }
##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc GetEntryPort { _directPath args} {
   global G infoLst Neighbor

   if {$_directPath == ""} {
      set NodeInfo [SmMadGetByDr NodeInfo dump ""]    
      set _port_num_vendor_id [WordAfterFlag $NodeInfo "-port_num_vendor_id"]
      return [format %d [FormatInfo $_port_num_vendor_id PortNum NONE]]
   }

   if {[info exists G(GuidByDrPath,$_directPath)]} {
      set tmpGuid $G(GuidByDrPath,[lrange $_directPath 0 end-1])
      set tmpGuid $G(NodeGuid,$tmpGuid)
      set entryPort $Neighbor($tmpGuid:[lindex $_directPath end])
      return [lindex [split $entryPort :] end ]
   }

   if {[lsearch -exac $args "-byNodeInfo"]!=-1} {
      set nodeInfo [WordAfterFlag $args "-byNodeInfo"]
      set _port_num_vendor_id [WordAfterFlag $nodeInfo "-port_num_vendor_id"]
      return [format %d [FormatInfo $_port_num_vendor_id PortNum NONE]]
   } elseif {$_directPath == ""} {
      return -code 1 -errorinfo "Can't retrive entry port"
   }

   set tmpGuid $G(GuidByDrPath,$_directPath)
   set tmpGuid $G(NodeGuid,$tmpGuid)
   set entryPort $Neighbor($tmpGuid,[lindex $_directPath end])
   puts "EntryPort $entryPort"
}
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	

proc GetParamValue { parameter DirectPath args } {
   global G infoLst
   # debug "1198" -header
   set DirectPath "[join $DirectPath]"
   if { ! [WordInList $DirectPath $G(list,DirectPath)] } {
      return -code 1 -errorinfo "Direct Path \"$DirectPath\" not in $G(list,DirectPath)"
   }

   # noread - if info doesn't exists don't try to get it by dr
   set byDr 0       
   set noread 0
   if {[lsearch -exac $args "-byDr"] != -1} { set byDr 1 }
   if {[lsearch -exac $args "-noread"] != -1} { set noread 1}

   if {[WordInList $parameter "PortNum PortGuid"]} { set byDr 1 }

   ## Setting the parameter flags
   parseOptionsList $infoLst($parameter) 

   ## Setting the port number
   set port [lindex $args 0]
   if {[info exists cfg(fromport0)]} { 
      if { [GetParamValue Type $DirectPath] == "SW" }  {
         set port 0
      }
   }
   ## setting port/node guids
   if {[info exists G(GuidByDrPath,$DirectPath)]} {
      set PortGuid $G(GuidByDrPath,$DirectPath)
      if {[info exists G(NodeGuid,$PortGuid)]} {
         set NodeGuid $G(NodeGuid,$PortGuid)
      } else {
         set  byDr 1
      }
   } else {
      set  byDr 1
   }
   ### Getting the parameter value 
   set value DZ
   switch -exact -- $parameter { 
      "PN" { return [FormatInfo $port PN $DirectPath] }
      "NodeDesc" { 
         if {[info exists NodeGuid]} {
            return [FormatInfo $G(NodeDesc,$NodeGuid) NodeDesc $DirectPath]
         } 
      }
      default {
         set addPort2Cmd [regexp {(Port|Lft)} $cfg(source)]


         if {$byDr} { set InfoSource "$cfg(source)byDr,$DirectPath" }
         if {[info exists NodeGuid]} {
            set InfoSource "$cfg(source),$NodeGuid"
            if {$addPort2Cmd} { append InfoSource ":$port" }
            if {[info exists G($InfoSource)]} { 
               return [FormatInfo [WordAfterFlag $G($InfoSource) -$cfg(flag)] $parameter $DirectPath]
            }
         }
         if {[info exists G($InfoSource)]} { 
            return [FormatInfo [WordAfterFlag $G($InfoSource) -$cfg(flag)] $parameter $DirectPath]
         } elseif {$noread} { 
            return -code 1 
         } elseif { [PathIsBad $DirectPath] } {
            return -code 1 -errorinfo "Direct Path \"$DirectPath\" is bad"
         } else {
            set Cmd [list SmMadGetByDr $cfg(source) -$cfg(flag) "$DirectPath"]
            if {$addPort2Cmd} { append Cmd " $port" }
            if {[catch { set value [eval $Cmd]}]} { return -code 1 }
         }
      }
   }
   return [FormatInfo $value $parameter $DirectPath]
}

proc FormatInfo {_value _parameter _directRoute} {
   global G infoLst MASK
   set value $_value
   if {"PortGUID" == $_parameter } {
      if {[info exists MASK(PortGuid,$_value)]} {
         return $G(GuidByDrPath,$_directRoute)
      }
   }
   if {"NodeGUID" == $_parameter } {
      if {[info exists MASK(NodeGuid,$_value)]} {
         set tmpPortGuid $G(GuidByDrPath,$_directRoute)
         return $G(NodeGuid,$tmpPortGuid)
      }
   }
   parseOptionsList $infoLst($_parameter)
   ## Formatting $value
   catch { set value [format %x $value] }
   regsub {^0x} $value {} value

   # bits -> bytes
   if {[catch { set width [expr $cfg(width) / 4] }]} { set width "" }

   if {!(( $width == 0 ) || ( ! [regexp {^[0-9]+} $width] )) } {
      if {[info exists cfg(offset)]} { 
         scan $cfg(offset) {%d%[:]%d} offset D bigwidth
         set bigwidth [expr $bigwidth / 4] ;# bits -> bytes
         set offset [expr $offset / 4] ;# bits -> bytes
         set value [ZeroesPad $value $bigwidth]
         set value [string range $value $offset [expr $offset + $width -1]]
      } else { 
         set value [ZeroesPad $value $width]
      }
   }

   if {[info exists cfg(substitution)]} { 
      regsub -all { *= *} [join $cfg(substitution)] {= } substitution
      set value [ZeroesErase $value]
      set value [WordAfterFlag $substitution "$value="] 
   } 
   if { ! [info exists cfg(string)] } {
      set value "0x$value"
   }
   # debug "336" value
   return $value
}
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	
proc linkAtPathEnd { Path } {
   if { [catch { set port1 [GetEntryPort $Path] } ] } { 
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
##############################

##############################
#  SYNOPSIS	
#  FUNCTION	
#  INPUTS	
#  OUTPUT	

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
      regsub {^0x} [GetParamValue $parameter $DirectPath $port] {} value
      # .lst formatting of parameters and their values
      if {[WordInList $parameter "VenID DevID Rev LID PN"]} {
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


proc writeLstFile { args } {
   global G

   set FileID [initOutputFile $G(tool).lst]
   foreach DirectPath $G(list,DirectPath) {
      # seperate the next 3 logical expr to avoid extra work
      if {![llength $DirectPath]  } {continue }
      if {[PathIsBad $DirectPath] } {continue }
      if {[catch {linkAtPathEnd $DirectPath}] } {continue }

      set lstLine ""

      append lstLine "\{ [lstInfo port $path0 $port0] \} "
      append lstLine "\{ [lstInfo port $path1 $port1] \} "
      append lstLine "[lstInfo link $path0 $port0]"
      puts $FileID "$lstLine"
   }
   close $FileID

   return
}

proc writeNeighborFile { args } {
   global Neighbor G

   set FileID [initOutputFile $G(tool).neighbor]
   set preGuid ""
   foreach neighbor [lsort -dictionary [array names Neighbor]] {
      if {($preGuid != [string range $neighbor 0 17]) && ($preGuid != "")} {
         puts $FileID ""
      }
      puts $FileID "$neighbor\t$Neighbor($neighbor)"
      set preGuid [string range $neighbor 0 17]
   }
   close $FileID
   return
}

proc writeMasksFile { args } {
   global MASK G
   set FileID [initOutputFile $G(tool).masks]
   foreach mask [lsort -dictionary [array names MASK *Mask,*]] {
      puts $FileID "$mask\t$MASK($mask)"
   }
   close $FileID
   return
}

proc writeSMFile { args } {
   global SM G
   set FileID [initOutputFile $G(tool).sms]
   set tmpStateList "not-active dicovering standby master"
   puts $FileID "ibdiagnet fabric SM report"

   foreach arrayEntry [array names SM] {
      set tmpDirectPath [lindex [split $arrayEntry ,] end]

      if { $tmpDirectPath == "" } {
         set nodeName "The Local Device/[GetEntryPort $tmpDirectPath]"
      } else {
         set DrPath2Name_1 [DrPath2Name $tmpDirectPath]
         set nodeName "$DrPath2Name_1/P[GetEntryPort $tmpDirectPath]"
      }

      set tmpPriState $SM($arrayEntry)
      set tmpState [lindex $tmpStateList [expr $tmpPriState%10]]
      puts $FileID "$nodeName\tstate:$tmpState\tpriorty:[expr $tmpPriState/10]"
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
proc writeFdbsFile { args } {
   global G

   set FileID [initOutputFile $G(tool).fdbs]

   foreach entry [array names G "DrPathOfGuid,*"] {
      set NodeType [GetParamValue Type $G($entry) -byDr]
      if {$NodeType != "SW"} { continue }
      set DirectPath $G($entry)
      if {[PathIsBad $DirectPath]} { continue }

      set PortGuid [lindex [split $entry ,] end]
      set NodeGuid $G(NodeGuid,$PortGuid) 

      # TODO -WTF
      set thisSwLid [GetParamValue LID $DirectPath X -noread]
      if {[PathIsBad $DirectPath]} { continue }
      if [catch {set LinFDBTop \
                    [SmMadGetByDr SwitchInfo -lin_top "$DirectPath"]}] { 
         continue 
      }
      ### TODO: What if lin_cap < lin_top ?
      set FDBs ""
      for { set I 0 } { [expr $I *64] <= $LinFDBTop } { incr I } {
         # Note "<=" - because LinFDBTop indicates the INDEX of the last 
         # valid entry 
         if [catch {set NewFDBs \
                       [SmMadGetByDr LftBlock dump "$DirectPath" $I] }] { 
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
            puts $FileID "[ZeroesPad $port 3]  : 00   : yes"
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
proc writeMcfdbsFile { } { 
   global G

   set FileID [initOutputFile $G(tool).mcfdbs]

   foreach entry [array names G "DrPathOfGuid,*"] {
      set NodeType [GetParamValue Type $G($entry) -byDr]
      if {$NodeType != "SW"} { continue }
      set DirectPath $G($entry)
      if {[PathIsBad $DirectPath]} { continue }
      set PortGuid [lindex [split $entry ,] end]
      set NodeGuid $G(NodeGuid,$PortGuid) 

      if [catch { set McFDBCap \
                     [SmMadGetByDr SwitchInfo -mcast_cap "$DirectPath"] }] { 
         continue
      }
      set NumPorts [GetParamValue Ports $DirectPath]
      puts $FileID "\nSwitch $NodeGuid\nLID    : Out Port(s) "
      for {set LidGrp 0xc000} {$LidGrp < 0xc000 + $McFDBCap} {incr LidGrp 0x20} {
         set McFDBs ""
         set LidGroup "0x[format %x $LidGrp]"
         # read the entire McFDBs data for Lids $LidGroup .. $LidGroup + 0x1f
         for {set PortGroup 0} {$PortGroup <= $NumPorts} {incr PortGroup 16} {
            if [catch {
               set newBlock \
                  [SmMadGetByDr MftBlock dump "$DirectPath" $LidGroup $PortGroup]
            }] { break }
            append McFDBs " " [Hex2Bin $newBlock]
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
                        if { [GetParamValue Type $LongPath -byDr] != "SW" } { 
                           #DZ
                           set directPathName [DrPath2Name $LongPath]
                           if {$directPathName !=""} {
                              lappend G(mclid2DrPath,0x$mcLid) $directPathName
                           } else {
                              lappend G(mclid2DrPath,0x$mcLid) $LongPath
                           }
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

proc InitalizeIBdiag {} {
   global G argv argv0 InfoArgv infoLst
   set G(version.num) 1.1.0rc2
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
   # if topology matching results have more lines than the following constant,
   # notify the user that his cluster is messed up
   set G(config,warn.long.matchig.results)	20
   # The largest value for integer-valued parameters
   set G(config,maximal.integer)	1000000

   set G(list,badpaths) ""

   set G(list,DirectPath) { "" }
   set G(list,NodeGuids) [list ]
   set G(list,PortGuids) [list ]
   set G(Counter,SW) 0
   set G(Counter,CA) 0

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
}

proc initOutputFile {_fileName} {
   global G 
   regsub {File$} [file extension [ProcName 1]] {} ext
   set ext [file extension $_fileName]
   if {![info exists G(outfiles,$ext)]} {
      puts XX
      inform "-E-outfile:not.valid" -file0 $outfile
   }
   set outfile $G(outfiles,[file extension $_fileName])
   if { [file exists $outfile] && ! [file writable $outfile] } {
      inform "-W-outfile:not.writable" -file0 $outfile -file1 $outfile.[pid]
      append G(outfiles,$ext) ".[pid]"
   }
   inform "-V-outfiles:$ext"
   return [open $G(outfiles,$ext) w]
}

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
   set hcaIndex 1
   set PortNum 0
   set upPorts 0
   set oldPortGuid [lindex [lindex $ibisInfo 0] 0]

   set portNumSet  [info exists G(argv,port.num)]
   foreach entry $ibisInfo {
      scan $entry {%s %s %s} PortGuid PortLid PortState
      # Note that this is used for the 1st iteration, too
      # TODO - FIX the differes by one algo
      # HACK set hcaIndex to 1
      
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
      catch { append namesList " " [SmMadGetByDr NodeDesc -description {}] }
   }
   array set topoNodesArray [join [IBFabric_NodeByName_get $G(fabric,.topo)]]
   array set topoSysArray   [join [IBFabric_SystemByName_get $G(fabric,.topo)]]
   set sysNameSet [info exists G(argv,sys.name)]
   if {![info exists G(argv,sys.name)]} {set G(sys.name.guessed) 1}
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
   
   ### HACK - ibis_get_local isn't ready yet
   foreach portInfo $ibisInfo {
      set portInfo [lrange $portInfo 0 2]
      lappend newIbisInfo $portInfo
   }

   set ibisInfo $newIbisInfo

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

##############################
### Debug related procedure 
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

   set srcProcName [ProcName 1]
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
#  SYNOPSIS	listG
#  FUNCTION	displays (compactly) the entries in the global vars array G
#		if the --G flag was specified in the comand line.
#		This is used for debug purposes.
#		Ran from finishIBDebug.
#  INPUTS	NULL
#  OUTPUT	NULL
proc listG {} {
   global G argv
   if {  [WordInList "--G" $argv] } { 
      foreach entry [lsort [array names G]] {
         puts "$entry : $G($entry)"
      }
      return 1
   }

   if { ! [WordInList "--G" $argv] } { return }
   set Glist ""
   foreach entry [lsort [array names G]] { 
      regsub {,[^,]*$} $entry {,*} head1
      regsub {,[^,]*$} [lindex $Glist end] {,*} head0
      regsub {^PortInfo,[0-9a-fx]+,\*} $head1 {PortInfo,*,*} head1
      regsub {^PortInfo,[0-9a-fx]+,\*} $head0 {PortInfo,*,*} head0
      if { "$head0" == "$head1" } { 
         set Glist [lreplace $Glist en end $head1]
      } else { 
         lappend Glist "$entry" 
      }
   }
   puts "-G- G entries: [join [lsort $Glist] "; "]"
   return
}
