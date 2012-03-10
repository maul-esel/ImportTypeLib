CreateVariant(value)
{
	static VT_VARIANT := 0xC, VT_BYREF := 0x4000, VT_UNKNOWN := 0xD
	local array, arr_data, variant, err

	array := ComObjArray(VT_VARIANT, 1)
	array[0] := value

	DllCall("oleaut32\SafeArrayAccessData", "Ptr", ComObjValue(array), "Ptr*", arr_data)
	variant := Mem_Allocate(16), Mem_Copy(arr_data, variant, 16)
	DllCall("oleaut32\SafeArrayUnaccessData", "Ptr", ComObjValue(array))

	return variant
}