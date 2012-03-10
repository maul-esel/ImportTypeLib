class TI_WrapperBaseClass
{
	__New(typeInfo)
	{
		local hr, name

		this["internal://typeinfo-instance"] := typeInfo

		hr := DllCall(NumGet(NumGet(typeInfo+0), 12*A_PtrSize, "Ptr"), "Ptr", typeInfo, "Int", -1, "Ptr*", name, "Ptr*", 0, "UInt*", 0, "Ptr*", 0, "Int")
		if (FAILED(hr))
		{
			throw Exception("Name for the type description could not be read.", -1, TI_FormatError(hr))
		}

		this["internal://typeinfo-name"] := StrGet(name, "UTF-16")
	}
}