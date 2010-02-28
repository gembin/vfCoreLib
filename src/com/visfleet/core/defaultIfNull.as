package com.visfleet.core {
	public function defaultIfNull(value:*,defaultValue:*):* {
		if (isNull(value))  
			return defaultValue;

		return value;
	}
}
