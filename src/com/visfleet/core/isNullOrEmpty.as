package com.visfleet.core {
	public function isNullOrEmpty(value:*):Boolean {
		return (value == null) || (value.toString() == ""); 
	}
}

