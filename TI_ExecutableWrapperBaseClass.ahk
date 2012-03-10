class TI_ExecutableWrapperBaseClass extends TI_Wrapper.TI_WrapperBaseClass
{
	__Call(method, p*)
	{
		; code inspired by AutoHotkey_L source (script_com.cpp)
		static INVOKE_FUNC := 1
		; ...
	}

	__Get(property)
	{
		; code inspired by AutoHotkey_L source (script_com.cpp)
		static INVOKE_PROPERTYGET := 2
		, DISPATCH_PROPERTYGET := 0x2, DISPATCH_METHOD := 0x1
		, sizeof_DISPPARAMS := 8 + 2 * A_PtrSize
		local dispparams, hr, info, dispid, instance, exception, err_index, result

		if (property != "base" && property != "internal://data-storage")
		{
			if (RegExMatch(property, "^internal://")) ; do not act on internal properties
			{
				return this["internal://data-storage"][property]
			}
			else
			{
				VarSetCapacity(dispparams, sizeof_DISPPARAMS, 00)

				info := this["internal://typeinfo-instance"]
				instance := this["internal://type-instance"]

				hr := DllCall(NumGet(NumGet(info+0), 10*A_PtrSize, "Ptr"), "Ptr", info, "Str*", property, "UInt", 1, "UInt*", dispid, "Int") ; ITypeInfo::GetIDsOfNames()
				if (FAILED(hr))
				{
					throw Exception("GetIDsOfNames for """ property """ failed.", -1, TI_FormatError(hr))
				}

				hr := DllCall(NumGet(NumGet(info+0), 11*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", instance, "UInt", dispid, "UShort", DISPATCH_METHOD, "Ptr", &dispparams, "Ptr*", result, "Ptr*", exception, "UInt*", err_index, "Int") ; ITypeInfo::Invoke()
				if (FAILED(hr))
				{
					ListVars
					throw Exception("""" property """ could not be retrieved.", -1, TI_FormatError(hr))
				}
				return ComObjValue(result)
			}
		}
	}

	__Set(property, value)
	{
		; code inspired by AutoHotkey_L source (script_com.cpp)
		static INVOKE_PROPERTYPUT := 4, INVOKE_PROPERTYPUTREF := 8
		, DISPATCH_PROPERTYPUTREF := 0x8, DISPATCH_PROPERTYPUT := 0x4
		, sizeof_DISPPARAMS := 8 + 2 * A_PtrSize, DISPID_PROPERTYPUT := -3
		, VT_UNKNOWN := 13, VT_DISPATCH := 9
		local variant, dispparams, hr, info, dispid, vt, instance, exception, err_index

		if (RegExMatch(property, "^internal:\/\/")) ; do not act on internal properties
			return this["internal://data-storage"][property] := value

		variant := CreateVARIANT(value)
		VarSetCapacity(dispparams, sizeof_DISPPARAMS, 00)

		NumPut(variant, dispparams, 00, "Ptr") ; DISPPARAMS::rgvarg
		NumPut(1, dispparams, 2 * A_PtrSize, "UInt") ; DISPPARAMS::cArgs

		NumPut(&DISPID_PROPERTYPUT, dispparams, A_PtrSize, "Ptr") ; DISPPARAMS::rgdispidNamedArgs
		NumPut(1, dispparams, 2 * A_PtrSize + 4, "UInt") ; DISPPARAMS::cNamedArgs

		info := this["internal://typeinfo-instance"]
		instance := this["internal://type-instance"]

		hr := DllCall(NumGet(NumGet(info+0), 10*A_PtrSize, "Ptr"), "Ptr", info, "Str*", property, "UInt", 1, "UInt*", dispid, "Int") ; ITypeInfo::GetIDsOfNames()
		if (FAILED(hr))
		{
			throw Exception("GetIDsOfNames failed.", -1, TI_FormatError(hr))
		}

		vt := NumGet(1*variant, 00, "UShort")
		if (vt == VT_DISPATCH || vt == VT_UNKNOWN)
		{
			hr := DllCall(NumGet(NumGet(info+0), 11*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", instance, "UInt", dispid, "UShort", DISPATCH_PROPERTYPUTREF, "Ptr", &dispparams, "Ptr*", 0, "Ptr*", exception, "UInt*", err_index, "Int") ; ITypeInfo::Invoke()
			if (SUCCEEDED(hr))
				return value
		}

		hr := DllCall(NumGet(NumGet(info+0), 11*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", instance, "UInt", dispid, "UShort", DISPATCH_PROPERTYPUT, "Ptr", &dispparams, "Ptr*", 0, "Ptr*", exception, "UInt*", err_index, "Int") ; ITypeInfo::Invoke()
		if (FAILED(hr))
		{
			throw Exception("""" property """ could not be set.", -1, TI_FormatError(hr))
		}
		return value
	}
}