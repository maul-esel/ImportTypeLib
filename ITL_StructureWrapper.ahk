class ITL_StructureWrapper extends ITL_Wrapper.ITL_WrapperBaseClass
{
	__New(typeInfo)
	{
		local Base, hr, rcinfo := 0
		if (this != ITL_Wrapper.ITL_StructureWrapper)
		{
			Base.__New(typeInfo)

			hr := DllCall("OleAut32\GetRecordInfoFromTypeInfo", "Ptr", this["internal://typeinfo-instance"], "Ptr*", rcinfo, "Int")
			if (ITL_FAILED(hr) || !rcinfo)
			{
				throw Exception("GetRecordInfoFromTypeInfo() failed.", -1, ITL_FormatError(hr))
			}
			this["internal://rcinfo-instance"] := rcinfo

			ObjInsert(this, "__New", Func("ITL_StructureConstructor"))
		}
	}

	__Get(field)
	{
		; ...
	}

	__Set(field, value)
	{
		; ...
	}
}