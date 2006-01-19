######################################################################
### Procs:
# putsIn80Chars
# toolsFlags
# parseArgv
# inform
# showHelpPage
######################################################################

######################################################################
## varoius definitions for the command-line arguments:
# name: the name to be used when refering to the flag (e.g., topo.file for -t)
# default: the default value (if exists)
# param: a string describing the value given to the flag - to be written in the tool's synopsys (e.g., the "count" in: [-c <count>])
# -deafult "" means that the parameter does have a default value, but it will set later (after ibis is ran, in porc startIBDebug).
## TODO: sm_key is a 64-bit integer - will it be correctly cheked in parseArgv ?
array set InfoArgv {
    -a,name	"attribute" 
    -a,param	"attr"
    -a,optional	"-field1 val1 -field2 val2 ..."
    -a,desc	"defines the attribute to query or send"

    -c,name	"count"	
    -c,default	10
    -c,param	"count"
    -c,regexp	"integer.nonneg.==1"
    -c,error	"-E-argv:not.nonneg.integer"
    -c,maxvalue	"1000000"

    -d,name	"direct.route" 
    -d,param	"p1,p2,p3,..." 
    -d,desc	"Directed route from the local node to the destination node"
    -d,regexp	"integer.pos.>=0"
    -d,error	"-E-argv:bad.path"
    -d,maxvalue	"0xff"

    -f,name	"failed.retry"
    -f,default	3 
    -f,param	"fail-rtry"
    -f,desc	"number of retries of sending a specific packet"

    -i,name	"dev.idx"	
    -i,default	1 
    -i,param	"dev-index" 
    -i,desc	"Specifies the index of the device of the port used to connect to the IB fabric (in case of multiple devices on the local system)"
    -i,regexp	"integer.pos.==1"
    -i,error	"-E-argv:not.pos.integer"
    -i,maxvalue	"0xff"

    -k,name	"sm.key" 
    -k,desc	"in order to generate \"trusted\" queries the user needs to provide the SM_key"
    -k,regexp	"integer:nonneg:==1"
    -k,error	"-E-argv:not.nonneg.integer"

    -l,name	"lid.route"	
    -l,param	"lid"
    -l,desc	"The LID of destination port"
    -l,regexp	"integer.pos.==1"
    -l,error	"-E-argv:not.pos.integer"
    -l,maxvalue	"0xffff"

    -m,name	"method" 
    -m,param	"meth"
    -m,desc	"send the mad using the given method"

    -n,name	"by-name.route" 
    -n,param	"name"
    -n,desc	"the name of the destination port"
    -n,regexp	{^[^ ,]+$}
    -n,error	"-E-argv:bad.node.name"

    -o,name	"out.dir"	
    -o,default	"/tmp"
    -o,param	"out-dir"
    -o,desc	"Specifies the directory where the output files will be placed"

    -p,name	"port.num"	
    -p,default	"" 
    -p,param	"port-num"
    -p,desc	"Specifies the local device's port number used to connect to the IB fabric"
    -p,regexp	"integer.pos.==1"
    -p,error	"-E-argv:not.pos.integer"
    -p,maxvalue	"0xff"

    -q,name	"query.mode" 
    -q,desc	"starts a \"query mode\"" 
    -q,arglen	0

    -r,name	"report" 
    -r,desc	"Provides a report of the fabric qualities"
    -r,arglen	0

    -s,name	"sys.name"
    -s,default	""
    -s,param	"sys-name"
    -s,desc	"Specifies the local system name. Meaningful only if a topology file is specified"

    -t,name	"topo.file" 
    -t,param	"topo-file"
    -t,desc	"Specifies the topology file name"

    -v,name	"verbose"	
    -v,desc	"Instructs the tool to run in verbose mode"
    -v,arglen	0..1
    -v,regexp	"integer.nonneg.<=1"
    -v,error	"-E-argv:not.nonneg.integer"
    -v,save     "-v,arglen 0..1"
    -v,default  0
    -v,maxvalue	"0xffff"

    -w,name	"wait.time"	
    -w,default	0
    -w,param	"wait-ms"
    -w,desc	"the time in msec to wait from receiving the response to the next send"
    -w,regexp	"integer.nonneg.==1"
    -w,error	"-E-argv:not.nonneg.integer"
    -w,maxvalue	"1000000"

    -h,name	"help"
    -h,desc	"Prints this help information"
    -h,longflag	"--help"

    -V,name	"version"
    -V,desc	"Prints the version of the tool"
    -V,longflag	"--version"

    --vars,name	"version"
    --vars,desc	"Prints the tool's environment variables and their values"
}


### some changes from the default definitions 
# (e.g., for ibtrace, since it recieves addresses of two ports...)

# for simulator
if {[info exists env(IBMGTSIM_DIR)]} {
    set InfoArgv(-o,default) $env(IBMGTSIM_DIR)
}

switch -exact -- $G(tool) { 
    "ibsac" { 
	set InfoArgv(-m,desc) "method to be used - either get or gettable"
	set InfoArgv(-a,desc) "the specific attribute to send"
    }
    "ibcfg"		{ 
	# unset InfoArgv(-q,optional)  G(-q,newline)
	array set InfoArgv {
	    -c,name "config.mode" 
	    -c,default ""
	    -c,param "cmd"
	    -c,desc	"defines the command to be executed"
	    -c,regexp ""
	    -c,arglen "1.."
	}
    }
    "ibdiagnet"	{ 
	set InfoArgv(-c,desc) "The minimal number of packets to be sent across each link"
    }
    "ibping"		{ 
	set InfoArgv(-c,desc) "the total number of packets to be sent"
	set InfoArgv(-c,default) 100
    }
    "ibtrace"		{ 
	array set InfoArgv {
	    -d,desc "directed route from the local node (which is the source) and the destination node"
	    
	    -l,param	"\[src-lid,\]dst-lid"
	    -l,desc	"Source and destination LIDs (source may be omitted -> local port is assumed to be the source)"
	    -l,regexp	"integer.pos.>=1&<=2"
	    -l,error	"-E-argv:not.pos.integers"

	    -n,param	"\[src-name,\]dst-name" 
	    -n,regexp	{^([^ ,]+,)?[^ ,]+$}
	    
	    -v,desc	"Provide full verbosity about the checks performed on every port"

	    -c,default	100
	    -c,desc	"The number of packets to be sent from source to destination nodes"
	}
	set InfoArgv(-n,desc)    "Names of the source and destination ports "
	append InfoArgv(-n,desc) "(as defined in the topology file; source may be omitted "
	append InfoArgv(-n,desc) "-> local port is assumed to be the source)"

    }
}
######################################################################

######################################################################
### parsing the command-line arguments
######################################################################
proc toolsFlags { tool } { 
    # Flags encompassed in ( ) are mandatory. 
    # If a few flags are thus encompassed, then they are mutex
    switch -exact -- $tool { 
	ibping	   { return "(n|l|d) c w v    t s i p o" }
	ibtrace	   { return "(n|l|d) c   v    t s i p o" }
	ibdiagnet { return "        c   v r  t s i p o" }
	ibcfg	   { return "(n|l|d) (c|q)    t s i p o" }
	ibmad	   { return "(m) (a) (n|l|d)  t s i p o ; (q) a" }
	ibsac	   { return "(m) (a) k        t s i p o ; (q) a" }

	envVars	   { return "t s i p" }
	general	   { return "h V -vars" }
    }
}
##############################
#  SYNOPSIS
#  FUNCTION
#  INPUTS
#  OUTPUT
proc HighPriortyFlag {} {
    global argv
    ## If help is needed ...
   if { [WordInList "-h" $argv] || [WordInList "--help" $argv] } {
	inform "-H-help"
    }
    ## output the version number
   if { [WordInList "-V" $argv] || [WordInList "--version" $argv] } {
	inform "-H-version"
    }
    ## list all env-var names
   if { [WordInList "--vars" $argv] } {
	inform "-H-vars"
    }
}

##############################
#  SYNOPSIS
#  FUNCTION
#  INPUTS
#  OUTPUT
proc parseArgv {} {
    global G argv env InfoArgv

    ## If help/version/vars are needed ...
    HighPriortyFlag

    ## Setting default values for command-line arguments 
    foreach entry [array names InfoArgv "*,default"] { 
	set flag [lindex [split $entry ,] 0]
	if {[catch { set name $InfoArgv($flag,name)}]} { continue }
	if { $InfoArgv($entry) != "" } { 
	    set G(argv,$name) $InfoArgv($entry)
	}
    }
    ## defining flags values by means of environment variables
    foreach flag [toolsFlags envVars]  {
	set name $InfoArgv(-$flag,name)
	set envVarName "IBDIAG_[string toupper [join [split $name .] _]]"
	if { ! [info exists env($envVarName)] } { continue }
	if { $env($envVarName) == "" } { continue }
	set G(argv,$name) $env($envVarName) 
    }

    ## mandatory flags
    # The first foreach is for the case when there are two different operatinal 
    # modes of the tool like the case is for ibmad,ibsac
    # HACK: I assume that the different sections have disjoint mandatory flags
    # if this is not true, I'll have to work harder ...
    set toolsFlags [toolsFlags $G(tool)]
    foreach section [split $toolsFlags ";" ] { 
	foreach item $section { 
	    if { ! [regexp {\(} $item] } { continue }
	    if { [regsub -all " $item " " $argv " {} .] == 0 } {
		catch { unset infoFlags }
		break
	    }
	    if {[info exists infoFlags]} { 
		if { $infoFlags != $section } { 
		    inform "-E-argv:nonmutex.flags" \
			-flags [list [join [lindex $infoFlags 0] [lindex $section 0]]]
		}
	    }
	    set infoFlags $section
	}
	# if {[info exists infoFlags]} { break }
    }
    if { ! [info exists infoFlags] } {
	set infoFlags [lindex [split $toolsFlags ";" ] 0]
    }
    foreach item $infoFlags {
	set mandatory [regsub -all {[()]} $item "" item]
	set litem "-[join [split $item |] " -"]"
	set mutexList ""
	foreach arg $argv {
	    append mutexList " " [lindex $litem [lsearch -exact $litem $arg]] 
	}
	set mutexList [lsort $mutexList]
	for { set i 0 } { $i < [llength $mutexList] } { incr i } {
	    if { [lindex $mutexList $i] == [lindex $mutexList [expr $i+1]] } {
		inform "-E-argv:flag.twice.specified" \
		    -flag [lindex $mutexList $i]
	    }
	}
	if { [llength $mutexList] > 1 } {
	    inform "-E-argv:nonmutex.flags" -flags $mutexList
	}
	if { ( [llength $mutexList] == 0 ) && $mandatory } {
	    inform "-E-argv:missing.mandatory.flag" \
		-flag [list $litem]
	}
    }

    set argvList $argv
    # flags-for-debug: for designer user
    foreach flag "--debug --G" {
	set index [lsearch -exact $argvList $flag]
	set argvList [lreplace $argvList $index $index]
    }
    # set G(DBId) [open $G(tool).dbg w]
   # if {[set G(argv,debug) [WordInList "--debug" $argv]]} {
    #     set G(DBId) [open $G(tool).dbg w]
    # }

    regsub -all {[()|]} $infoFlags " " allLegalFlags
    set allLegalFlags "-[join $allLegalFlags " -"]"

    while { [llength $argvList] > 0 } {
	set flag  [lindex $argvList 0]
	set value [lindex $argvList 1]

      if { ! [WordInList $flag $allLegalFlags] } {
	    inform "-E-argv:unknown.flag" -flag $flag
	}
	set argvList [lreplace $argvList 0 0]
      if {[WordInList $flag $argvList]} {
	    inform "-E-argv:flag.twice.specified" -flag $flag
	}

	set arglen 1
	catch { set arglen $InfoArgv($flag,arglen) }
	if { [llength $argvList] == 0 && ![regexp {^0} $arglen] } { 
	    inform "-E-argv:flag.without.value" -flag $flag
	}

	# Checking values validity and setting G(argv,$name) - the flag's value
	set regexp 1
	if { [regexp {^0} $arglen] && [regexp {^\-} $value] } {
	    set value ""
	} elseif {[info exists InfoArgv($flag,regexp)]} {
	    scan [split $InfoArgv($flag,regexp) .] {%s %s %s} type sign len
	    # debug "300" type sign len
	    if { $type == "integer" } {
		# Turn values like 010 into 10 (instead of the tcl value - 8)
		set int "(0x)?0*(\[a-fA-F0-9\]+)"
		set valuesList [split $value ","]
		# Checking if length of integers list is OK
		foreach condition [split $len &] {
		    if { ! [expr [llength $valuesList] $condition] } {
			inform "$InfoArgv($flag,error)" -flag $flag -value $value
		    }
		}
		# Checking that all items in list are integers
		set formattedValue ""
		if {[catch { set maxValue $InfoArgv($flag,maxvalue) }]} { 
		    set maxValue $G(config,maximal.integer)
		}
		foreach item $valuesList {
		    debug "337" item flag maxValue
		    # special case: I allow the command -d ""
		    if { ( [llength [join $item]] == 0 ) && ( [llength $valuesList] == 1 ) } {
			break
		    }
		    if {[catch {format %x $item} err]} {
			if {[regexp "integer value too large to represent" $err]} { 
			    inform "-E-argv:too.large.integer" -flag $flag -value $value
			} else { 
			    inform "$InfoArgv($flag,error)" -flag $flag -value $value
			}
		    }
		    if { ! [regsub "^$int$" $item {\1\2} item] } {
			inform "$InfoArgv($flag,error)" -flag $flag -value $value
		    }
		    if { $sign == "pos" && $item == 0 } {
			inform "$InfoArgv($flag,error)" -flag $flag -value $value
		    }
		    if { $item > $maxValue } {
			inform "-E-argv:too.large.value" \
			    -flag $flag -value $value -maxValue $maxValue
		    }
		    lappend formattedValue [format %d $item]
		}
		set value [join $formattedValue ,]
	    } else {
		set regexp [regexp $InfoArgv($flag,regexp) "$value"]
	    }
	}
	set name $InfoArgv($flag,name)
	set G(argv,$name) ""
	if { $arglen == "1.." } {
	    while { [llength $argvList] > 0 } {
		if { [set I [lsearch -regexp $argvList {^\-}]] == -1 } { 
		    set I [llength $argvList]
		}
		append G(argv,$name) " " [lrange $argvList 0 [expr $I -1]]
		set argvList [lreplace $argvList 0 [expr $I -1]]
            if {[WordInList [lindex $argvList 0] $allLegalFlags]} {
		    break
		} else {
		    append G(argv,$name) " " [lindex $argvList 0]
		    set argvList [lreplace $argvList 0 0]
		}
	    }
	} elseif { $arglen == "0" || \
		       ( ( $arglen == "0..1" ) && ( ( $regexp==0 ) || ( $value=="" ) ) ) } {
	    set G(argv,$name) 1
	} elseif { $regexp } {
	    set G(argv,$name) "$value"
	    set argvList [lreplace $argvList 0 0]
	} else {
	    inform "$InfoArgv($flag,error)" -flag $flag -value $value
	}
    }
    ## If we are using direct-route addressing, the output port of the direct
    # route must not disagree with the local port number (if specified).
    # If the latter was not specified, it is set to be the former.
    if {[info exists G(argv,direct.route)]} {
	set drOutPort [lindex [split $G(argv,direct.route) ","] 0]
	if { $drOutPort == "" } {
	    # do nothing
	} elseif {[info exists G(argv,port.num)]} {
	    if { $drOutPort != $G(argv,port.num) } {
		inform "-E-argv:disagrees.with.dir.route" \
		    -value $G(argv,port.num) -port $drOutPort
	    }
	} else {
	    set G(argv,port.num) $drOutPort
	    set G(-p.set.by.-d) 1
	}
    }

    # extra actions 
    if {[info exists G(argv,out.dir)]} { 
	set dir $G(argv,out.dir)
	if { ! [file isdirectory $dir] } {
	    if {[catch {exec mkdir -- $dir} msg]} { 
		inform "-E-argv:could.not.create.dir" \
		    -flag "-o" -value $dir -errMsg [list $msg]
	    }
	} elseif { ! [file writable $dir] } {
	    inform "-E-argv:dir.not.writable" -flag "-o" -value $dir
	}
	foreach extention { "lst" "fdbs" "mcfdbs" "log" } {
	    set G(outfiles,.${extention}) [file join $dir $G(tool).${extention}]
	}
    }
    set G(logFileID) [open $G(outfiles,.log) w]
    catch { package require ibdm }

    ## TODO: check that direct path/LID/name/sysname exist
   # - this is checked by getArgvPortNames and DiscoverPath

    # If topology is not given and -s/-n  flags are specified
    if { ! [info exists G(argv,topo.file)]  } {
	if {[info exists G(argv,sys.name)]} { 
	    inform "-W-argv:-s.without.-t"
	}
	if {[info exists G(argv,by-name.route)]} { 
	    inform "-E-argv:nodename.without.topology" \
		-value $G(argv,by-name.route)
	}
	inform "-W-argv:no.topology.file"
    # If topology is given, check that $G(argv,by-name.route) are names of existing nodes
    # We do the same for G(argv,sys.name), after ibis_init 
    # - to search for sys.name in the description of the source node
    } else {
	set topoFile $G(argv,topo.file)
	if { ! [file isfile $topoFile] } {
	    inform "-E-argv:file.not.found" -flag "-t" -value $topoFile
	} elseif { ! [file readable $topoFile] } {
	    inform "-E-argv:file.not.readable" -flag "-t" -value $topoFile
	}
	set G(fabric,.topo) [new_IBFabric]
	IBFabric_parseTopology $G(fabric,.topo) $topoFile
	getArgvPortNames
    }

    return
}
######################################################################

######################################################################
### User messages
######################################################################

##############################
#  SYNOPSIS
#  FUNCTION
#  INPUTS
#  OUTPUT


proc putsIn80Chars { string args } { 
    global G

    set maxLen 80
    set indent ""
    if { [llength $args] == 1 } { set args [join $args] }
   set chars  [WordAfterFlag $args "-chars"]
   set nonewline [WordInList "-nonewline" $args]
    foreach line [split $string \n] {
	if { $chars != "" } {
	    if { [set idx [string first $chars $line]] >= 0 } {
		set indent "[string range $line 0 [expr $idx -1]]$chars"
		set line \
		    [string range $line [expr $idx+[string length $chars]] end]
	    }
	} else {
	    regexp {^(-[A-Z]- ?| +)(.*)$} $line . indent line
	}
	set outline "$indent"
	set indent [bar " " [string length $indent]]
	set len80 [expr $maxLen - [string length $indent]]
	while { [string length $line] > 0 } {
	    set interval [string range $line 0 $len80]
         if { [WordInList "-origlen" $args] \
		     || ( [string length $line] <= $len80 ) \
		     || ( [set spcIdx [string last " " $interval]] == -1 ) } { 
		append outline "$line"
		break
	    } else { 
		append outline "[string range $line 0 [expr $spcIdx -1]]\n$indent"
		set line [string range $line [expr $spcIdx +1] end]
	    }
	}

      if { ! [WordInList "-stdout" $args] } {
	    if {$nonewline} {
		puts -nonewline $outline
	    } else {
		puts $outline
	    }
	}
      if { ! [WordInList "-logfile" $args] } {
	    if {$nonewline} {
		catch { puts -nonewline $G(logFileID) $outline }
	    } else {
		catch { puts $G(logFileID) $outline }
	    }
	}
    }
}
proc retriveEntryFromArray {_arrayName _entry {_defMsg "UNKNOWEN"}} {
    upvar 1 $_arrayName tmpArray
    if {[info exists tmpArray($_entry)]} {
        set res $tmpArray($_entry)
        return $res
    } else {
        return $_defMsg
    }
}

proc inform { msgCode args } { 
    global G InfoArgv argv env
    regexp {^(\-[A-Z]\-)?([^:]+).*$} $msgCode . msgType msgSource

    if { $msgType == "-V-" } { 
	if { $G(argv,verbose) == 0 } { 
	    return 
	}
	set dontShowMads \
         [expr ( \"[ProcName 1]\" == \"DiscoverFabric\" ) \
		 && ( \"$G(tool)\" != \"ibdiagnet\" ) \
		 && ( $G(argv,verbose) < 2 ) ]
    } else { 
	debug "472" -header 
    }

    ## Setting Error Codes
    set G(status,help)			0
    set G(status,discovery.failed)	1
    set G(status,illegal.flag.value)	2
    set G(status,ibis_init)		3
    set G(status,rootPortGet)		4 
    
    # 1 - Failed to fully discover the fabric
    # 2 - Failed to parse command line options
    # 3 - Some packet drop observed 
    # 4 - Mismatch with provided topology

    ##################################################
    ### When general tool's info is requested (help page, version num etc.)
    if { $msgType == "-H-" } { 
	switch -exact -- $msgCode { 
	    "-H-help" {
		showHelpPage
	    } "-H-version" { 
		append msgText "-I- $G(tool) version $G(version.num)"
	    } "-H-vars" {
		append msgText "-I- $G(tool) environment variabls:"
		foreach flag [toolsFlags envVars]  {
		    set name $InfoArgv(-$flag,name)
		    set envVarName  IBDIAG_[string toupper [join [split $name .] _]]
		    append msgText "\n    $envVarName \t"
		    if {[catch {append msgText "$env($envVarName)"}]} { 
			append msgText "not set"
		    }
		}
	    }
	}
	catch { putsIn80Chars $msgText }
        exit $G(status,help) 
    }
    ##################################################
    set argsList $args 

    array set msgF {}
    while { [llength $argsList] > 0 } {
        if {[regsub "^-" [lindex $argsList 0] "" param]} { 
	    set value [lindex $argsList 1]
            set msgF($param) $value ; #not [join $value] - because of -I-ibdiagnet:bad.link
            set argsList  [lreplace $argsList 0 1]
	} else { 
	    set argsList  [lreplace $argsList 0 0]
	}
    }

   set listOfNames ""
   set listOfNames_Ports ""
   set maxType 3
   set total 0
   set localDevice 0
   array set deviceNames { SW "Switch" CA "HCA" Rt "Router" }

   foreach entry [array names msgF DirectPath*] {
      incr total
      regsub {^DirectPath} $entry {} i
      set NODE_TYPE($i)  [GetParamValue Type $msgF($entry) -byDr]
      set NODE_TYPE($i,Name) $deviceNames($NODE_TYPE($i))
      set PATH($i) "\"$msgF($entry)\""

      if {$NODE_TYPE($i) == "SW"} {
         set maxType 6
         set ENTRY_PORT($i) 0
      } else {
         set ENTRY_PORT($i) [GetParamValue PortNum $msgF($entry) -byDr]
         set ENTRY_PORT($i) [format %d $ENTRY_PORT($i)]
      }
        if { $msgF($entry) == "" } { 
         set NODE_NAME($i,FullName)  "The Local Device"
         set NODE_NAME($i,Name)      "The Local Device"
         set localDevice 1
	} else { 	    
            set DrPath2Name_1 [DrPath2Name $msgF($entry) -fullName]
            set DrPath2Name_2 [DrPath2Name $msgF($entry)]
         set NODE_NAME($i,FullName)  "$DrPath2Name_1"
         set NODE_NAME($i,Name)      "$DrPath2Name_2"
      }
      if {$NODE_NAME($i,Name) == ""} {
         if {$NODE_TYPE($i) != "SW"} {
            set NODE_NAME($i,Name_Port) "PN=$ENTRY_PORT($i)"
         } else {
            set NODE_NAME($i,Name_Port) ""
	}
      } else {
         set NODE_NAME($i,Name_Port) "\"$NODE_NAME($i,Name)/P$ENTRY_PORT($i)\""
         set NODE_NAME($i,Name) "\"$NODE_NAME($i,Name)\""
    }

      lappend listOfNames $NODE_NAME($i,Name)
      lappend listOfNames_Ports $NODE_NAME($i,Name_Port)
   }

   set maxName [LengthMaxWord $listOfNames]
   set maxName_Port [LengthMaxWord $listOfNames_Ports]
   for {set i 0} {$i < $total } {incr i} {
      if {[info exists NODE_NAME($i,Name)]} {
         set name [AddSpaces $NODE_NAME($i,Name) $maxName]
         set NODE_TYPE($i,Name) "[AddSpaces $NODE_TYPE($i,Name) $maxType]"
         set NODE_NAME($i,Name) $name
         set NODE_NAME($i,Name) $name
         set name [AddSpaces $NODE_NAME($i,Name_Port) $maxName_Port]
         set NODE_NAME($i,Name_Port) $name
      }
   }

    if {[info exists msgF(flag)]} { 
	set name  ""
	catch { set name $InfoArgv($msgF(flag),name) }
	set envVarName "IBDIAG_[string toupper [join [split $name .] _]]"
      if {[WordInList "$msgF(flag)" $argv]} {
	    set llegalValMsg "llegal value for $msgF(flag) flag"
	} elseif {[info exists env($envVarName)]} { 
	    set llegalValMsg "llegal value for environment variable $envVarName"
	} elseif { ( $msgCode == "-E-localPort:port.not.found" ) && \
		       [info exists G(argv,direct.route)] } {
	    set msgCode "-E-localPort:illegal.dr.path.out.port"
	} else { 
	    set llegalValMsg ""
	    # set llegalValMsg "kuku a-ha"
	}
    }

    if {[info exists msgF(names)]} {
	set validNames "[lsort -dictionary $msgF(names)]"
	if { [llength $validNames] > 0 } {
	    set validNames "Valid %s names are:\n${validNames}"
	}
    }

    set numOfRetries [expr $G(argv,failed.retry) + $G(config,badpath,maxnErrors)]
    set rumSMmsg "To use lid-routing, an SM should be ran on the fabric."
    set bar "${msgType}[bar - 50]"
    set putsFlags ""
    set msgText "$msgType "
   ##################################################
   ### decoding msgCode 
   switch -exact -- $msgCode { 
      "-E-argv:unknown.flag" {
	   append msgText "Illegal agrument: $msgF(flag) - unknown flag."
      }
      "-E-argv:missing.mandatory.flag" {
	   if { [llength $msgF(flag)] > 1 } { 
	       append msgText "Missing one of the mandatory flags [join $msgF(flag) ,]."
	   } else { 
	       append msgText "Missing mandatory flag $msgF(flag)."
	   }
      }
      "-E-argv:flag.without.value" {
	   append msgText "Illegal agruments: flag $msgF(flag) must have a value."
      }
      "-E-argv:flag.twice.specified" {
	   append msgText "Illegal agruments: flag $msgF(flag) is specified twice."
      }
      "-E-argv:nonmutex.flags" {
	   append msgText "Only one of the options [join $msgF(flags) ,] may be active."
      }
      "-E-argv:nonmutex.modes" {
	   # TODO: do I ever use this ???
	   append msgText "Bad arguments; could not figure out the run mode."
      }
      "-E-argv:too.large.integer" {
	   append msgText "$msgF(value) - i${llegalValMsg} "
	   append msgText "(integer value too large to represent)."
      }
      "-E-argv:not.nonneg.integer" {
	   append msgText "$msgF(value) - i${llegalValMsg} "
	   append msgText "(must be a non negative integer number)."
      }
      "-E-argv:not.pos.integer" {
	   append msgText "$msgF(value) - i${llegalValMsg} "
	   append msgText "(must be a positive integer number)."
      }
      "-E-argv:not.pos.integers" {
	   append msgText "$msgF(value) - i${llegalValMsg}.\n"
	   append msgText "(lagel value: a positive integer, or a pair of"
	   append msgText "positive integers separated by a comma)."
      }
      "-E-argv:too.large.value" {
	   append msgText "$msgF(value) - i${llegalValMsg}.\n"
	   switch -exact -- $msgF(flag) { 
	       "-d"    { append msgText "(maximal legal port number is [expr $msgF(maxValue)])." }
	       "-l"    { append msgText "(maximal legal LID is $msgF(maxValue))." }
	       default { append msgText "(it must not exceed $msgF(maxValue))." }
	   }
      }
      "-E-argv:bad.path" {
	   append msgText "\"$msgF(value)\" - i${llegalValMsg}.\n"
	   append msgText "(it must be a direct path: "
	   append msgText "positive integers separated by commas)."
      }
      "-E-argv:dir.not.found" {
	   append msgText "$msgF(value) - no such directory. "
	   append msgText "I${llegalValMsg} (must be an existing directory)."
      }
      "-E-argv:could.not.create.dir" {
	   append msgText "Failed to create directory $msgF(value) (for output files).\n"
	   append msgText "Error message:\n\"$msgF(errMsg)\""
      }
      "-E-argv:file.not.found" {
	   append msgText "$msgF(value) - no such file. "
	   append msgText "I${llegalValMsg} (must be an existing file)."
      }
      "-E-argv:dir.not.writable" {
	   append msgText "Directory $msgF(value) is write protected."
	   if { $llegalValMsg != "" } { 
	       append msgText " I${llegalValMsg}."
	   } else { 
	       append msgText "\n(Use the -o flag to use a different directory"
	       append msgText " for the output files)"
	   }
      }
      "-E-argv:file.not.readable" {
	   append msgText "File $msgF(value) is read protected. I${llegalValMsg}."
      }
      "-E-argv:bad.sys.name" {
	   append msgText "$msgF(value) - no such system. I${llegalValMsg}.\n"
	   append msgText "[format $validNames system]"
      }
      "-E-argv:unknown.sys.name" {
	   ## TODO: add description (in help page, too...)
	   append msgText "Local system name was not specified.\n"
	   append msgText "(it must be specified when using a topology file).\n"
	   append msgText "[format $validNames system]"
      }
      "-E-argv:bad.node.name" {
	   append msgText "$msgF(value) - no such node. I${llegalValMsg}.\n"
	   append msgText "[format $validNames node]"
      }
      "-E-argv:bad.port.name" {
         ###TODO  Not used
	   append msgText "$msgF(value) - no such port. I${llegalValMsg}.\n"
	   append msgText "[format $validNames port]"
      }
      "-E-argv:nodename.without.topology" {
	   append msgText "If node(s) are specified by name - \"$msgF(value)\""
	   append msgText " - a topology file must be given."
      }
      "-E-argv:no.such.command" {
	   append msgText "\"$msgF(command)\" - no such command."
      }
      "-E-argv:command.not.valid.for.device" {
	   append msgText "Command \"$msgF(command)\" is not valid for device $msgF(device)."

       } -E-argv:no.such.field { 
	   append msgText "\"$msgF(errorCode)\" - illegal field for command \"$msgF(command)\"."
       } -E-argv:illegal.field.value {
	   append msgText "\"$msgF(value)\" - illegal value for field "
	   append msgText "\"$msgF(field)\" (must be $msgF(legal))."
       } -E-argv:illegal.integer.value {
	   append msgText "\"$msgF(value)\" - illegal value for field "
	   append msgText "\"$msgF(field)\" (must be an integer)."
       } -E-argv:illegal.port.value { 
	   append msgText "$msgF(value) - illegal port value "
	   append msgText "(must be an integer 1..$msgF(ports))."
       } -E-argv:missing.fields {
	   append msgText "The field(s) -[join $msgF(field) ,-] "
	   append msgText "must be specified for the command $msgF(command)."
       } 
       -E-argv:specified.port.not.connected {
	   append msgText "Port $msgF(value) (specified by $msgF(flag) flag) is specified in the "
	   append msgText "topology file as not connected to the fabric."
       } -E-argv:hca.no.port.is.connected { 
	   append msgText "No port of node $msgF(value) (specified by $msgF(flag) flag) was "
	   append msgText "found to be connected to the fabric."
       } -W-argv:hca.many.ports.connected { 
	   append msgText "A few ports of $msgF(value) (specified by $msgF(flag) flag) are "
	   append msgText "connected to the fabric; one of them - port $msgF(port) - is used."
       } -E-argv:disagrees.with.dir.route { 
	   append msgText "The output port of the direct route (= $msgF(port)) is not "
	   append msgText "the local port (= $msgF(value)).\n"
	   append msgText "(MADs may be sent only through the local port)."
       } 

        -W-argv:-s.without.-t {
	   append msgText "Local system name is specified, but topology "
	   append msgText "is not given. The former is ignored."
       } -W-argv:no.topology.file {
	   append msgText "Topology file is not specified.\n"
	   append msgText "Reports regarding cluster links will use direct routes."
       }
       
       -E-ibis:init {
	   append msgText "ibis_init failed.\n[join $args]"
       } -E-ibis:info { 
	   append msgText "ibis_get_local_ports_info failed.\n[join $args]"
       } -E-ibis:no.hca { 
	   append msgText "No HCA was found on local machine."
       }

       
       -E-localPort:all.ports.down {
	   if { $G(tool) == "ibtrace" } { 
	       append msgText "None of the ports of local device are in ACTIVE state."
	   } else { 
	       append msgText "All ports of local device are in DOWN state."
	   }
       } -E-localPort:dev.not.found {
	   append msgText "I${llegalValMsg}: "
	   append msgText "local machine does not have device of index $value."
       } -E-localPort:port.not.found {
	   append msgText "I${llegalValMsg}: "
	   append msgText "local device does not have port number $value."
       } -E-localPort:illegal.dr.path.out.port { 
	   append msgText "Illegal value for -d flag: "
	   append msgText "local device does not have port number $value."
	   append msgText "No such direct route."
       } -W-localPort:few.ports.up {
	   append msgText "A few ports of local device are up.\n"
	   append msgText "Since port-num was not specified (-p flag), "
	   append msgText "port \#$G(argv,port.num) will be used as the local port."
       } -I-localPort:one.port.up {
	   append msgText "Using port $G(argv,port.num) as the local port."
       } -W-localPort:node.inteligently.guessed {
	   append msgText "Since local system name was not specified (-s flag), "
         append msgText "its set to $G(argv,sys.name)."
       } -I-localPort:is.dr.path.out.port { 
	   append msgText "Using port $G(argv,port.num) as the local port "
	   append msgText "(since this is the output port of the direct route)."
       } -I-localPort:using.dev.index {
	   append msgText "Using device $G(argv,dev.idx) as the local device."
       }
       
       -W-outfile:not.writable { 
	   append msgText "Output file $msgF(file0) is write protected.\n"
	   append msgText "Writing info into $msgF(file1)."
       }

      -E-outfile:not.valid {
         append msgText "Output file $msgF(file0) is illegal value for $G(tool).\n"
      }
     
       -E-discover:local.port.down {
	   append msgText "Port $msgF(port) of local device if down."
       } -E-discover:local.port.crashed {
	   append msgText "Discovery at local link failed: $msgF(command) - failed "
         append msgText "$numOfRetries consecutive times."
       } -E-discover:local.port.failed {
	   append msgText "Local link is bad: $msgF(command) - failed $msgF(fails) "
	   append msgText "times during $msgF(attempts) attempts."
       } -E-discover:duplicated.guids { 
         # TODO Unset NODE_NAME,NODE_TYPE... at the end of inform
         if {$localDevice} {set G(LocalDeviceDuplicated) 1}
	   append msgText "Duplicate $msgF(port_or_node) guid detected.\n"
	   append msgText "The following two different devices:\n"
         append msgText "a $NODE_TYPE(0,Name) $NODE_NAME(0,Name_Port) at direct path=$PATH(0)\n"
         append msgText "a $NODE_TYPE(1,Name) $NODE_NAME(1,Name_Port) at direct path=$PATH(1)\n"
	   append msgText "have inedtical $msgF(port_or_node) guid $msgF(guid)."
           set noExiting 1
       } "-E-discover:zero/duplicate.IDs.found" {
         if {$total > 1} {
            append msgText "#$total Devices with "
	   } else {
            append msgText "Device with "
	   }
         if { $msgF(value) != 0 } { append msgText "identical "}
         append msgText "$msgF(ID) = $msgF(value) found in the fabric:\n"
        
         for {set i 0} {$i < $total} {incr i} {
            append msgText "a $NODE_TYPE($i,Name) $NODE_NAME($i,Name_Port) at direct path=$PATH($i)\n"
	   }
           set noExiting 1
      } -E-ibtrace:direct.route.deadend {
         ### TODO: check the phrasing ...
	   append msgText "Bad direct route: the specified direct route passes through "
	   append msgText "the following device%n"
	   append msgText "$nodeFullName%n"
	   append msgText "which is a HCA (which cannot forward direct route mads)."
       } -E-ibtrace:direct.path.no.such.port {
	   append msgText "Bad direct route: the following device%n"
	   append msgText "$nodeFullName%n"
	   append msgText "does not have port number $msgF(port)."
       } -E-ibtrace:link.down {
	   append msgText "Port \#$msgF(port) of the following device%n"
	   append msgText "$nodeFullName%n"
	   append msgText "is DOWN."
	   # -E-ibtrace:link.down.byLid
	   #   append msgText "Link (on the Lid route) at direct route \"$W0\" "
	   #   append msgText "port \#$W1 is DOWN."
       } -E-ibtrace:local.port.not.active { 
	   append msgText "Local link (port \#$msgF(port) of local device) is " 
	   append msgText "in $msgF(state) state.\n"
	   append msgText "(PortCounters may be queried only over ACTIVE links)."
       } -E-ibtrace:reached.lid.0 {
	   # set noExiting 1
	   # puts ""
	   append msgText "Bad LID: the following device has LID = 0.\n"
         if { $NODE_TYPE(0) == "SW" } {
	       append msgText "Switch "
	   } else { 
	       append msgText "Port $EntryPort of HCA "
	   }
	   append msgText "$nodeFullName%n"
         if {[WordInList "+cannotRdPM" $args]} {
	       append msgText "Cannot send pmGetPortCounters mads.\n"
	   }
	   append msgText "$rumSMmsg."
	   #  -E-ibtrace:lid.0.on.direct.route 
	   #   set noExiting 1
	   #   append msgText "Bad LID: device at direct route \"$W0\" has LID = 0.\n"
	   #   append msgText "Cannot send pmGetPortCounters mads.\n${rumSMmsg}."
       } -E-ibtrace:lid.route.deadend {
	   set path2Switch [lreplace $DirectPath end end]
	   set port [lindex $DirectPath end] \
	       set switchname "[path=\"$path2Switch\" [DrPath2Name $path2Switch -fullName]"
	   append msgText "LID-route deadend was detected.\n"
	   append msgText "Entry $msgF(lid) of LFT of the following switch\n"
	   append msgText "$switchname\n"
	   append msgText "is $port, but port $port leads to\n"
	   append msgText "HCA $nodeFullName."
       } -E-ibtrace:lid.route.loop {
	   append msgText "Lid route loop detected: "
	   append msgText "when following the LID-route for LID $msgF(lid) from device%n"
	   append msgText "$nodeFullName%n"
       } -E-ibtrace:read.lft.failure {
	   append msgText "[join $args] - failed $numOfRetries consecutive times." 
	   # Text ended with "Aborting ibtrace."
       } -E-ibtrace:fdb.block.unreachable { 
	   append msgText "Could not read FDB table: \"$msgF(command)\" "
	   append msgText "terminated with errorcode $msgF(errorcode)."
       } -E-ibtrace:fdb.value.ffs {
	   append msgText "Lid $msgF(lid) unreachable: \"$msgF(command)\" "
	   append msgText "(ran over ibis) returned 0xff at entry $msgF(entry)."
       } -E-ibtrace:pmGet.failed {
	   set noExiting 1
	   append msgText "Could not get PM info:\n"
	   append msgText "\"pmGetPortCounters [join $args]\" failed $numOfRetries consecutive times."
       }
       
       "-I-discover:discovery.status" {
	   append putsFlags " -nonewline"
	   if { $G(argv,debug) || $G(argv,verbose) } { return } 
           set nodesNum [expr $G(Counter,SW) + $G(Counter,CA)]
           debug "740" nodesNum swNum
	   append msgText "Discovering the subnet ... $nodesNum nodes "
	   append msgText "($G(Counter,SW) Switches & $G(Counter,CA) CA-s) "
	   append msgText "discovered.\r"

       } "-V-discover:discovery.status"	{
	   append msgText "Discovering DirectPath (no. $msgF(index)) \{$msgF(path)\}"
       }

       "-I-topology:matching.header" {
	   append msgText "Topology matching results"
      } "-W-topology:localDevice.Duplicated" {
         append msgText "Local Device Guid was duplicated. "
         append msgText "Since local system name was guessed, "
         append msgText "Topology Matching May Failed."
       } "-I-topology:matching.note" {
	   append msgText "Note that \"bad\" links and the part of the fabric "
	   append msgText "to which they led (in the BFS discovery of the fabric, "
	   append msgText "starting at the local node) are not discovered and "
	   append msgText "therefore will be reported as \"missing\"."
	   if { [llength [array names G bad,paths,*]] == 0 } {
	       set msgText "" ; # <- this means don't print the "-I-" prefix
	   }
       } "-I-topology:matching.perfect" { 
	   append msgText "The topology defined in $G(argv,topo.file) "
	   append msgText "perfectly matches the discovered fabric."
       } "-W-topology:matching.bad" {
	   append msgText "Many mismatches between the topology defined in "
	   append msgText "$G(argv,topo.file) and the discovered fabric:\n"
       }

       "-I-ibdiagnet:report.fab.qualities.header" {
	   append msgText "Fabric qualities report"
       } "-I-ibdiagnet:check.credit.loops.header" {
	   append msgText "Checking credit loops"
       } "-I-ibdiagnet:mgid.mlid.hca.header" {
	   append msgText "mgid-mlid-HCAs matching table"
       } "-I-ibdiagnet:bad.links.header" {
	   append msgText "Bad Links Info\n"
	   append msgText "-I- Errors have occurred on the following links "
	   append msgText "(for errors details, look in log file $G(outfiles,.log)):"
       } "-I-ibdiagnet:no.bad.paths.header" {
	   append msgText "Bad Links Info\n"
	   append msgText "-I- No bad link were found"
       } "-I-ibdiagnet:bad.link" {
	   append putsFlags " -origlen"
	   set msgText "" ; # <- this means don't print the "-I-" prefix
	   append msgText $msgF(link)
       } "-I-ibdiagnet:bad.link.errors" { ;# -errors
	   append putsFlags " -stdout"
	   set msgText "" ; # <- this means don't print the "-I-" prefix
	   append msgText $msgF(errors)
       } "-I-ibdiagnet:bad.links.err.types" {
	   append putsFlags " -stdout -chars \": \""
	   set msgText "" ; # <- this means don't print the "-I-" prefix
	   append msgText "\n Errors types explanation:\n"
	   append msgText "   \"noInfo\"  : the link was ACTIVE during discovery "
	   append msgText "but, sending MADs across it failed $numOfRetries consecutive times\n"
	   append msgText "   \"badPMs\"  : one of the Error Counters of the link "
	   append msgText "has values higher than predefined thresholds.\n"
	   append msgText "   \"madsLost\": $G(config,badpath,maxnErrors) MADs were "
	   append msgText "dropped on the link (drop ratio is given).\n"
       }
       "-W-report:one.hca.in.fabric" {
	   append msgText "The fabric has only one HCA. No fabric qualities report is issued."
       }

       "-I-ibtrace:read.lft.header" {
	   append msgText "Traversing the path from source to destination port"
	   # puts "\n$bar\n-I- Traversing Source to Destination LFTs:\n$bar"
       } "-I-ibtrace:read.lft.from" {
	   append msgText "From: [join $args]"
       } "-I-ibtrace:read.lft.to" { 
	   append msgText "To:   [join $args]\n"
       } "-I-ibtrace:read.pm.header" {
	   append msgText "Validating path health"
	   # puts "\n-I- Traversing Source to Destination LFTs:\n"
       } "-W-ibtrace:ardessing.local.node" { 
	   append msgText "Addressing local node. Only local port will be checked."
       }
       
       "-I-exit:\\r" {
	   set msgText "" ; # <- this means don't print the "-I-" prefix
	   append msgText "%n"
	   # if { ! ( $G(argv,debug) || $G(argv,verbose) ) } {
	   #	puts "\v"
	   # }
	   # return
       }
       
       "-I-done" {
	   putsIn80Chars " "
	   append msgText "Done. Run time was [expr [clock seconds] - $args] seconds."
       }

       "-V-mad:sent"	{
	   if {$dontShowMads} { return }
	   append putsFlags " -nonewline"
         append msgText "running $msgF(command) ..." ;#(invoked by [ProcName 2])
       } "-V-mad:received"	{
	   if {$dontShowMads} { return }
	   set msgText "" ; # <- this means don't print the "-I-" prefix
	   if {[info exists msgF(status)]} { 
	       append msgText "status = $msgF(status) (after $msgF(attempts) attempts)"
	   } else {
	       append msgText "done (after $msgF(attempts) attempts)"
	   }
       }

       "-V-badPathRegister"	{
	   append msgText "Bad path found: failure = $msgF(error). "
	   append msgText "When running: $msgF(command)."
       } "-V-discover:start.discovery.header"	{
	   append msgText "Starting subnet discovery"
       } "-V-discover:end.discovery.header"	{
	   set nodesNum [llength [array names G "NodeInfo,*"]]
	   set swNum	 [llength [array names G "PortInfo,*:0"]]
	   append msgText "Subnet discovery finished.%n"
	   append msgText "$nodesNum nodes ($swNum Switches & [expr $nodesNum - $swNum] CA-s) discovered"
       } "-V-ibdiagnet:bad.links.info"	{
	   # puts "\n$bar\n-V- Bad Links Info\n$bar"
	   foreach entry [array names G bad,paths,*] {
	       append msgText "\nFailure(s) for direct route [lindex [split $entry ,] end] : "
	       if { [llength $G($entry)] == 1 } {
		   append msgText "[join $G($entry)]"
	       } else {
		   append msgText "\n      [join $G($entry) "\n      "]"
	       }
	   }
       } "-V-discover:long.paths" {
	   putsIn80Chars " "
	   append msgText "Retrying discovery multiple times (according to the -c flag) ... "
       } "-V-ibdiagnet:detect.bad.links" {
	   putsIn80Chars " "
	   append msgText "Searching for bad link(s) on direct route \{$msgF(path)\} ..."
       } "-V-ibdiagnet:incremental.bad.links" {
	   append msgText "Sending MADs over increments of the direct route \{$msgF(path)\}"
       }

       "-V-ibtrace:pm.value" {
	   append msgText "PM [join $args]"
       }

       "-V-outfiles:.lst"	{
	   putsIn80Chars " "
	   append msgText "Writing file $G(outfiles,.lst) "
	   append msgText "(a listing of all the links in the fabric)"
       } "-V-outfiles:.fdbs"	{
	   putsIn80Chars " "
	   append msgText "Writing file $G(outfiles,.fdbs)" 
	   append msgText "(a dump of the unicast forwarding tables of the fabric switches)"
       } "-V-outfiles:.mcfdbs"	{
	   putsIn80Chars " "
	   append msgText "Writing file $G(outfiles,.mcfdbs)" 
	   append msgText "(a dump of the multicast forwarding tables of the fabric switches)"
       }

       "-I-ibping:results" {
	   set pktFailures	$msgF(failures)
	   set pktTotal	$G(argv,count)
	   set pktSucces	[expr $pktTotal - $pktFailures]
	   set pktSuccesPrc	[expr ( round ( ($pktSucces / $pktTotal)*10000 ) ) / 100.0 ]
	   set pktFailuresPrc	[expr 100 - $pktSuccesPrc]
	   set avrgRoundTrip	$msgF(time)
	   putsIn80Chars " "
	   append msgText "ibping: pass:  $pktSucces $pktSuccesPrc%, "
	   append msgText "failed: $pktFailures $pktFailuresPrc%, "
	   append msgText "average round trip: $avrgRoundTrip ms"
       } "-V-ibping:ping.result" {
	   # "12:38:16 010020 lid=2: seq=1 time=0.365 ms"

	   set cc [clock clicks]
	   set us [string range $cc [expr [string length $cc] - 6] end]

	   catch { set address "lid=$G(argv,lid.route)" }
	   catch { set address "name=$G(argv,by-name.route)" }
	   catch { set address "direct_route=\"[split $G(argv,direct.route) ,]\"" }

	   set seqLen [string length $G(argv,count)]
	   if { $msgF(retry) == 1 } { puts "\n$bar\n-V- ibping pinging details\n$bar" }
	   set seq [string range "$msgF(retry)[bar " " $seqLen]" 0 [expr $seqLen -1] ]

	   if { $msgF(time) == "failed" } {
	       set result "failed"
	   } else {
	       set result "time=[string range "[expr $msgF(time) / 1000.0]0000" 0 4] ms"
	   }

	   append msgText "[clock format [clock seconds] -format %H:%M:%S] "
	   append msgText "$us $address seq=$seq $result"
       }
   }
   ##################################################

    ##################################################
    ### Writing out the message  
    set msgText [split $msgText \n]
    if {[regexp ".header" $msgCode]} {
        set msgText [concat [list ""] [list $bar] [linsert $msgText 1 $bar]]
    }

    if { $msgType == "-E-" } {
	if { ! [info exists noExiting] } {
            set Exiting "Exiting"
	    if { $msgSource == "discover" } {
		set Exiting "Aborting discovery"
	    }
	    set Text "[lindex $msgText 0] ${Exiting}."
	    set msgText [linsert [lrange $msgText 1 end] 0 $Text]
            switch -exact -- $msgSource {
        	"ibis" {
                    set exitStatus $G(status,ibis_init) 
                } "argv" {
                    set showSynopsys 1
                    set exitStatus $G(status,illegal.flag.value)
                } "localPort" {
                    set showSynopsys 1
                    set exitStatus $G(status,rootPortGet)
                } "discover" {
                    set exitStatus $G(status,discovery.failed)
                } "ibtrace" {
                    set exitStatus $G(status,discovery.failed)
                } default {
                    set exitStatus $G(status,illegal.flag.value) 
                }
            }
        }
    }
    regsub -all {%n} "[join $msgText \n]" "\n" msgText
    putsIn80Chars $msgText $putsFlags

    if {[info exists exitStatus]} { 
        if {[info exists showSynopsys]} { showHelpPage -sysnopsys }
	catch { close $G(logFileID) }
	exit $exitStatus
    }
    return
    ##################################################
}
######################################################################

######################################################################
proc showHelpPage { args } { 
    global G InfoArgv

##############################
### ibdiagnet help page
##############################
    set helpPage(ibdiagnet) \
"DESCRIPTION
  ibdiagnet scans the fabric using directed route packets and extracts all the 
  available information regarding its connectivity and devices.
  It then produces the following files in the output directory defined by the
  -o option (see below): 
    ibdiagnet.lst    - List of all the nodes, ports and links in the fabric
    ibdiagnet.fdbs   - A dump of the unicast forwarding tables of the fabric
                        switches
    ibdiagnet.mcfdbs - A dump of the multicast forwarding tables of the fabric
                        switches
  In addition to generating the files above, the discovery phase also checks for
  duplicate node GUIDs in the IB fabric. If such an error is detected, it is
  displayed on the standard output.
  After the discovery phase is completed, directed route packets are sent
  multiple times (according to the -c option) to detect possible problematic 
  paths on which packets may be lost. Such paths are explored, and a report of
  the suspected bad links is displayed on the standard output.
  After scanning the fabric, if the -r option is provided, a full report of the
  fabric qualities is displayed.
  This report includes: 
    Number of nodes and systems
    Hop-count information: 
         maximal hop-count, an example path, and a hop-count histogram
    All CA-to-CA paths traced 
  Note: In case the IB fabric includes only one CA, then CA-to-CA paths are not
  reported.
  Furthermore, if a topology file is provided, ibdiagnet uses the names defined
  in it for the output reports.

ERROR CODES
  1 - Failed to fully discover the fabric
  2 - Failed to parse command line options
  3 - Some packet drop observed 
  4 - Could not use local device/port"

#   The number of retries of sending a specific packet is given by the -f option (default = 3).

##############################
### ibtrace help page
##############################
    set helpPage(ibtrace) \
"DESCRIPTION
  ibtrace traces a path between two end-points and provides information
  regarding the nodes and ports traversed along the path. It utilizes device
  specific health queries for the different devices along the traversed path.
  The way ibtrace operates depends on the addressing mode used on the command
  line. If directed route adressing is used, the local node is the source node
  and the route to the destination port is known apriori.
  On the other hand, if LID route (or by-name) addressing is imployed,
  then the source and destination ports of a route are specified by their LIDs 
  (or by the names defined in the topology file). In this case, the actual path
  from the local port to the source port, and from the source port to the
  destination port, is defined by means of Subnet Management Linear Forwarding
  Table queries of the switch nodes along those paths. Therefore, the path
  cannot be predicted as it may change.
  The tool allows omitting the source node, in which case the local port on the
  machine running the tool is assumed to be the source. 
  Note: When ibtrace queries for the performance counters along the path between
  the source and destination ports, it always traverses the LID route, even if a
  directed route is specified. If along the LID route one or more links are not
  in the ACTIVE state, ibtrace reports an error.

ERROR CODES
  1 - The path traced is un-healthy
  2 - Failed to parse command line options
  3 - More then 64 hops are required for traversing the local port to the \"from\" port and then to the \"to\" port.
  4 - Unable to traverse the LFT data from source to destination"
#   The number of retries of sending a specific packet is given by the -f option (default = 3).

##############################
### ibping help page
##############################
    set helpPage(ibping) \
"DESCRIPTION
  ibping pings a target port by sending SM_PortInfo mad request to the target port. 
  The target port is specified by means of either its LID, 
  a direct route to it - a sequence of a output ports through which the packet should be forwarded,
  or its name (the latter - provided that the fabric's topoloy is given).
  If the target node is specified by a direct route, the packets will be sent by direct route,
  otherwise (lid or name addressing) they will be sent by LID route.
  The total number of packets sent is defined by the -c option (100 by default). 
  After sending the desired number of packets ibping reports back 
  the accumulated number of failures and successful responses.  
  If the -v option is defined a verbose line is printed for each packet sent, 
  containing the time sent, and the trip total time or failure. 

ERROR CODES
  1 - Some packets failed to return
  2 - Failed to parse command line options 
  3 - Given name does not exist or some topology required parameters were not provided
  4 - Failed to bind to the driver"

##############################
### ibcfg help page
##############################
    set helpPage(ibcfg) \
"DESCRIPTION
  ibcfg provides user interface for device level configuration.
  It runs in two modes: query mode (-q) or configuration mode (-c).
  The query mode provides back a list of the specific device commands and their parameters.
  The configuration mode requires the name of the command to be executed and its parameters. 
  To support \"Device Specific\" configuration options the implementation of this command 
  relies on vendor provided modules. 
  With this architecture each device has its own set of commands provided by the device manufacturer. 
  Please see the set of commands that will be available for each Mellanox device at appendix A. 
  This utility also supports controlling local devices accessible through the local PCI bus or I2C. 
  To configure a local device the -m flag should be provided following an MST device designator.

ERROR CODES
  1 - Fail to execute the command
  2 - No such command for the given device
  3 - Fail to find the given device"

##############################
### ibmad help page
##############################
    set helpPage(ibmad) \
"DESCRIPTION
  ibmad is a generic mad injector supporting many types of attributes. 
  It works in two modes: query and injection. 
  The query mode denoted by the -q option provides the list of attributes supported 
  and their detailed list of fields or required modifier values: 
  if an attribute is provided then the list of the attribute fields and modifiers is printed. 
  Otherwise the list of attributes is printed.
  The injection mode requires a method and an attribute options and optional list 
  of field name and values to fill into the mad. 
  All fields not being provided are filled with zeros. 

ATTRRIBUTES:
  The following attributes are supported:
  SMPs: 
      SM_NodeInfo, SM_PortInfo, SM_SwitchInfo, SM_NodeDescription, 
      SM_LFTBlock, SM_MFTBlock, SM_GUIDInfo, SM_PKeyTable, 
      SM_SLVLTable and SM_VLArbTable, SM_Notice.
  Performance Monitoring Queries: 
      PM_PortCounters
  Vendor Specific: 
      VS_CfgReg, VS_CfgRegVL15

ERROR CODES
  -1 - Fail to find target device
  -2 - Fail to parse command line (might be wrong attribute method field...)
  <1-N> - Remote mad status"

##############################
### ibsac help page
##############################
    set helpPage(ibsac) \
"DESCRIPTION
  ibsac sends SA queries. 
  The supported attributes and their fields 
  are provided in the \"query\" mode (-q).   

ERROR CODES
  -1 - Fail to find target device
  -2 - Fail to parse command line (might be wrong attribute method field)
  <1-N> - Remote mad status"

# OPTIONS
# -<field-i> <val-i>: specific attribute field and value. Automatically sets the component mask bit.
 ##############################

   set onlySynopsys [WordInList "-sysnopsys" $args]
    # NAME
    if { ! $onlySynopsys } { 
	puts "NAME\n  $G(tool)"
    }
    
    # SYNOPSIS
    set SYNOPSYS "SYNOPSYS\n  $G(tool)"
    set OPTIONS "OPTIONS"
    foreach item [toolsFlags $G(tool)] {
	if { $item == ";" } { 
	    append SYNOPSYS "\n\n  $G(tool)"
	    continue
	}

	set synopsysFlags ""
	set mandatory [regsub -all {[()]} $item "" item]
	foreach flag [split $item |] { 
	    set flagNparam "-$flag"
	    catch { append flagNparam " <$InfoArgv(-$flag,param)>" }
	    set flagNdesc "$flagNparam:"
	    catch { append flagNdesc " $InfoArgv(-$flag,desc)" }
	    catch { 
		if { ( [set defVal $InfoArgv(-$flag,default)] != "" ) \
                    && ( ! [WordInList $flag "i v"] ) } {
		    append flagNdesc " (default = $defVal)"
		}
	    }
	    if {[regexp {\(} $item]} { ; # only mandatory flags have optional flags
		catch { append flagNparam " \[$InfoArgv(-$flag,optional)\]" } 
	    }
	    lappend synopsysFlags $flagNparam
	    lappend OPTIONS $flagNdesc
	    lappend lcol [string first ":" $flagNdesc]
	}

	if { [string length "[lindex [split $SYNOPSYS \n] end] $synopsysFlags "] > 80 } { 
	    append SYNOPSYS "\n    "
	}
	if { ! $mandatory } { 
	    append SYNOPSYS " \[[join $synopsysFlags]\]"
	} elseif { [llength $synopsysFlags] == 1 } {  
	    append SYNOPSYS " [join $synopsysFlags |]"
	} else { 
	    append SYNOPSYS " \{[join $synopsysFlags |]\}"
	}
    }
    lappend OPTIONS ""
    foreach flag [toolsFlags general] {
	# set synopsysFlags ""
	set flagNparam "-$flag"
	if {[regexp {^\-} $flag]} { 
	    set flagNparam "   -$flag"
	} 
	catch { append flagNparam " <$InfoArgv(-$flag,param)>" }
	catch { append flagNparam "|$InfoArgv(-$flag,longflag)" }
	set flagNdesc "$flagNparam:"
	catch { append flagNdesc " $InfoArgv(-$flag,desc)" }
	# if {[regexp {\(} $item]} { ; # only mandatory flags have optional flags
	#     catch { append flagNparam " \[$InfoArgv(-$flag,optional)\]" } 
	# }
	# lappend synopsysFlags $flagNparam
	lappend OPTIONS $flagNdesc
	lappend lcol [string first ":" $flagNdesc]
    }

    puts "\n$SYNOPSYS"
    if {$onlySynopsys} { return }

    # OPTIONS
    regsub -all "<>" $OPTIONS "" newOPTIONS
    set colIndent [lindex [lsort -integer $lcol] end]
    set OPTIONS ""
    foreach option $newOPTIONS { 
	set colIdx [string first ":" $option]
	regsub ":" $option "[bar " " [expr $colIndent - $colIdx]]:" option
# 	regsub "\n" $option "\n[bar " " [expr $colIndent + 3] ]" option
	lappend OPTIONS $option
    }
    lappend lcol [string first ":" $option]

    set text [split $helpPage($G(tool)) \n] 
    set index 0
    set read 0
    foreach line $text { 
	incr index
	# if { ! [regexp {DESCRIPTION} $line] } { append DESCRIPTION " " [string trim $line] }
	if { [incr read [expr [regexp "DESCRIPTION" $line] + ( $read && ! [regexp {[^ ]} $line] ) ]] > 1 } {
	    break
	}
    }

    puts "\n[join [lrange $text 0 [expr $index -1]] \n]"
    putsIn80Chars "[join $OPTIONS "\n  "]" -chars ": "
    putsIn80Chars "\n[join [lrange $text $index end ] \n]" -chars "-"
    # puts "\n[join [linsert $text $index "[join $OPTIONS "\n  "]\n"] \n]"

    return
}
######################################################################

