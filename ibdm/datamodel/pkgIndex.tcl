# Main idea here is to intialize the ibnl_path
proc ibdmLoad {dir} { 
   global ibnl_path 
   global env
   # support env variable for extending the search path for
   # system definition files.
   if {[info exists env(IBADM_IBNL_PATH)]} {
      set ibnl_path "$env(IBADM_IBNL_PATH)"
   } else {
      set ibnl_path ""
   }

   load [file join $dir libibdm.so.1.0]
}

package ifneeded ibdm 1.0 [list ibdmLoad $dir]
