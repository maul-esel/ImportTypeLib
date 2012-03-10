class TI_TypeLibWrapper
{
	__New(lib)
	{
		static valid_typekinds
		local typeKind, hr, typename, obj

		if (!IsObject(valid_typekinds)) ; init static field
			 valid_typekinds := { 0 : TI_Wrapper.TI_EnumWrapper, 1 : TI_Wrapper.TI_StructureWrapper, 5 : TI_Wrapper.TI_CoClassWrapper }

		this["internal://typelib-instance"] := lib
		this["internal://typelib-name"] := this.GetName()

		Loop % DllCall(NumGet(NumGet(lib+0), 03*A_PtrSize, "Ptr"), "Ptr", lib, "Int")
		{
			hr := DllCall(NumGet(NumGet(lib+0), 05*A_PtrSize, "Ptr"), "Ptr", lib, "UInt", A_Index - 1, "UInt*", typeKind, "Int")
			if (FAILED(hr))
			{
				throw Exception("Type information kind no. " A_Index - 1 " could not be read.", -1, TI_FormatError(hr))
			}
			if (!valid_typekinds.HasKey(typeKind))
			{
				continue
			}

			hr := DllCall(NumGet(NumGet(lib+0), 04*A_PtrSize, "Ptr"), "Ptr", lib, "UInt", A_Index - 1, "Ptr*", typeInfo, "Int")
			if (FAILED(hr))
			{
				throw Exception("Type information no. " A_Index - 1 " could not be read.", -1, TI_FormatError(hr))
			}

			typename := this.GetName(A_Index - 1), obj := valid_typekinds[typeKind]
			this[typename] := new obj(typeInfo)
		}
	}

	GetName(index = -1)
	{
		local hr, name, lib

		lib := this["internal://typelib-instance"]
		hr := DllCall(NumGet(NumGet(lib+0), 09*A_PtrSize, "Ptr"), "Ptr", lib, "UInt", index, "Ptr*", name, "Ptr*", 0, "UInt*", 0, "Ptr*", 0, "Int")
		if (FAILED(hr))
		{
			throw Exception("Name for the " (index == -1 ? "type library" : "type description no. " index) " could not be read.", -1, TI_FormatError(hr))
		}

		return StrGet(name, "UTF-16")
	}
}