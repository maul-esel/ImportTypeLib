VARIANT_Create(value, byRef buffer)
{
	static VT_VARIANT := 0xC
	local arr_data := 0, array := ComObjArray(VT_VARIANT, 1)

	array[0] := value

	DllCall("oleaut32\SafeArrayAccessData", "Ptr", ComObjValue(array), "Ptr*", arr_data)
	VarSetCapacity(buffer, 16, 00), Mem_Copy(arr_data, &buffer, 16)
	DllCall("oleaut32\SafeArrayUnaccessData", "Ptr", ComObjValue(array))

	return &buffer
}

VARIANT_GetValue(variant)
{
	static VT_VARIANT := 0xC
	local arr_data := 0, array := ComObjArray(VT_VARIANT, 1)

	DllCall("oleaut32\SafeArrayAccessData", "Ptr", ComObjValue(array), "Ptr*", arr_data)
	, Mem_Copy(variant, arr_data, 16)
	, DllCall("oleaut32\SafeArrayUnaccessData", "Ptr", ComObjValue(array))

	return array[0]
}