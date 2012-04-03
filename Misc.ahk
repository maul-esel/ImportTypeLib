; various misc. helper functions, later to be sorted out to separate classes / libs / files.

ITL_IsSafeArray(obj)
{
	static VT_ARRAY := 0x2000
	local vt := 0
	return (IsObject(obj) && ITL_HasEnumFlag(ComObjType(obj), VT_ARRAY)) ; a wrapper object was passed
		|| (ITL_SUCCEEDED(DllCall("OleAut32\SafeArrayGetVartype", "Ptr", obj, "UShort*", vt, "Int")) && vt && ITL_IsSafeArray(ComObjParameter(VT_ARRAY|vt, obj))) ; a raw SAFEARRAY pointer was passed
}

ITL_SafeArrayType(obj)
{
	static VT_ARRAY := 0x2000
	local vt := 0
	if (ITL_IsSafeArray(obj))
		return IsObject(obj)
			? (ComObjType(obj) ^ VT_ARRAY) ; a wrapper object was passed
			: (ITL_SUCCEEDED(DllCall("OleAut32\SafeArrayGetVartype", "Ptr", obj, "UShort*", vt, "Int")) && vt) ? vt : "" ; a raw SAFEARRAY pointer was passed
}

ITL_CreateStructureSafeArray(type, dims*)
{
	static VT_RECORD := 0x24
	local arr, hr

	if (dims.MaxIndex() > 8 || dims.MinIndex() != 1)
		throw Exception(ITL_FormatException("Failed to create a structure SAFEARRAY."
										, "Invalid dimensions were specified."
										, ErrorLevel)*)

	arr := ComObjArray(VT_RECORD, dims*)
	hr := DllCall("OleAut32\SafeArraySetRecordInfo", "Ptr", ComObjValue(arr), "Ptr", type[ITL.Properties.TYPE_RECORDINFO], "Int")
	if (ITL_FAILED(hr))
		throw Exception(ITL_FormatException("Failed to create a structure SAFEARRAY."
										, "Could not set IRecordInfo."
										, ErrorLevel, hr)*)

	return arr
}

; for structures and interfaces
ITL_GetInstancePointer(instance)
{
	return instance[ITL.Properties.INSTANCE_POINTER]
}

ITL_CreateStructureArray(type, count)
{
	return new ITL.ITL_StructureArray(type, count)
}