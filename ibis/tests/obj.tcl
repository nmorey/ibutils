proc objDump {obj} {
	catch {$obj cget} atts
	puts "---- Object Dump ------"
	foreach attr [lindex $atts 0] {
		set an [string range $attr 1 end]
		puts "$an = [$obj cget $attr]"
	}
	puts "-----------------------"
}

proc objPtrDump {class objPtr} {
	if {[catch {$class __obj -this $objPtr;} e]} {
		puts $e
	} else {
		objDump __obj
		rename __obj ""
	}
}
