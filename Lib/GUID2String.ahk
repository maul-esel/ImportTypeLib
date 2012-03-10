GUID2String(guid)
{
	local string
	DllCall("Ole32.dll\StringFromCLSID", "Ptr", guid, "Ptr*", string)
	return StrGet(string, "UTF-16")
}