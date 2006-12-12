# Main idea here is to intialize the ibnl_path
proc ibdmLoad%VERSION% {dir} { 
   global ibnl_path 
   global env
   # support env variable for extending the search path for
   # system definition files.
   if {[info exists env(IBADM_IBNL_PATH)]} {
      set ibnl_path "$env(IBADM_IBNL_PATH)"
   } else {
      set ibnl_path ""
   }
   puts "Loading IBDM from: $dir"
   uplevel \#0 load [file join $dir libibdm.so.%VERSION%]
	package provide ibdm %VERSION%
}

package ifneeded ibdm %VERSION% [list ibdmLoad%VERSION% $dir]
