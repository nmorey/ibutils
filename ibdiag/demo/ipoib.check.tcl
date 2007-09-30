# This is the checker for IPoIB flow

proc parseNodePortGroup {simDir} {
   set f [open [file join $simDir "port_pkey_groups.txt"] r]
   set res {}
   while {[gets $f sLine] >= 0} {
		if {[regexp {^\#} $sLine]} {continue}
      lappend res $sLine
   }
   close $f
   puts "-I- Defined [llength $res] ports"
   return $res
}

# given the node port group defined by the sim flow 
# setup the partitions policy file for the SM 
proc setupPartitionPolicyFile {fileName} {
   global nodePortGroupList
	for {set g 1} {$g <= 3} {incr g} {
		set GROUP_PKEYS($g) ""
	}
   set f [open $fileName w]

   # no need for default partition
   # puts $f "Default=0x7fff ,ipoib : ALL, SELF=full ;"

   # loop on the tree groups collecting their member guids and printing
	# them out
   foreach p {1 2 3} {
      set guids {}
      foreach png $nodePortGroupList {
         # png = { name num grp guid pkey }
         set grp [lindex $png 2]
         if {$grp == $p} {
            lappend guids [lindex $png 3]
            set GROUP_PKEYS($grp) [lindex $png 4]
         } elseif {$grp == 3} {
            # group 3 ports are members of both other groups
            lappend guids [lindex $png 3]            
         }
      }

		switch $p {
			1 {set ipoib ", ipoib, rate=6"}
			2 {set ipoib ", ipoib, rate=3"}
			3 {set ipoib ", ipoib, rate=3"}
		}

      puts $f "G$p=$GROUP_PKEYS($p) $ipoib:"
      set lastGuid [lindex $guids end]
      foreach g $guids {
         if {$p != 3} {
            puts -nonewline $f "   $g=full"
         } else {
            puts -nonewline $f "   $g=full"
         }
         if {$lastGuid == $g} {
            puts $f ";"
         } else {
            puts $f ","
         }
      }
      puts $f " "
   }

   close $f
}

# obtain the list of hosts per each group and dump first few of them
proc getFirstHostOfEachGroup {} {
   global nodePortGroupList
	global GROUP_HOSTS
   foreach p {1 2 3} {
      set hosts {}
      foreach png $nodePortGroupList {
         # png = { name num grp guid pkey }
         set grp [lindex $png 2]
         if {$grp == $p} {
            lappend hosts [lindex $png 0]
         }
      }
		
		set GROUP_HOSTS($p) $hosts
		puts "Group \#$p has [llength $hosts] hosts: [lrange $hosts 0 2] ..."
	}
}

##############################################################################
# 
# Start up the test applications
# This is the default flow that will start OpenSM only in 0x43 verbosity
# Return a list of process ids it started (to be killed on exit)
#
proc runner {simDir osmPath osmPortGuid} { 
   global simCtrlSock
   global env
   global nodePortGroupList
	global GROUP_HOSTS

   set osmStdOutLog [file join $simDir osm.stdout.log]
   set osmLog [file join $simDir osm.log]

   fconfigure $simCtrlSock -blocking 1 -buffering line

   # randomize pkey tables
   puts $simCtrlSock "setAllHcaPortsPKeyTable \$fabric"
   puts "SIM: [gets $simCtrlSock]"
   puts $simCtrlSock "dumpHcaPKeyGroupFile $simDir"
   puts "SIM: [gets $simCtrlSock]"
   
   # parse the node/port/pkey_group file from the sim dir:
   set nodePortGroupList [parseNodePortGroup $simDir]

   # Prepare the nodes partitions data
   set partitionPolicyFile  [file join $simDir opensm-partitions.policy]
   setupPartitionPolicyFile $partitionPolicyFile

	puts "---------------------------------------------------------------------"
	puts " Listing of 3 Nodes of each group:"
	getFirstHostOfEachGroup

	puts "---------------------------------------------------------------------"
	puts " Performing some fabric modifications for SDR and 1X"
	set host [lindex $GROUP_HOSTS(1) 0]
	puts $simCtrlSock "setPortTo1X \$fabric $host/U1 1"
   puts "SIM: [gets $simCtrlSock]"
	set host [lindex $GROUP_HOSTS(2) 0]
	puts $simCtrlSock "setPortToSDR \$fabric $host/U1 1"
   puts "SIM: [gets $simCtrlSock]"

   # start the SM
	puts "---------------------------------------------------------------------"
	puts " Starting the SM\n"
   set valgrind "/usr/bin/valgrind --tool=memcheck"
   set osmCmd "$osmPath -P$partitionPolicyFile -D 0x43 -d2 -t 4000 -f $osmLog -g $osmPortGuid"
   puts "-I- Starting: $osmCmd"
   set osmPid [eval "exec $osmCmd > $osmStdOutLog &"]
   
   # start a tracker on the log file and process:
   startOsmLogAnalyzer $osmLog
   
   return $osmPid
}

##############################################################################
#
# Check for the test results
# Return the exit code
proc checker {simDir osmPath osmPortGuid} {
   global env
   global simCtrlSock
   global nodePortGroupList
	global GROUP_HOSTS
		
   # wait for the SM up or dead
   set osmLog [file join $simDir osm.log]
   if {[osmWaitForUpOrDead $osmLog]} {
      return 1
   }

	# make sure /proc is updated ... 
	puts $simCtrlSock "updateProcFSForNode \$fabric $simDir H-1/U1 H-1/U1 1"
   set res [gets $simCtrlSock]
   puts "SIM: Updated H-1 proc file:$res"

	puts "---------------------------------------------------------------------"
	puts " OpemSM brought up the network"
	puts $simCtrlSock "dumpPKeyTables \$fabric"
	puts "SIM:[gets $simCtrlSock]"
	puts "---------------------------------------------------------------------"
	puts " All hosts now joining their IPoIB Subnets"
	puts $simCtrlSock "joinPortsByPartition \$fabric"
   puts "SIM: [gets $simCtrlSock]"
	after 10000
	puts "---------------------------------------------------------------------"
	puts " SUBNET READY FOR DIAGNOSTICS"
	puts "\nCut and paste the following in a new window then run ibdiagnet:" 
	puts "cd $simDir"
	puts "setenv IBMGTSIM_DIR  $simDir"
	puts "setenv OSM_CACHE_DIR $simDir"
	puts "setenv OSM_TMP_DIR   $simDir"
	puts " "
	puts " press Enter when done"
	gets stdin
   return 0
}
