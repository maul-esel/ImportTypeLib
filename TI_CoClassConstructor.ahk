TI_CoClassConstructor(this, iid = 0)
{
	local instance, typeAttr, info, hr, clsid, iid_mem, implCount, implFlags, implHref, implInfo, implAttr
	static IMPLTYPEFLAG_FDEFAULT := 1

	info := this["internal://typeinfo-instance"]
	hr := DllCall(NumGet(NumGet(info+0), 03*A_PtrSize, "Ptr"), "Ptr", info, "Ptr*", typeAttr, "Int") ; ITypeInfo::GetTypeAttr()
	if (FAILED(hr) || !typeAttr)
	{
		throw Exception("TYPEATTR could not be read.", -1, TI_FormatError(hr))
	}

	if (!iid)
	{
		if (this["internal://default-iid"])
		{
			iid := TI_ConvertGUID(this["internal://default-iid"], iid_mem)
		}
		else
		{
			implCount := NumGet(1*typeAttr, 44+1*A_PtrSize, "UShort") ; TYPEATTR::cImplTypes
			Loop % implCount
			{
				hr := DllCall(NumGet(NumGet(info+0), 09*A_PtrSize, "Ptr"), "Ptr", info, "UInt", A_Index - 1, "UInt*", implFlags, "Int") ; ITypeInfo::GetImplTypeFlags()
				if (FAILED(hr))
				{
					throw Exception("ImplTypeFlags could not be read.", -1, TI_FormatError(hr))
				}
				if (HasEnumFlag(implFlags, IMPLTYPEFLAG_FDEFAULT))
				{
					hr := DllCall(NumGet(NumGet(info+0), 08*A_PtrSize, "Ptr"), "Ptr", info, "UInt", A_Index - 1, "UInt*", implHref, "Int") ; ITypeInfo::GetRefTypeOfImplType()
					if (FAILED(hr) || !implHref)
					{
						throw Exception("GetRefTypeOfImplType failed.", -1, TI_FormatError(hr))
					}

					hr := DllCall(NumGet(NumGet(info+0), 14*A_PtrSize, "Ptr"), "Ptr", info, "UInt", implHref, "Ptr*", implInfo, "Int") ; ITypeInfo::GetRefTypeInfo()
					if (FAILED(hr) || !implInfo)
					{
						throw Exception("GetRefTypeInfo failed.", -1, TI_FormatError(hr))
					}

					hr := DllCall(NumGet(NumGet(info+0), 03*A_PtrSize, "Ptr"), "Ptr", implInfo, "Ptr*", implAttr, "Int") ; ITypeInfo::GetTypeAttr()
					if (FAILED(hr) || !implAttr)
					{
						throw Exception("TYPEATTR could not be read.", -1, TI_FormatError(hr))
					}

					VarSetCapacity(iid_mem, 16, 00)
					Mem_Copy(implAttr, &iid_mem, 16) ; TYPEATTR::guid
					iid := &iid_mem

					DllCall(NumGet(NumGet(info+0), 19*A_PtrSize, "Ptr"), "Ptr", implInfo, "Ptr", implAttr) ; ITypeInfo::ReleaseTypeAttr()

					this["internal://default-iid"] := GUID2String(iid)
				}
			}
		}
	}
	else
	{
		iid := TI_ConvertGUID(iid, iid_mem)
	}

	VarSetCapacity(clsid, 16, 00)
	Mem_Copy(typeAttr, &clsid, 16) ; TYPEATTR::guid

	DllCall(NumGet(NumGet(info+0), 19*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", typeAttr) ; ITypeInfo::ReleaseTypeAttr()

	hr := DllCall(NumGet(NumGet(info+0), 16*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", 0, "Ptr", iid, "Ptr*", instance, "Int") ; ITypeInfo::CreateInstance()
	if (FAILED(hr) || !instance)
	{
		throw Exception("CreateInstance failed.", -1, TI_FormatError(hr))
	}
	this["internal://type-instance"] := instance
}