GUID_ToString(guid)
{
	local string
	DllCall("Ole32.dll\StringFromCLSID", "Ptr", guid, "Ptr*", string)
	return StrGet(string, "UTF-16")
}

GUID_FromString(str, byRef mem)
{
	VarSetCapacity(mem, 16, 00)
	return DllCall("CLSIDFromString", "Str", str, "Ptr", &mem)
}

GUID_IsGUIDString(str)
{
	return RegExMatch(str, "^\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}$")
}