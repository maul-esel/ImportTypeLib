TI_IsGUID(str)
{
	return RegExMatch(str, "^\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}$")
}

TI_GetVersion(string, byRef ver_major, byRef ver_minor)
{
	return RegExMatch(string, "^(?P<major>\d+)\.(?P<minor>\d+)$", ver_)
}

TI_ConvertGUID(str, byRef mem)
{
	VarSetCapacity(mem, 16, 00)
	return DllCall("CLSIDFromString", "Str", str, "Ptr", &mem) >= 0x00
}

TI_FormatError(hr)
{
	static ALLOCATE_BUFFER := 0x00000100, FROM_SYSTEM := 0x00001000, IGNORE_INSERTS := 0x00000200
	local size, msg, bufaddr

	size := DllCall("FormatMessageW", "UInt", ALLOCATE_BUFFER|FROM_SYSTEM|IGNORE_INSERTS, "Ptr", 0, "UInt", hr, "UInt", 0, "Ptr*", bufaddr, "UInt", 0, "Ptr", 0)
	msg := StrGet(bufaddr, size, "UTF-16")

	return hr . " - " . msg
}