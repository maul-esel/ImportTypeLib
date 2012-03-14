class TI_ModuleWrapper extends TI_Wrapper.TI_WrapperBaseClass
{
	__New(typeInfo, lib)
	{
		local Base

		if (this != TI_Wrapper.TI_ModuleWrapper)
		{
			Base.__New(typeInfo, lib)
			ObjInsert(this, "__New", Func("TI_AbstractClassConstructor"))
		}
	}

	__Get(field)
	{
		static VARKIND_CONST := 2, DISPID_UNKNOWN := -1
		local hr, info, typeName, varID := DISPID_UNKNOWN, index := -1, varDesc := 0, varValue := ""

		if (field != "base" && !RegExMatch(field, "^internal://")) ; ignore base and internal properties (handled by TI_WrapperBaseClass)
		{
			info := this["internal://typeinfo-instance"]
			typeName := this["internal://typeinfo-name"]

			hr := DllCall(NumGet(NumGet(info+0), 10*A_PtrSize, "Ptr"), "Ptr", info, "Str*", field, "UInt", 1, "UInt*", varID, "Int") ; ITypeInfo::GetIDsOfNames()
			if (FAILED(hr) || varID == DISPID_UNKNOWN)
			{
				; allow omitting a typename prefix:
				; if the enum is called "MyEnum" and the field is called "MyEnum_Any",
				; then allow both "MyEnum.MyEnum_Any" and "MyEnum.Any"
				if (!InStr(field, typeName . "_", true) == 1) ; omit this if the field is already prefixed with the type name
				{
					hr := DllCall(NumGet(NumGet(info+0), 10*A_PtrSize, "Ptr"), "Ptr", info, "Str*", typeName "_" . field, "UInt", 1, "UInt*", varID, "Int") ; ITypeInfo::GetIDsOfNames()
				}
				if (FAILED(hr) || varID == DISPID_UNKNOWN) ; recheck as the above "if" might have changed it
				{
					throw Exception("GetIDsOfNames for """ field """ failed.", -1, FormatError(hr))
				}
			}

			hr := DllCall(NumGet(NumGet(info+0), 25*A_PtrSize, "Ptr"), "Ptr", info, "UInt", varID, "UInt*", index, "Int") ; ITypeInfo2::GetVarIndexOfMemId()
			if (FAILED(hr) || index < 0)
			{
				throw Exception("GetVarIndexOfMemId for """ field """ failed.", -1, FormatError(hr))
			}

			hr := DllCall(NumGet(NumGet(info+0), 06*A_PtrSize, "Ptr"), "Ptr", info, "UInt", index, "Ptr*", varDesc, "Int") ; ITypeInfo::GetVarDesc()
			if (FAILED(hr) || !varDesc)
			{
				throw Exception("VARDESC for """ field """ could not be read.", -1, FormatError(hr))
			}

			if (NumGet(1*varDesc, 08 + 6 * A_PtrSize, "UShort") != VARKIND_CONST) ; VARDESC::varkind
			{
				throw Exception("Cannot read non-constant enumeration member """ field """!", -1)
			}

			varValue := VARIANT_GetValue(NumGet(1 * varDesc, 04 + A_PtrSize, "Ptr")) ; VARDESC::lpvarValue
			DllCall(NumGet(NumGet(info+0), 21*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", varDesc) ; ITypeInfo::ReleaseVarDesc()

			return varValue
		}
	}

	__Set(field, value)
	{
	}

	__Call(method, params*)
	{
	}
}