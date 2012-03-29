/*
Function: ImportTypeLib
loads a type library and returns a wrapper object

Parameters:
	lib - either the path to the library or the GUID if it is registered within the system.
		If the path passed points to a file (e.g. a DLL) containing the type library, but it is not the first resource, append the index like so:
		> ImportTypeLib("C:\Path\to\Lib.dll\2")
	[opt] version - if a GUID is passed, specify the type library version here. Defaults to "1.0" (use exactly that format!).
*/
ImportTypeLib(lib, version = "1.0")
{
	local ver, verMajor, verMinor, libid, hr

	if (ITL_GUID_IsGUIDString(lib))
	{
		if (!RegExMatch(version, "^(?P<Major>\d+)\.(?P<Minor>\d+)$", ver))
		{
			;throw Exception("Invalid version specified: """ version """.", -1)
			throw Exception(ITL_FormatException("An invalid version was specified: """ version """.", "", ErrorLevel)*)
		}

		hr := ITL_GUID_FromString(lib, libid)
		if (ITL_FAILED(hr))
		{
			;throw Exception("LIBID could not be converted: """ lib """.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("Failed to load type library.", "LIBID """ lib """ could not be converted.", ErrorLevel, hr)*)
		}

		hr := DllCall("OleAut32\LoadRegTypeLib", "Ptr", &libid, "UShort", verMajor, "UShort", verMinor, "UInt", 0, "Ptr*", lib, "Int") ; error handling is done below

		VarSetCapacity(libid, 0)
	}
	else
	{
		hr := DllCall("OleAut32\LoadTypeLib", "Str", lib, "Ptr*", lib, "Int") ; error handling is done below
	}

	if (ITL_FAILED(hr) || !lib)
	{
		;throw Exception("Loading of type library failed.", -1, ITL_FormatError(hr))
		throw Exception(ITL_FormatException("Failed to load type library.", "", ErrorLevel, hr, !lib, "Invalid ITypeLibrary pointer: " lib)*)
	}
	return new ITL_Wrapper.ITL_TypeLibWrapper(lib)
}
ITL_FAILED(hr)
{
	return hr == "" || hr < 0
}
ITL_FormatError(hr)
{
	static ALLOCATE_BUFFER := 0x00000100, FROM_SYSTEM := 0x00001000, IGNORE_INSERTS := 0x00000200
	local size, msg, bufaddr := 0

	size := DllCall("FormatMessageW", "UInt", ALLOCATE_BUFFER|FROM_SYSTEM|IGNORE_INSERTS, "Ptr", 0, "UInt", hr, "UInt", 0, "Ptr*", bufaddr, "UInt", 0, "Ptr", 0)
	msg := StrGet(bufaddr, size, "UTF-16")

	return hr . " - " . Trim(msg, " `t`r`n")
}
ITL_GUID_ToString(guid)
{
	local string := 0
	DllCall("Ole32\StringFromCLSID", "Ptr", guid, "Ptr*", string)
	return StrGet(string, "UTF-16")
}

ITL_GUID_FromString(str, byRef mem)
{
	VarSetCapacity(mem, 16, 00)
	return DllCall("Ole32\CLSIDFromString", "Str", str, "Ptr", &mem)
}

ITL_GUID_IsGUIDString(str)
{
	return RegExMatch(str, "^\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}$")
}

ITL_GUID_Create(byRef guid)
{
	VarSetCapacity(guid, 16, 00)
	return DllCall("Ole32\CoCreateGuid", "Ptr", &guid, "Int")
}
ITL_HasEnumFlag(combi, flag)
{
	return (combi & flag) == flag
}
ITL_Mem_Allocate(bytes)
{
	static HEAP_GENERATE_EXCEPTIONS := 0x00000004, HEAP_ZERO_MEMORY := 0x00000008
	return DllCall("HeapAlloc", "Ptr", ITL_Mem_GetHeap(), "UInt", HEAP_GENERATE_EXCEPTIONS|HEAP_ZERO_MEMORY, "UInt", bytes, "Ptr")
}
ITL_Mem_GetHeap()
{
	static heap := DllCall("GetProcessHeap", "Ptr")
	return heap
}
ITL_Mem_Release(buffer)
{
	return DllCall("HeapFree", "Ptr", ITL_Mem_GetHeap(), "UInt", 0, "Ptr", buffer, "Int")
}
ITL_Mem_Copy(src, dest, bytes)
{
	DllCall("RtlMoveMemory", "Ptr", dest, "Ptr", src, "UInt", bytes)
}
ITL_SUCCEEDED(hr)
{
	return hr != "" && hr >= 0x00
}
ITL_VARIANT_Create(value, byRef buffer)
{
	static VT_VARIANT := 0xC, sizeof_VARIANT := 8 + 2 * A_PtrSize
	local arr_data := 0, array := ComObjArray(VT_VARIANT, 1)

	array[0] := value

	DllCall("oleaut32\SafeArrayAccessData", "Ptr", ComObjValue(array), "Ptr*", arr_data)
	VarSetCapacity(buffer, 16, 00), ITL_Mem_Copy(arr_data, &buffer, sizeof_VARIANT)
	DllCall("oleaut32\SafeArrayUnaccessData", "Ptr", ComObjValue(array))

	return &buffer
}

ITL_VARIANT_GetValue(variant)
{
	static VT_VARIANT := 0xC, VT_UNKNOWN := 0xD
	local array := ComObjArray(VT_VARIANT, 1), vt := 0

	vt := NumGet(1*variant, 00, "UShort")
	array[0] := ComObjParameter(vt, NumGet(1*variant, 08, "Int64"))

	return vt == VT_UNKNOWN ? NumGet(1*variant, 08, "Ptr") : array[0]
}

ITL_VARIANT_MapType(variant)
{
	; handled types:
	static VT_EMPTY := 0, VT_NULL := 1, VT_BYREF := 0x4000, VT_I1 := 16, VT_UI1 := 17, VT_I2 := 2, VT_UI2 := 18, VT_I4 := 3, VT_BOOL := 0xB, VT_INT := 22, VT_ERROR := 0xA, VT_HRESULT := 25, VT_UI4 := 19, VT_UINT := 23, VT_I8 := 20, VT_UI8 := 21, VT_CY := 6, VT_R4 := 4, VT_R8 := 5, VT_BSTR := 0x8, VT_LPSTR := 30, VT_LPWSTR := 31, VT_DISPATCH := 9, VT_UNKNOWN := 13, VT_PTR := 26, VT_INT_PTR := 37, VT_UINT_PTR := 38

	; unhandled types:
	static VT_DATE := 7, VT_VARIANT := 12, VT_DECIMAL := 14, VT_VOID := 24, VT_SAFEARRAY := 27, VT_ARRAY := 0x2000, VT_CARRAY := 28, VT_USERDEFINED := 29, VT_RECORD := 36, VT_FILETIME := 64, VT_BLOB := 65, VT_STREAM := 66, VT_STORAGE := 67, VT_STREAMED_OBJECT := 68, VT_STORED_OBJECT := 69, VT_BLOB_OBJECT := 70, VT_CF := 71, VT_CLSID := 72, VT_VERSIONED_STREAM := 73, VT_BSTR_BLOB := 0xffff, VT_VECTOR := 0x1000

	static map := ""
	local vt := 0, suffix := "", type := ""

	; init static var:
	if (!IsObject(map))
	{
		map := {  (VT_I1)		: "Char",	(VT_UI1)	: "UChar"
				, (VT_I2)		: "Short",	(VT_UI2)	: "UShort"
				, (VT_I4)		: "Int",	(VT_BOOL)	: "Int",	(VT_INT)	: "Int",	(VT_HRESULT) : "Int", (VT_ERROR) : "Int", (VT_UI4) : "UInt", (VT_UINT) : "UInt"
				, (VT_I8)		: "Int64",	(VT_CY)		: "Int64",	(VT_UI8)	: "Int64"
				, (VT_R4)		: "Float",	(VT_R8)		: "Double"
				, (VT_BSTR)		: "WStr",	(VT_LPSTR)	: "Str",	(VT_LPWSTR) : "WStr"
				, (VT_DISPATCH)	: "Ptr",	(VT_UNKNOWN): "Ptr",	(VT_PTR)	: "Ptr",	(VT_INT_PTR) : "Ptr", (VT_UINT_PTR) : "UPtr" }
	}

	vt := NumGet(1*variant, 00, "UShort")
	if (ITL_HasEnumFlag(vt, VT_BYREF))
	{
		vt ^= VT_BYREF, suffix := "*" ; change this handling (?)
	}

	if (vt == VT_EMPTY || vt == VT_NULL)
		throw Exception("Cannot map type 'EMPTY' or 'NULL'.", -1)
	else if (map.HasKey(vt))
		return map[vt] . suffix

	throw Exception("Could not map type " vt ".", -1)
}

ITL_VARIANT_GetByteCount(variant)
{
	throw Exception("Could not retrieve byte count.", -1, "Not implemented.")
}
ITL_FormatException(msg, detail, error, hr = "", special = false, special_msg = "")
{
	static NL := "`n`t"
	return [ "ImportTypeLib encountered an error:" . NL . msg
			, -1
			, (detail != ""	? NL . detail										:	"")
			. (ErrorLevel	? NL . "ErrorLevel: " error							:	"")
			. (A_LastError	? NL . "A_LastError: " ITL_FormatError(A_LastError)	:	"")
			. (hr != ""		? NL . "HRESULT: " ITL_FormatError(hr)				:	"")
			. (special		? NL . special_msg									:	"") ]
}
ITL_CoClassConstructor(this, iid = 0)
{
	static IMPLTYPEFLAG_FDEFAULT := 1
	local info, typeAttr := 0, hr, iid_mem, instance := 0

	info := this.base["internal://typeinfo-instance"]

	hr := DllCall(NumGet(NumGet(info+0), 03*A_PtrSize, "Ptr"), "Ptr", info, "Ptr*", typeAttr, "Int") ; ITypeInfo::GetTypeAttr()
	if (ITL_FAILED(hr) || !typeAttr)
	{
		;throw Exception("TYPEATTR could not be read.", -1, ITL_FormatError(hr))
		throw Exception(ITL_FormatException("Failed to create an instance of the class """ this.base["internal://typeinfo-name"] """."
										, "ITypeInfo::GetTypeAttr() failed."
										, ErrorLevel, hr
										, !typeAttr, "Invalid TYPEATTR pointer: " typeAttr)*)
	}

	if (!iid)
	{
		iid := this.base["internal://default-iid"] ; get coclass default interface
		if (!iid) ; there's no default interface
		{
			;throw Exception("An IID must be specified to create an instance of this class.", -1)
			throw Exception(ITL_FormatException("Failed to create an instance of the class """ this.base["internal://typeinfo-name"] """."
											, "An IID must be specified to create an instance of this class."
											, ErrorLevel)*)
		}
	}

	hr := ITL_GUID_FromString(iid, iid_mem)
	if (ITL_FAILED(hr))
	{
		;throw Exception("GUID could not be converted.", -1, ITL_FormatError(hr))
		throw Exception(ITL_FormatException("Failed to create an instance of the class """ this.base["internal://typeinfo-name"] """."
										, "The IID """ iid """ could not be converted."
										, ErrorLevel, hr)*)
	}
	iid := &iid_mem

	hr := DllCall(NumGet(NumGet(info+0), 16*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", 0, "Ptr", iid, "Ptr*", instance, "Int") ; ITypeInfo::CreateInstance()
	if (ITL_FAILED(hr) || !instance)
	{
		;throw Exception("CreateInstance failed.", -1, ITL_FormatError(hr))
		throw Exception(ITL_FormatException("Failed to create an instance of the class """ this.base["internal://typeinfo-name"] """."
										, "ITypeInfo::CreateInstance() failed."
										, ErrorLevel, hr
										, !instance, "Invalid instance pointer: " instance)*)
	}

	return instance
}
; Function: ITL_AbstractClassConstructor
; This is simply a wrapper for "abstract classes", i.e. an exception is thrown when it is called.
; "Abstract" classes set this as their constructor.
ITL_AbstractClassConstructor(this, p*)
{
	;throw Exception("An instance of the class """ this.__class """ must not be created.", -1)
	throw Exception(ITL_FormatException("An instance of the class """ this.__class """ must not be created."
										, "The class is abstract."
										, 0)*)
}
ITL_StructureConstructor(this, ptr = 0, noInit = false)
{
	local hr, rcinfo := this.base["internal://rcinfo-instance"]

	if (!ptr)
	{
		ptr := DllCall(NumGet(NumGet(rcinfo+0), 16*A_PtrSize, "Ptr"), "Ptr", rcinfo, "Ptr") ; IRecordInfo::RecordCreate()
		if (!ptr)
		{
			throw Exception(ITL_FormatException("Failed to create an instance of the """ this.base["internal://typeinfo-name"] """ structure."
											, "IRecordInfo::RecordCreate() failed."
											, ErrorLevel, ""
											, !ptr, "Invalid instance pointer: " ptr)*)
		}
	}
	else if (!noInit)
	{
		hr := DllCall(NumGet(NumGet(rcinfo+0), 03*A_PtrSize, "Ptr"), "Ptr", rcinfo, "Ptr", ptr, "Int") ; IRecordInfo::RecordInit()
		if (ITL_FAILED(hr))
		{
			;throw Exception("RecordInit() failed.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("Failed create an instance of the """ this.base["internal://typeinfo-name"] """ structure."
											, "IRecordInfo::RecordInit() failed."
											, ErrorLevel, hr)*)
		}
	}

	this["internal://type-instance"] := ptr
}
ITL_InterfaceConstructor(this, instance)
{
	local interfacePtr
	if (!instance)
	{
		throw Exception("An instance of abstract type " this.__class " must not be created without supplying a valid instance pointer.", -1)
	}
	interfacePtr := ComObjQuery(instance, this["internal://interface-iid"])
	if (!interfacePtr)
	{
		;throw Exception("This interface is not supported by the given class instance.", -1)
		throw Exception(ITL_FormatException("Failed to create an instance of interface """ this.base["internal://typeinfo-name"] """."
										, "The interface is not supported by the given class instance."
										, ErrorLevel, ""
										, !interfacePtr, "Invalid pointer returned by ComObjQuery() : " interfacePtr)*)
	}
	this["internal://type-instance"] := interfacePtr
}
class ITL_Wrapper
{
	static __New := Func("ITL_AbstractClassConstructor")
class ITL_WrapperBaseClass
{
	__New(typeInfo, lib)
	{
		local hr, name := 0, typeInfo2
		static IID_ITypeInfo2 := "{00020412-0000-0000-C000-000000000046}"

		if (this != ITL_Wrapper.ITL_WrapperBaseClass)
		{
			ObjInsert(this, "internal://data-storage", {})
			this["internal://typelib-object"] := lib, ObjAddRef(lib)

			hr := DllCall(NumGet(NumGet(typeInfo+0), 12*A_PtrSize, "Ptr"), "Ptr", typeInfo, "Int", -1, "Ptr*", name, "Ptr*", 0, "UInt*", 0, "Ptr*", 0, "Int") ; ITypeInfo::GetDocumentation()
			if (ITL_FAILED(hr) || !name)
			{
				;throw Exception("Name for the type description could not be read.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to create a wrapper instance."
												, "ITypeInfo::GetDocumentation() failed."
												, ErrorLevel, hr
												, !name, "Invalid name pointer: " name)*)
			}

			this["internal://typeinfo-name"] := StrGet(name, "UTF-16")

			typeInfo2 := ComObjQuery(typeInfo, IID_ITypeInfo2)
			if (!typeInfo2)
			{
				;throw Exception("QueryInterface() failed.", -1)
				throw Exception(ITL_FormatException("Failed to create a wrapper instance."
												, "QueryInterface() for ITypeInfo2 failed."
												, ErrorLevel, ""
												, !typeInfo2, "Invalid ITypeInfo2 pointer returned by ComObjQuery() : " typeInfo2)*)
			}
			this["internal://typeinfo-instance"] := typeInfo2, ObjAddRef(typeInfo2)
		}
	}

	__Delete()
	{
		ObjRelease(this["internal://typelib-object"])
		, ObjRelease(this["internal://typeinfo-instance"])
	}

	__Set(property, value)
	{
		if (property != "base" && !RegExMatch(property, "^internal://"))
			return this["internal://data-storage"][property] := value
	}

	__Get(property)
	{
		if (property != "base" && !RegExMatch(property, "^internal://"))
			return this["internal://data-storage"][property]
	}
}
; class: ITL_ConstantMemberWrapperBaseClass
; This is the base class for types that have constant variable members, i.e. enums and modules.
class ITL_ConstantMemberWrapperBaseClass extends ITL_Wrapper.ITL_WrapperBaseClass
{
	; method: __Get
	; gets the value of an enumeration field or module constant.
	__Get(field)
	{
		static VARKIND_CONST := 2, DISPID_UNKNOWN := -1
		local hr, info, typeName, varID := DISPID_UNKNOWN, index := -1, varDesc := 0, varValue := ""

		if (field != "base" && !RegExMatch(field, "^internal://")) ; ignore base and internal properties (handled by ITL_WrapperBaseClass)
		{
			info := this["internal://typeinfo-instance"]
			typeName := this["internal://typeinfo-name"]

			; get the member id for the given field name
			hr := DllCall(NumGet(NumGet(info+0), 10*A_PtrSize, "Ptr"), "Ptr", info, "Str*", field, "UInt", 1, "UInt*", varID, "Int") ; ITypeInfo::GetIDsOfNames()
			if (ITL_FAILED(hr) || varID == DISPID_UNKNOWN)
			{
				; allow omitting a typename prefix:
				; if the enum is called "MyEnum" and the field is called "MyEnum_Any",
				; then allow both "MyEnum.MyEnum_Any" and "MyEnum.Any"
				if (!InStr(field, typeName . "_", true) == 1) ; omit this if the field is already prefixed with the type name
				{
					hr := DllCall(NumGet(NumGet(info+0), 10*A_PtrSize, "Ptr"), "Ptr", info, "Str*", typeName "_" . field, "UInt", 1, "UInt*", varID, "Int") ; ITypeInfo::GetIDsOfNames()
				}
				if (ITL_FAILED(hr) || varID == DISPID_UNKNOWN) ; recheck as the above "if" might have changed it
				{
					;throw Exception("GetIDsOfNames() for """ field """ failed.", -1, ITL_FormatError(hr))
					throw Exception(ITL_FormatException("Failed to retrieve a constant field."
													, "ITypeInfo::GetIDsOfNames() failed on """ field """."
													, ErrorLevel, hr
													, varID == DISPID_UNKNOWN, "Invalid DISPID: " varID)*)
				}
			}

			; map the member id to the index of the variable:
			hr := DllCall(NumGet(NumGet(info+0), 25*A_PtrSize, "Ptr"), "Ptr", info, "UInt", varID, "UInt*", index, "Int") ; ITypeInfo2::GetVarIndexOfMemId()
			if (ITL_FAILED(hr) || index < 0)
			{
				;throw Exception("GetVarIndexOfMemId() for """ field """ failed.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to retrieve a constant field."
												, "ITypeInfo2::GetVarIndexOfMemId() failed on """ field """."
												, ErrorLevel, hr
												, index < 0, "Invalid VARDESC index: " index)*)
			}

			; now use the index to get the VARDESC structure:
			hr := DllCall(NumGet(NumGet(info+0), 06*A_PtrSize, "Ptr"), "Ptr", info, "UInt", index, "Ptr*", varDesc, "Int") ; ITypeInfo::GetVarDesc()
			if (ITL_FAILED(hr) || !varDesc)
			{
				;throw Exception("VARDESC for """ field """ could not be read.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to retrieve a constant field."
												, "ITypeInfo::GetVarDesc() failed on """ field """."
												, ErrorLevel, hr
												, !varDesc, "Invalid VARDESC pointer: " varDesc)*)
			}

			; check if it is actually a constant we can map (it is very unlikely / impossible that it's something different, yet check to be sure)
			if (NumGet(1*varDesc, 04 + 7 * A_PtrSize, "UShort") != VARKIND_CONST) ; VARDESC::varkind
			{
				;throw Exception("Cannot read non-constant member """ field """!", -1)
				throw Exception(ITL_FormatException("Failed to retrieve a constant field."
												, "Field """ field """ is not constant!"
												, ErrorLevel)*)
			}

			; get the VARIANT value out of the structure and get it's real value:
			varValue := ITL_VARIANT_GetValue(NumGet(1 * varDesc, 2 * A_PtrSize, "Ptr")) ; VARDESC::lpvarValue

			; we don't need the VARDESC structure anymore, so officially release it:
			DllCall(NumGet(NumGet(info+0), 21*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", varDesc) ; ITypeInfo::ReleaseVarDesc()

			return varValue
		}
	}

	; method: __Set
	; throws an error if an attempt is made to change a constant value
	__Set(field, params*)
	{
		if (field != "base" && !RegExMatch(field, "^internal://")) ; ignore base and internal properties (handled by ITL_WrapperBaseClass)
		{
			; throw an exception as setting constants is impossible
			;throw Exception("A field must not be set on this class!", -1)
			throw Exception(ITL_FormatException("Failed to set constant field """ field """."
											, "By definition, constant field cannot be set."
											, ErrorLevel)*)
		}
	}

	; method: _NewEnum
	; allows the object to be used within a for-loop
	_NewEnum()
	{
		static VARKIND_CONST := 2
		local hr, typeName, info, obj, attr := 0, varCount, varDesc := 0, varID, pVarName := 0, varValue

		; only loop through the members once, since the constant values won't change
		obj := this["internal://enumerator-object"]
		if (!IsObject(obj)) ; if this is the first iteration
		{
			obj := this["internal://enumerator-object"] := {} ; create a storage object
			typeName := this["internal://typeinfo-name"]
			info := this["internal://typeinfo-instance"]

			; get some attributes of the type
			hr := DllCall(NumGet(NumGet(info+0), 03*A_PtrSize, "Ptr"), "Ptr", info, "Ptr*", attr, "Int") ; ITypeInfo::GetTypeAttr()
			if (ITL_FAILED(hr) || !attr)
			{
				;throw Exception("TYPEATTR could not be read.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to enumerate constant fields of type """ typeName """."
												, "ITypeInfo::GetTypeAttr() failed."
												, ErrorLevel, hr
												, !attr, "Invalid TYPEATTR pointer: " attr)*)
			}
			; get the count of variables from the attribute structure
			varCount := NumGet(1*attr, 42+1*A_PtrSize, "UShort") ; TYPEATTR::cVars

			; release the structure as we don't need it any longer
			DllCall(NumGet(NumGet(info+0), 19*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", attr) ; ITypeInfo::ReleaseTypeAttr()

			Loop % varCount ; loop through all variables
			{
				; get the variable description for the current variable (from zero-based index)
				hr := DllCall(NumGet(NumGet(info+0), 06*A_PtrSize, "Ptr"), "Ptr", info, "UInt", A_Index - 1, "Ptr*", varDesc, "Int") ; ITypeInfo::GetVarDesc()
				if (ITL_FAILED(hr) || !varDesc)
				{
					;throw Exception("VARDESC no. " A_Index - 1 " could not be read.", -1, ITL_FormatError(hr))
					throw Exception(ITL_FormatException("Failed to enumerate constant fields of type """ typeName """."
													, "ITypeInfo::GetVarDesc() failed on index " A_Index - 1 "."
													, ErrorLevel, hr
													, !varDesc, "Invalid VARDESC pointer: " varDesc)*)
				}

				; check if it is actually a constant we can map (it is very unlikely / impossible that it's something different, yet check to be sure)
				if (NumGet(1*varDesc, 04 + 7 * A_PtrSize, "UShort") != VARKIND_CONST) ; VARDESC::varkind
				{
					;throw Exception("Cannot read non-constant member """ field """!", -1)
					throw Exception(ITL_FormatException("Failed to enumerate constant fields of type """ typeName """."
													, "Field  no. " A_Index - 1 " is not constant!"
													, ErrorLevel)*)
				}

				; from the structure, get the variable member id:
				varID := NumGet(1*varDesc, 00, "Int") ; VARDESC::memid

				; retrieve the field name
				hr := DllCall(NumGet(NumGet(info+0), 12*A_PtrSize, "Ptr"), "Ptr", info, "Int", varID, "Ptr*", pVarName, "Ptr", 0, "UInt", 0, "Ptr", 0, "Int") ; ITypeInfo::GetDocumentation()
				if (ITL_FAILED(hr) || !pVarName)
				{
					;throw Exception("GetDocumentation() failed.", -1, ITL_FormatError(hr))
					throw Exception(ITL_FormatException("Failed to enumerate constant fields of type """ typeName """."
													, "ITypeInfo::GetDocumentation() failed on field no. " A_Index - 1 "."
													, ErrorLevel, hr
													, !pVarName, "Invalid name pointer: " pVarName)*)
				}

				; get the VARIANT out of the structure and retrieve its value:
				varValue := ITL_VARIANT_GetValue(NumGet(1 * varDesc, 2 * A_PtrSize, "Ptr")) ; VARDESC::lpvarValue

				; store the field in the enumerator object:
				obj[StrGet(pVarName, "UTF-16")] := varValue

				; release the structure as we're finished with this variable
				DllCall(NumGet(NumGet(info+0), 21*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", varDesc) ; ITypeInfo::ReleaseVarDesc()
				; reset local variables
				pVarName := 0, varDesc := 0
			}
		}

		; return a builtin enumerator for the field-value object:
		return ObjNewEnum(obj)
	}

	NewEnum()
	{
		; allow both syntaxes: obj.NewEnum() redirects to obj._NewEnum()
		return this._NewEnum()
	}
}
class ITL_CoClassWrapper extends ITL_Wrapper.ITL_WrapperBaseClass
{
	__New(typeInfo, lib)
	{
		local hr, typeAttr := 0, implCount, implFlags := 0, implHref := -1, implInfo := 0, implAttr := 0, iid, Base
		static IMPLTYPEFLAG_FDEFAULT := 1

		if (this != ITL_Wrapper.ITL_CoClassWrapper)
		{
			Base.__New(typeInfo, lib)
			ObjInsert(this, "__New", Func("ITL_CoClassConstructor"))
			this["internal://class-clsid"] := lib.GetGUID(typeInfo, false, true)

			; get default interface:
			; =======================================
			hr := DllCall(NumGet(NumGet(typeInfo+0), 03*A_PtrSize, "Ptr"), "Ptr", typeInfo, "Ptr*", typeAttr, "Int") ; ITypeInfo::GetTypeAttr()
			if (ITL_FAILED(hr) || !typeAttr)
			{
				;throw Exception("TYPEATTR could not be read.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to retrieve the default interface for the """ this["internal://typeinfo-name"] """ class."
												, "ITypeInfo::GetTypeAttr() failed."
												, ErrorLevel, hr
												, !typeAttr, "Invalid TYPEATTR pointer: " typeAttr)*)
			}

			implCount := NumGet(1*typeAttr, 44+1*A_PtrSize, "UShort") ; TYPEATTR::cImplTypes
			Loop % implCount
			{
				hr := DllCall(NumGet(NumGet(typeInfo+0), 09*A_PtrSize, "Ptr"), "Ptr", typeInfo, "UInt", A_Index - 1, "UInt*", implFlags, "Int") ; ITypeInfo::GetImplTypeFlags()
				if (ITL_FAILED(hr))
				{
					;throw Exception("ImplTypeFlags could not be read.", -1, ITL_FormatError(hr))
					throw Exception(ITL_FormatException("Failed to retrieve the default interface for the """ this["internal://typeinfo-name"] """ class."
														, "ITypeInfo::GetImplTypeFlags() failed."
														, ErrorLevel, hr)*)
				}
				if (ITL_HasEnumFlag(implFlags, IMPLTYPEFLAG_FDEFAULT))
				{
					hr := DllCall(NumGet(NumGet(typeInfo+0), 08*A_PtrSize, "Ptr"), "Ptr", typeInfo, "UInt", A_Index - 1, "UInt*", implHref, "Int") ; ITypeInfo::GetRefTypeOfImplType()
					if (ITL_FAILED(hr) || implHref == -1)
					{
						;throw Exception("GetRefTypeOfImplType failed.", -1, ITL_FormatError(hr))
						throw Exception(ITL_FormatException("Failed to retrieve the default interface for the """ this["internal://typeinfo-name"] """ class."
														, "ITypeInfo::GetRefTypeOfImplType() failed."
														, ErrorLevel, hr
														, implHref == -1, "Invalid HREFTYPE: " implHref)*)
					}

					hr := DllCall(NumGet(NumGet(typeInfo+0), 14*A_PtrSize, "Ptr"), "Ptr", typeInfo, "UInt", implHref, "Ptr*", implInfo, "Int") ; ITypeInfo::GetRefTypeInfo()
					if (ITL_FAILED(hr) || !implInfo)
					{
						;throw Exception("GetRefTypeInfo failed.", -1, ITL_FormatError(hr))
						throw Exception(ITL_FormatException("Failed to retrieve the default interface for the """ this["internal://typeinfo-name"] """ class."
														, "ITypeInfo::GetRefTypeInfo() failed."
														, ErrorLevel, hr
														, !implInfo, "Invalid ITypeInfo pointer: " implInfo)*)
					}

					hr := DllCall(NumGet(NumGet(implInfo+0), 03*A_PtrSize, "Ptr"), "Ptr", implInfo, "Ptr*", implAttr, "Int") ; ITypeInfo::GetTypeAttr()
					if (ITL_FAILED(hr) || !implAttr)
					{
						;throw Exception("TYPEATTR could not be read.", -1, ITL_FormatError(hr))
						throw Exception(ITL_FormatException("Failed to retrieve the default interface for the """ this["internal://typeinfo-name"] """ class."
														, "ITypeInfo::GetTypeAttr() failed."
														, ErrorLevel, hr
														, !implAttr, "Invalid TYPEATTR pointer: " implAttr)*)
					}

					VarSetCapacity(iid, 16, 00)
					ITL_Mem_Copy(implAttr, &iid, 16) ; TYPEATTR::guid
					this["internal://default-iid"] := ITL_GUID_ToString(&iid)

					DllCall(NumGet(NumGet(implInfo+0), 19*A_PtrSize, "Ptr"), "Ptr", implInfo, "Ptr", implAttr) ; ITypeInfo::ReleaseTypeAttr()
					break
				}
			}
			DllCall(NumGet(NumGet(typeInfo+0), 19*A_PtrSize, "Ptr"), "Ptr", typeInfo, "Ptr", typeAttr) ; ITypeInfo::ReleaseTypeAttr()
			; =======================================
		}
	}
}
; class: ITL_InterfaceWrapper
; This class enwraps COM interfaces and provides the ability to call methods, set and retrieve properties.
class ITL_InterfaceWrapper extends ITL_Wrapper.ITL_WrapperBaseClass
{
	; method: __New
	; This is the constructor for the wrapper, used by ITL_TypeLibWrapper.
	__New(typeInfo, lib)
	{
		local Base
		if (this != ITL_Wrapper.ITL_InterfaceWrapper)
		{
			Base.__New(typeInfo, lib)
			ObjInsert(this, "__New", Func("ITL_InterfaceConstructor")) ; change constructor for instances
			this["internal://interface-iid"] := lib.GetGUID(typeInfo, false, true) ; save IID
		}
	}

	; method: __Call
	; calls a method in the wrapped interface
	__Call(method, params*)
	{
		; code inspired by AutoHotkey_L source (script_com.cpp)
		static DISPATCH_METHOD := 0x1
		, DISPID_UNKNOWN := -1
		, sizeof_DISPPARAMS := 8 + 2 * A_PtrSize, sizeof_EXCEPINFO := 12 + 5 * A_PtrSize, sizeof_VARIANT := 8 + 2 * A_PtrSize
		, DISP_E_MEMBERNOTFOUND := -2147352573, DISP_E_UNKNOWNNAME := -2147352570
		, INVOKEKIND_FUNC := 1
		local paramCount, dispparams, rgvarg := 0, hr, info, dispid := DISPID_UNKNOWN, instance, excepInfo, err_index, result, variant, index := -1, funcdesc := 0, vt ;, fn

		paramCount := params.maxIndex() > 0 ? params.maxIndex() : 0 ; the ternary is necessary, otherwise it would hold an empty string, causing calculations to fail
		info := this["internal://typeinfo-instance"]
		instance := this["internal://type-instance"]

		; init structures
		if (VarSetCapacity(dispparams, sizeof_DISPPARAMS, 00) != sizeof_DISPPARAMS)
		{
			;throw Exception("Out of memory.", -1)
			throw Exception(ITL_FormatException("Out of memory", "Memory allocation for DISPPARAMS failed.", ErrorLevel)*)
		}
		if (VarSetCapacity(result, sizeof_VARIANT, 00) != sizeof_VARIANT)
		{
			;throw Exception("Out of memory.", -1)
			throw Exception(ITL_FormatException("Out of memory", "Memory allocation for the result VARIANT failed.", ErrorLevel)*)
		}
		if (VarSetCapacity(excepInfo, sizeof_EXCEPINFO, 00) != sizeof_EXCEPINFO)
		{
			;throw Exception("Out of memory.", -1)
			throw Exception(ITL_FormatException("Out of memory", "Memory allocation for EXCEPINFO failed.", ErrorLevel)*)
		}

		; get MEMBERID for called method:
		hr := DllCall(NumGet(NumGet(info+0), 10*A_PtrSize, "Ptr"), "Ptr", info, "Str*", method, "UInt", 1, "UInt*", dispid, "Int") ; ITypeInfo::GetIDsOfNames()
		if (ITL_FAILED(hr) || dispid == DISPID_UNKNOWN)
		{
			/*
			if (hr == DISP_E_UNKNOWNNAME)
			{
				if (IsFunc(fn := "Obj" . LTrim(method, "_"))) ; if member not found: check for internal method
				{
					return %fn%(this, params*)
				}
			}
			*/
			;throw Exception("GetIDsOfNames() for """ method """ failed.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("Failed to call a method."
											, "ITypeInfo::GetIDsOfNames() for """ method """ failed."
											, ErrorLevel, hr
											, dispid != DISPID_UNKNOWN, "Invalid DISPID: " dispid)*)
		}

		if (paramCount > 0)
		{
			if (VarSetCapacity(rgvarg, sizeof_VARIANT * paramCount, 00) != (sizeof_VARIANT * paramCount)) ; create VARIANT array
				throw Exception("Out of memory.", -1)

			hr := DllCall(NumGet(NumGet(info+0), 24*A_PtrSize, "Ptr"), "Ptr", info, "UInt", dispid, "UInt", INVOKEKIND_FUNC, "UInt*", index) ; ITypeInfo2::GetFuncIndexOfMemId(_this, dispid, invkind, [out] index)
			if (ITL_FAILED(hr) || index == -1)
			{
				;throw Exception("ITypeInfo2::GetFuncIndexOfMemId() failed.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to call a method."
												, "ITypeInfo2::GetFuncIndexOfMemId() for """ method """ failed."
												, ErrorLevel, hr
												, index == -1, "Invalid function index: " index)*)
			}

			hr := DllCall(NumGet(NumGet(info+0), 05*A_PtrSize, "Ptr"), "ptr", info, "UInt", index, "Ptr*", funcdesc) ; ITypeInfo::GetFuncDesc(_this, index, [out] funcdesc)
			if (ITL_FAILED(hr) || !funcdesc)
			{
				;throw Exception("ITypeInfo::GetFuncDesc() failed.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to call a method."
												, "ITypeInfo::GetFuncDesc() for """ method """ (index " index ") failed."
												, ErrorLevel, hr
												, !funcdesc, "Invalid FUNCDESC pointer: " funcdesc)*)
			}

			paramArray := NumGet(1*funcdesc, 04 + A_PtrSize, "Ptr") ; FUNCDESC::lprgelemdescParam
			if (!paramArray)
			{
				;throw Exception("Array of parameter descriptions could not be read.", -1)
				throw Exception(ITL_FormatException("Failed to call a method."
												, "The array of parameter descriptions (FUNCDESC::lprgelemdescParam) could not be read."
												, ErrorLevel, ""
												, !paramArray, "Invalid ELEMDESC[] pointer: " paramArray)*)
			}

			Loop % paramCount
			{
				vt := NumGet(1*paramArray, (A_Index - 1) * (4*A_PtrSize) + A_PtrSize, "UShort") ; ELEMDESC[A_Index - 1]::tdesc::vt

				ITL_VARIANT_Create(params[A_Index], variant) ; create VARIANT and put it in the array
				, ITL_Mem_Copy(&variant, &rgvarg + (paramCount - A_Index) * sizeof_VARIANT, sizeof_VARIANT)
			}
			NumPut(&rgvarg, dispparams, 00, "Ptr") ; DISPPARAMS::rgvarg - the pointer to the VARIANT array
			NumPut(paramCount, dispparams, 2 * A_PtrSize, "UInt") ; DISPPARAMS::cArgs - the number of arguments passed

			DllCall(NumGet(NumGet(info+0), 20*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", funcdesc) ; ITypeInfo::ReleaseFuncDesc(_this, funcdesc)
		}

		; invoke the function
		; currently, the excepinfo structure is not used; also, the last parameter (index of a bad argument if any) is not passed
		hr := DllCall(NumGet(NumGet(info+0), 11*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", instance, "UInt", dispid, "UShort", DISPATCH_METHOD, "Ptr", &dispparams, "Ptr", &result, "Ptr", &excepInfo, "Ptr", 0, "Int") ; ITypeInfo::Invoke()
		if (ITL_FAILED(hr))
		{
			/*
			if (hr == DISP_E_MEMBERNOTFOUND)
			{
				; If member not found: check for internal method
				; A 2nd check is needed here because a class / interface could have a property with the same name as an AHK object function.
				; In that case, GetIDsOfNames() would do well, but it would fail here.
				; In all other cases, i.e. where the class / interface does not have such a property, GetIDsOfNames would fail - thus a check is needed there, too.
				if (IsFunc(fn := "Obj" . LTrim(method, "_")))
				{
					return %fn%(this, params*)
				}
			}
			*/
			; use EXCEPINFO here!
			;throw Exception("""" method "()"" could not be called.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("Failed to call a method."
											, "ITypeInfo::Invoke() failed for """ method """."
											, ErrorLevel, hr)*)
		}
		return ITL_VARIANT_GetValue(&result) ; return the result of the call
	}

	; method: __Get
	; retrieves instance properties from an interface
	__Get(property)
	{
		; code inspired by AutoHotkey_L source (script_com.cpp)
		static DISPATCH_PROPERTYGET := 0x2, DISPATCH_METHOD := 0x1
		, DISPID_UNKNOWN := -1
		, sizeof_DISPPARAMS := 8 + 2 * A_PtrSize, sizeof_EXCEPINFO := 12 + 5 * A_PtrSize, sizeof_VARIANT := 8 + 2 * A_PtrSize
		local dispparams, hr, info, dispid := DISPID_UNKNOWN, instance, excepInfo, err_index, result

		if (property != "base" && !RegExMatch(property, "^internal://")) ; ignore base and internal properties (handled by ITL_WrapperBaseClass)
		{
			; init structures
			if (VarSetCapacity(dispparams, sizeof_DISPPARAMS, 00) != sizeof_DISPPARAMS)
			{
				;throw Exception("Out of memory.", -1)
				throw Exception(ITL_FormatException("Out of memory", "Memory allocation for DISPPARAMS failed.", ErrorLevel)*)
			}
			if (VarSetCapacity(result, sizeof_VARIANT, 00) != sizeof_VARIANT)
			{
				;throw Exception("Out of memory.", -1)
				throw Exception(ITL_FormatException("Out of memory", "Memory allocation for the result VARIANT failed.", ErrorLevel)*)
			}
			if (VarSetCapacity(excepInfo, sizeof_EXCEPINFO, 00) != sizeof_EXCEPINFO)
			{
				;throw Exception("Out of memory.", -1)
				throw Exception(ITL_FormatException("Out of memory", "Memory allocation for EXCEPINFO failed.", ErrorLevel)*)
			}

			info := this["internal://typeinfo-instance"]
			instance := this["internal://type-instance"]

			; get MEMBERID for the method to be retrieved:
			hr := DllCall(NumGet(NumGet(info+0), 10*A_PtrSize, "Ptr"), "Ptr", info, "Str*", property, "UInt", 1, "UInt*", dispid, "Int") ; ITypeInfo::GetIDsOfNames()
			if (ITL_FAILED(hr) || dispid == DISPID_UNKNOWN)
			{
				;throw Exception("GetIDsOfNames() for """ property """ failed.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to retrieve a property."
												, "ITypeInfo::GetIDsOfNames() for """ property """ failed."
												, ErrorLevel, hr
												, dispid == DISPID_UNKNOWN, "Invalid DISPID: " dispid)*)
			}

			; get the property:
			; as with __Call, excepinfo is not yet used
			hr := DllCall(NumGet(NumGet(info+0), 11*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", instance, "UInt", dispid, "UShort", DISPATCH_METHOD | DISPATCH_PROPERTYGET, "Ptr", &dispparams, "Ptr", &result, "Ptr", &excepInfo, "Ptr", 0, "Int") ; ITypeInfo::Invoke()
			if (ITL_FAILED(hr))
			{
				;throw Exception("""" property """ could not be retrieved.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to retrieve a property."
												, "ITypeInfo::Invoke() for """ property """ failed."
												, ErrorLevel, hr)*)
			}
			return ITL_VARIANT_GetValue(&result) ; return the result, i.e. the value of the property
		}
	}

	; method: __Set
	; sets an instance property
	__Set(property, value)
	{
		; code inspired by AutoHotkey_L source (script_com.cpp)
		static DISPATCH_PROPERTYPUTREF := 0x8, DISPATCH_PROPERTYPUT := 0x4
		, DISPID_UNKNOWN := -1, DISPID_PROPERTYPUT := -3
		, sizeof_DISPPARAMS := 8 + 2 * A_PtrSize, sizeof_EXCEPINFO := 12 + 5 * A_PtrSize
		, VT_UNKNOWN := 13, VT_DISPATCH := 9
		, DISP_E_MEMBERNOTFOUND := -2147352573
		local variant, dispparams, hr, info, dispid := DISPID_UNKNOWN, vt, instance, excepInfo, err_index := 0, variant

		if (property != "base" && !RegExMatch(property, "^internal://")) ; ignore base and internal properties (handled by ITL_WrapperBaseClass)
		{
			; init structures
			if (VarSetCapacity(dispparams, sizeof_DISPPARAMS, 00) != sizeof_DISPPARAMS)
			{
				;throw Exception("Out of memory.", -1)
				throw Exception(ITL_FormatException("Out of memory", "Memory allocation for DISPPARAMS failed.", ErrorLevel)*)
			}
			if (VarSetCapacity(excepInfo, sizeof_EXCEPINFO, 00) != sizeof_EXCEPINFO)
			{
				;throw Exception("Out of memory.", -1)
				throw Exception(ITL_FormatException("Out of memory", "Memory allocation for EXCEPINFO failed.", ErrorLevel)*)
			}

			; create a VARIANT from the new value
			ITL_VARIANT_Create(value, variant)
			NumPut(&variant, dispparams, 00, "Ptr") ; DISPPARAMS::rgvarg - the VARIANT "array", a single item here
			NumPut(1, dispparams, 2 * A_PtrSize, "UInt") ; DISPPARAMS::cArgs - the count of VARIANTs (1 in this case)

			NumPut(&DISPID_PROPERTYPUT, dispparams, A_PtrSize, "Ptr") ; DISPPARAMS::rgdispidNamedArgs - indicate a property is being set
			NumPut(1, dispparams, 2 * A_PtrSize + 4, "UInt") ; DISPPARAMS::cNamedArgs

			info := this["internal://typeinfo-instance"]
			instance := this["internal://type-instance"]

			; get MEMBERID for the property to be set:
			hr := DllCall(NumGet(NumGet(info+0), 10*A_PtrSize, "Ptr"), "Ptr", info, "Str*", property, "UInt", 1, "UInt*", dispid, "Int") ; ITypeInfo::GetIDsOfNames()
			if (ITL_FAILED(hr) || dispid == DISPID_UNKNOWN) ; an error code was returned or the ID is invalid
			{
				;throw Exception("GetIDsOfNames() for """ property """ failed.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to set a property."
												, "ITypeInfo::GetIDsOfNames() for """ property """ failed."
												, ErrorLevel, hr
												, dispid == DISPID_UNKNOWN, "Invalid DISPID: " dispid)*)
			}

			; get VARTYPE from the VARIANT structure
			vt := NumGet(variant, 00, "UShort")
			; for VT_UNKNOWN and VT_DISPATCH, invoke with DISPATCH_PROPERTYPUTREF first:
			if (vt == VT_DISPATCH || vt == VT_UNKNOWN)
			{
				; as with __Call, excepinfo is not yet used
				hr := DllCall(NumGet(NumGet(info+0), 11*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", instance, "UInt", dispid, "UShort", DISPATCH_PROPERTYPUTREF, "Ptr", &dispparams, "Ptr", 0, "Ptr", &excepInfo, "UInt*", err_index, "Int") ; ITypeInfo::Invoke()
				if (ITL_SUCCEEDED(hr))
				{
					return value ; return the original value to allow "a := obj.prop := value" and similar
				}
				else if (hr != DISP_E_MEMBERNOTFOUND) ; if member not found, retry below with DISPATCH_PROPERTYPUT
				{
					;throw Exception("""" property """ could not be set.", -1, ITL_FormatError(hr)) ; otherwise an error occured
					throw Exception(ITL_FormatException("Failed to set a property."
													, "ITypeInfo::Invoke() for """ property """ failed."
													, ErrorLevel, hr)*)
				}
			}

			; set the property:
			; as with __Call, excepinfo is not yet used
			hr := DllCall(NumGet(NumGet(info+0), 11*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", instance, "UInt", dispid, "UShort", DISPATCH_PROPERTYPUT, "Ptr", &dispparams, "Ptr*", 0, "Ptr", &excepInfo, "UInt*", err_index, "Int") ; ITypeInfo::Invoke()
			if (ITL_FAILED(hr))
			{
				;throw Exception("""" property """ could not be set.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to set a property."
												, "ITypeInfo::Invoke() for """ property """ failed."
												, ErrorLevel, hr)*)
			}
			return value ; return the original value to allow "a := obj.prop := value" and similar
		}
	}
}
class ITL_EnumWrapper extends ITL_Wrapper.ITL_ConstantMemberWrapperBaseClass
{
	__New(typeInfo, lib)
	{
		local Base

		if (this != ITL_Wrapper.ITL_EnumWrapper)
		{
			Base.__New(typeInfo, lib)
			ObjInsert(this, "__New", Func("ITL_AbstractClassConstructor"))
		}
	}
}
class ITL_StructureWrapper extends ITL_Wrapper.ITL_WrapperBaseClass
{
	__New(typeInfo, lib)
	{
		static GUID_NULL := "{00000000-0000-0000-0000-000000000000}", IID_ICreateTypeInfo := "{00020405-0000-0000-C000-000000000046}"
		local Base, hr := 0x00, rcinfo := 0, guid:= 0

		if (this != ITL_Wrapper.ITL_StructureWrapper)
		{
			Base.__New(typeInfo, lib)

			; If there's no GUID specified, this would cause GetRecordInfoFromTypeInfo() to fail
			; So we're trying to add a random-generated GUID just to keep it satisfied.
			if (lib.GetGUID(typeInfo, false, true) == GUID_NULL)
			{
				createInfo := ComObjQuery(typeInfo, IID_ICreateTypeInfo) ; query for the ICreateTypeInfo interface which can be used to modify the type
				if (!createInfo)
				{
					;throw Exception("QueryInterface() for ICreateTypeInfo failed.", -1, "This is needed because the type """ this["internal://typeinfo-name"] """ does not have a GUID.")
					throw Exception(ITL_FormatException("Failed to create a wrapper for """ this["internal://typeinfo-name"] """."
													, "QueryInterface() for ICreateTypeInfo failed."
													, ErrorLevel, ""
													, !createInfo, "Invalid ICreateTypeInfo pointer returned by ComObjQuery() : " createInfo)*)
				}

				hr := ITL_GUID_Create(guid) ; dynamically create a new GUID
				if (ITL_FAILED(hr))
				{
					;throw Exception("Creating a GUID failed.", -1, ITL_FormatError(hr))
					throw Exception(ITL_FormatException("Failed to create a wrapper for """ this["internal://typeinfo-name"] """."
													, "Creation of a GUID failed."
													, ErrorLevel, hr)*)
				}

				hr := DllCall(NumGet(NumGet(createInfo+0), 03*A_PtrSize, "Ptr"), "Ptr", createInfo, "Ptr", &guid, "Int") ; ICreateTypeInfo::SetGuid() - assign a GUID for the type
				if (ITL_FAILED(hr))
				{
					;throw Exception("ICreateTypeInfo::SetGUID() failed.", -1, ITL_FormatError(hr))
					throw Exception(ITL_FormatException("Failed to create a wrapper for """ this["internal://typeinfo-name"] """."
													, "ICreateTypeInfo::SetGuid() failed."
													, ErrorLevel, hr)*)
				}
			}

			hr := DllCall("OleAut32\GetRecordInfoFromTypeInfo", "Ptr", typeInfo, "Ptr*", rcinfo, "Int") ; retrieve an IRecordInfo instance for a type
			if (ITL_FAILED(hr) || !rcinfo)
			{
				;throw Exception("GetRecordInfoFromTypeInfo() failed for type """ this["internal://typeinfo-name"] """.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to create a wrapper for """ this["internal://typeinfo-name"] """."
												, "GetRecordInfoFromTypeInfo() failed."
												, ErrorLevel, hr
												, !rcinfo, "Invalid IRecordInfo pointer: " rcinfo)*)
			}
			this["internal://rcinfo-instance"] := rcinfo

			ObjInsert(this, "__New", Func("ITL_StructureConstructor"))
		}
	}

	__Delete()
	{
		local hr, ptr, rcinfo
		if (ptr := this["internal://type-instance"])
		{
			rcinfo := this.base["internal://rcinfo-instance"]
			hr := DllCall(NumGet(NumGet(rcinfo+0), 18*A_PtrSize, "Ptr"), "Ptr", rcinfo, "Ptr", ptr, "Int") ; IRecordInfo::RecordDestroy()
			if (ITL_FAILED(hr))
			{
				;throw Exception("RecordDestroy() failed.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to release structure of type """ this.base["internal://typeinfo-name"] """."
												, "IRecordInfo::RecordDestroy() failed."
												, ErrorLevel, hr)*)
			}
		}
		else
		{
			rcinfo := this["internal://rcinfo-instance"]
			ObjRelease(rcinfo)
		}
	}

	__Get(field)
	{
		static sizeof_VARIANT := 8 + 2 * A_PtrSize
		local hr, ptr, variant := 0, rcinfo

		if (field != "base" && !RegExMatch(field, "^internal://")) ; ignore base and internal properties (handled by ITL_WrapperBaseClass)
		{
			ptr := this["internal://type-instance"]
			rcinfo := this.base["internal://rcinfo-instance"]

			if (VarSetCapacity(variant, sizeof_VARIANT, 00) != sizeof_VARIANT)
			{
				;throw Exception("Out of memory.", -1)
				throw Exception(ITL_FormatException("Out of memory.", "Memory allocation for VARIANT failed.", ErrorLevel)*)
			}

			hr := DllCall(NumGet(NumGet(rcinfo+0), 10*A_PtrSize, "Ptr"), "Ptr", rcinfo, "Ptr", ptr, "Str", field, "Ptr", &variant, "Int") ; IRecordInfo::GetField()
			if (ITL_FAILED(hr))
			{
				;throw Exception("GetField() failed.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to retrieve a structure field."
												, "IRecordInfo::GetField() failed for field """ field """ on type """ this.base["internal://typeinfo-name"] """."
												, ErrorLevel, hr)*)
			}

			return ITL_VARIANT_GetValue(&variant)
		}
	}

	__Set(field, value)
	{
		static INVOKE_PROPERTYPUT := 4
		local hr, ptr, variant := 0, rcinfo

		if (field != "base" && !RegExMatch(field, "^internal://")) ; ignore base and internal properties (handled by ITL_WrapperBaseClass)
		{
			ptr := this["internal://type-instance"]
			, rcinfo := this.base["internal://rcinfo-instance"]

			ITL_VARIANT_Create(value, variant)
			hr := DllCall(NumGet(NumGet(rcinfo+0), 12*A_PtrSize, "Ptr"), "Ptr", rcinfo, "UInt", INVOKE_PROPERTYPUT, "Ptr", ptr, "Str", field, "Ptr", &variant, "Int") ; IRecordInfo::PutField()
			if (ITL_FAILED(hr))
			{
				;throw Exception("PutField() failed.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("Failed to set a structure field."
												, "IRecordInfo::PutField() failed for field """ field """ on type """ this.base["internal://typeinfo-name"] """."
												, ErrorLevel, hr)*)
			}

			return value
		}
	}

	_NewEnum()
	{
		local hr, info, rcinfo, attr := 0, obj, names_array, varCount := -1, name := ""

		obj := this["internal://enumerator-object"] := {} ; create a storage object
		rcinfo := this.base["internal://rcinfo-instance"]

		; call GetFieldNames() with a NULL array pointer -> retrieve the total field count through "varCount"
		hr := DllCall(NumGet(NumGet(rcinfo+0), 14 * A_PtrSize, "Ptr"), "Ptr", rcinfo, "UInt*", varCount, "Ptr", 0, "Int") ; IRecordInfo::GetFieldNames()
		if (ITL_FAILED(hr) || varCount == -1)
		{
			;throw Exception("IRecordInfo::GetFieldNames() failed.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("Failed to enumerate structure members of type """ this.base["internal://typeinfo-name"] """."
											, "IRecordInfo::GetFieldNames() failed."
											, ErrorLevel, hr
											, varCount != -1, "Invalid member count: " varCount)*)
		}

		VarSetCapacity(names_array, varCount * A_PtrSize, 00) ; allocate name array memory
		; call it again, this time supplying a valid array pointer
		hr := DllCall(NumGet(NumGet(rcinfo+0), 14 * A_PtrSize, "Ptr"), "Ptr", rcinfo, "UInt*", varCount, "Ptr", &names_array, "Int") ; IRecordInfo::GetFieldNames()
		if (ITL_FAILED(hr))
		{
			;throw Exception("IRecordInfo::GetFieldNames() failed.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("Failed to enumerate structure members of type """ this.base["internal://typeinfo-name"] """."
											, "IRecordInfo::GetFieldNames() failed."
											, ErrorLevel, hr)*)
		}

		Loop %varCount%
		{
			name := StrGet(NumGet(names_array, (A_Index - 1) * A_PtrSize, "Ptr"))
			obj.Insert(name, this[name])
		}

		return ObjNewEnum(obj)
	}

	NewEnum()
	{
		return this._NewEnum()
	}

	_Clone()
	{
		local hr, rcinfo := this.base["internal://rcinfo-instance"], ptrNew := 0, ptrOld := this["internal://type-instance"], newObj

		newObj := new this.base()
		ptrNew := newObj["internal://type-instance"]

		hr := DllCall(NumGet(NumGet(rcinfo+0), 05*A_PtrSize, "Ptr"), "Ptr", rcinfo, "Ptr", ptrOld, "Ptr", ptrNew, "Int") ; IRecordInfo::RecordCopy()
		if (ITL_FAILED(hr))
		{
			;throw Exception("IRecordInfo::RecordCopy() failed.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("Failed to clone a structure instance."
											, "IRecordInfo::RecordCopy() failed."
											, ErrorLevel, hr)*)
		}

		return newObj
	}

	Clone()
	{
		return this._Clone()
	}

	GetSize()
	{
		local hr, size := -1, rcinfo := this["internal://rcinfo-instance"]

		hr := DllCall(Numget(NumGet(rcinfo+0), 08*A_PtrSize, "Ptr"), "Ptr", rcinfo, "UInt*", size, "Int") ; IRecordInfo::GetSize()
		if (ITL_FAILED(hr) || size == -1)
		{
			;throw Exception("GetSize() failed.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("Failed to retrieve structure size for """ this["internal://typeinfo-name"] """."
											, "IRecordInfo::GetSize() failed."
											, ErrorLevel, hr)*)
		}

		return size
	}

	Clear()
	{
		local hr, rcinfo := this["internal://rcinfo-instance"], ptr := this["internal://type-instance"]
		hr := DllCall(NumGet(NumGet(rcinfo+0), 04*A_PtrSize, "Ptr"), "Ptr", rcinfo, "Ptr", ptr, "Int") ; IRecordInfo::RecordClear()
		if (ITL_Failed(hr))
		{
			throw Exception(ITL_FormatException("Failed to clear a structure instance."
											, "IRecordInfo::RecordClear() failed."
											, ErrorLevel, hr)*)
		}
		hr := DllCall(NumGet(NumGet(rcinfo+0), 03*A_PtrSize, "Ptr"), "Ptr", rcinfo, "Ptr", ptr, "Int") ; IRecordInfo::RecordInit()
		if (ITL_Failed(hr))
		{
			throw Exception(ITL_FormatException("Failed to clear a structure instance."
											, "RecordInit::RecordClear() failed."
											, ErrorLevel, hr)*)
		}
	}
}
class ITL_ModuleWrapper extends ITL_Wrapper.ITL_ConstantMemberWrapperBaseClass
{
	__New(typeInfo, lib)
	{
		local Base

		if (this != ITL_Wrapper.ITL_ModuleWrapper)
		{
			Base.__New(typeInfo, lib)
			ObjInsert(this, "__New", Func("ITL_AbstractClassConstructor"))
		}
	}

	__Call(method, params*)
	{
		static DISPID_UNKNOWN := -1
		local id := DISPID_UNKNOWN, hr := 0, addr := 0, info

		info := this["internal://typeinfo-instance"]

		hr := DllCall(NumGet(NumGet(info+0), 10*A_PtrSize, "Ptr"), "Ptr", info, "Str*", method, "UInt", 1, "Ptr*", id, "Int")
		if (ITL_FAILED(hr) || id == DISPID_UNKNOWN)
		{
			;throw Exception("GetIDsOfNames() for """ method "()"" failed.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("Failed to call method """ method """ on module """ this.base["internal://typeinfo-name"] """."
											, "ITypeInfo::GetIDsOfNames() failed."
											, ErrorLevel, hr
											, id == DISPID_UNKNOWN, "Invalid DISPID: " id)*)
		}

		hr := DllCall(NumGet(NumGet(info+0), 15*A_PtrSize, "Ptr"), "Ptr", info, "UInt", id, "UInt", 0, "Ptr*", addr, "Int")
		if (ITL_FAILED(hr) || !addr)
		{
			;throw Exception("AddressOfMember() for """ method "()"" failed.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("Failed to call method """ method """ on module """ this.base["internal://typeinfo-name"] """."
											, "ITypeInfo::AddressOfMember() failed."
											, ErrorLevel, hr
											, !addr, "Invalid member address: " addr)*)
		}

		; call!
		; result := DllCall(addr, params*)
		; get return type

		return ; result
	}
}
class ITL_TypeLibWrapper
{
	__New(lib)
	{
		static valid_typekinds := "", VT_USERDEFINED := 29, MEMBERID_NIL := -1
			, TYPEKIND_ENUM := 0, TYPEKIND_RECORD := 1, TYPEKIND_MODULE := 2, TYPEKIND_INTERFACE := 3, TYPEKIND_COCLASS := 5, TYPEKIND_ALIAS := 6
		local typeKind := -1, hr, typeName, obj, typeInfo := 0, attr := 0, vt, mappings := [], refInfo := 0, hrefType, refAttr := 0, refKind

		if (!IsObject(valid_typekinds)) ; init static field
		{
			 valid_typekinds := { (TYPEKIND_ENUM)		: ITL_Wrapper.ITL_EnumWrapper
								, (TYPEKIND_RECORD)		: ITL_Wrapper.ITL_StructureWrapper
								, (TYPEKIND_MODULE)		: ITL_Wrapper.ITL_ModuleWrapper
								, (TYPEKIND_INTERFACE)	: ITL_Wrapper.ITL_InterfaceWrapper
								, (TYPEKIND_COCLASS)	: ITL_Wrapper.ITL_CoClassWrapper }
		 }

		if (this != ITL_Wrapper.ITL_TypeLibWrapper)
		{
			ObjInsert(this, "__New", Func("ITL_AbstractClassConstructor"))
			this["internal://typelib-instance"] := lib
			this["internal://typelib-name"] := this.GetName()

			Loop % DllCall(NumGet(NumGet(lib+0), 03*A_PtrSize, "Ptr"), "Ptr", lib, "Int") ; ITypeLib::GetTypeInfoCount()
			{
				hr := DllCall(NumGet(NumGet(lib+0), 05*A_PtrSize, "Ptr"), "Ptr", lib, "UInt", A_Index - 1, "UInt*", typeKind, "Int") ; ITypeLib::GetTypeKind()
				if (ITL_FAILED(hr) || typeKind == -1)
				{
					;throw Exception("Type information kind no. " A_Index - 1 " could not be read.", -1, ITL_FormatError(hr))
					throw Exception(ITL_FormatException("Failed to wrap type library """ this["internal://typelib-name"] """."
													, "Type information kind no. " A_Index - 1 " could not be read."
													, ErrorLevel, hr
													, typeKind == -1, "Invalid TYPEKIND: " typeKind)*)
				}

				if (!valid_typekinds.HasKey(typeKind) && typeKind != TYPEKIND_ALIAS)
				{
					ObjRelease(typeInfo), typeKind := -1, typeName := "", typeInfo := 0
					continue
				}

				hr := DllCall(NumGet(NumGet(lib+0), 04*A_PtrSize, "Ptr"), "Ptr", lib, "UInt", A_Index - 1, "Ptr*", typeInfo, "Int") ; ITypeLib::GetTypeInfo()
				if (ITL_FAILED(hr) || !typeInfo)
				{
					;throw Exception("Type information no. " A_Index - 1 " could not be read.", -1, ITL_FormatError(hr))
					throw Exception(ITL_FormatException("Failed to wrap type library """ this["internal://typelib-name"] """."
													, "Type information no. " A_Index - 1 " could not be read."
													, ErrorLevel, hr
													, !typeInfo, "Invalid ITypeInfo pointer: " typeInfo)*)
				}

				typeName := this.GetName(A_Index - 1)
				if (typeKind == TYPEKIND_ALIAS)
				{
					MsgBox %typeName% is an alias...
					hr := DllCall(NumGet(NumGet(typeInfo+0), 03*A_PtrSize, "Ptr"), "Ptr", typeInfo, "Ptr*", attr, "Int") ; ITypeInfo::GetTypeAttr()
					if (ITL_FAILED(hr) || !attr)
					{
						;throw Exception("ITypeInfo::GetTypeAttr() failed.", -1, ITL_FormatError(hr))
						throw Exception(ITL_FormatException("Failed to wrap type library """ this["internal://typelib-name"] """."
														, "ITypeInfo::GetTypeAttr() for type """ typeName """ failed."
														, ErrorLevel, hr
														, !attr, "Invalid TYPEATTR pointer: " attr)*)
					}

					vt := NumGet(1*attr, 56 + 2*A_PtrSize, "UShort") ; TYPEATTR::tdescAlias::vt
					if (vt == VT_USERDEFINED)
					{
						hrefType := NumGet(1*attr, 56 + A_PtrSize, "UInt")
						hr := DllCall(NumGet(NumGet(typeInfo+0), 14*A_PtrSize, "Ptr"), "Ptr", typeInfo, "UInt", hrefType, "Ptr*", refInfo) ; ITypeInfo::GetRefTypeInfo()
						if (ITL_FAILED(hr) || !refInfo)
						{
							;throw Exception("ITypeInfo::GetRefTypeInfo() failed.", -1, ITL_FormatError(hr))
							throw Exception(ITL_FormatException("Failed to wrap type library """ this["internal://typelib-name"] """."
															, "ITypeInfo::GetRefTypeInfo() for type """ typeName """ failed."
															, ErrorLevel, hr
															, !refInfo, "Invalid ITypeInfo pointer: " refInfo)*)
						}

						hr := DllCall(NumGet(NumGet(refInfo+0), 03*A_PtrSize, "Ptr"), "Ptr", refInfo, "Ptr*", refAttr, "Int") ; ITypeInfo::GetTypeAttr()
						if (ITL_FAILED(hr) || !refAttr)
						{
							;throw Exception("ITypeInfo::GetTypeAttr() failed.", -1, ITL_FormatError(hr))
							throw Exception(ITL_FormatException("Failed to wrap type library """ this["internal://typelib-name"] """."
															, "ITypeInfo::GetTypeAttr() for type """ typeName """ failed."
															, ErrorLevel, hr
															, !refAttr, "Invalid TYPEATTR pointer: " refAttr)*)
						}

						refKind := NumGet(1*attr, 36+A_PtrSize, "UInt") ; TYPEATTR::typekind
						if (valid_typekinds.HasKey(refKind))
						{
							mappings.Insert(typeName, refInfo)
						}

						DllCall(NumGet(NumGet(refInfo+0), 19*A_PtrSize, "Ptr"), "Ptr", refInfo, "Ptr", refAttr) ; ITypeInfo::ReleaseTypeAttr()
						, ObjRelease(refInfo)
						, refInfo := 0, refAttr := 0
					}

					DllCall(NumGet(NumGet(typeInfo+0), 19*A_PtrSize, "Ptr"), "Ptr", typeInfo, "Ptr", attr) ; ITypeInfo::ReleaseTypeAttr()
					, ObjRelease(typeInfo)
					, attr := 0
				}
				else
				{
					obj := valid_typekinds[typeKind], this[typeName] := new obj(typeInfo, this)
				}
				typeName := "", typeInfo := 0, typeKind := -1
			}

			for alias, typeInfo in mappings
			{
				hr := DllCall(NumGet(NumGet(typeInfo+0), 12*A_PtrSize, "Ptr"), "Ptr", typeInfo, "Int", MEMBERID_NIL, "Ptr*", typeName, "Int")
				if (ITL_FAILED(hr) || !typeName)
				{
					;throw Exception("ITypeInfo::GetDocumentation() failed.", -1, ITL_FormatError(hr))
					throw Exception(ITL_FormatException("Failed to wrap type library """ this["internal://typelib-name"] """."
													, "ITypeInfo::GetDocumentation() for an alias failed."
													, ErrorLevel, hr
													, !typeName, "Invalid type name pointer: " typeName)*)
				}
				this[alias] := this[StrGet(typeName)]
				ObjRelease(typeInfo)
			}
		}
	}

	GetName(index = -1)
	{
		local hr, name := 0, lib

		lib := this["internal://typelib-instance"]
		hr := DllCall(NumGet(NumGet(lib+0), 09*A_PtrSize, "Ptr"), "Ptr", lib, "UInt", index, "Ptr*", name, "Ptr*", 0, "UInt*", 0, "Ptr*", 0, "Int") ; ITypeLib::GetDocumentation()
		if (ITL_FAILED(hr) || !name)
		{
			;throw Exception("Name for the " (index == -1 ? "type library" : "type description no. " index) " could not be read.", -1, ITL_FormatError(hr))
			throw Exception(ITL_FormatException("The name for the " (index == -1 ? "type library" : "type description no. " index) " could not be read."
											, "ITypeLib::GetDocumentation() failed."
											, ErrorLevel, hr
											, !name, "Invalid name pointer: " name)*)
		}

		return StrGet(name, "UTF-16")
	}

	GetGUID(obj = -1, returnRaw = false, passRaw = false)
	{
		local hr, guid, lib, info, attr := 0, result

		lib := this["internal://typelib-instance"]
		if obj is not integer
		{
			if (!IsObject(obj)) ; it's a string, a field name
				obj := this[obj]

			if (IsObject(obj)) ; a field, either passed directly or via name
				info := obj["internal://typeinfo-instance"]
			else
			{
				;throw Exception("Field could not be retrieved.", -1)
				throw Exception(ITL_FormatException("A type GUID could not be read."
												, "The type wrapper object could not be retrieved."
												, ErrorLevel, ""
												, !IsObject(obj), "Not an object: """ obj """.")*)
			}
		}
		else if (obj != -1)
		{
			if (passRaw)
				info := obj ; also allow passing an ITypeInfo pointer directly
			else
			{
				hr := DllCall(NumGet(NumGet(lib+0), 04*A_PtrSize, "Ptr"), "Ptr", lib, "UInt", obj, "Ptr*", info, "Int") ; ITypeLib::GetTypeInfo()
				if (ITL_FAILED(hr) || !info)
				{
					;throw Exception("Type information could not be read.", -1, ITL_FormatError(hr))
					throw Exception(ITL_FormatException("A type GUID could not be read."
													, "ITypeLib::GetTypeInfo() failed on index " obj "."
													, ErrorLevel, hr
													, !info, "Invalid ITypeInfo pointer: " info)*)
				}
			}
		}

		if (obj == -1)
		{
			hr := DllCall(NumGet(NumGet(lib+0), 07*A_PtrSize, "Ptr"), "Ptr", lib, "Ptr*", attr, "Int") ; ITypeLib::GetLibAttr()
			if (ITL_FAILED(hr) || !attr)
			{
				;throw Exception("TLIBATTR could not be read.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("The type library GUID could not be read."
													, "ITypeLib::GetLibAttr() failed."
													, ErrorLevel, hr
													, !attr, "Invalid TLIBATTR pointer: " attr)*)
			}

			guid := ITL_Mem_Allocate(16), ITL_Mem_Copy(attr, guid, 16) ; TLIBATTR::guid
			if (returnRaw)
				result := guid
			else
				result := ITL_GUID_ToString(guid), ITL_Mem_Release(guid)

			DllCall(NumGet(NumGet(lib+0), 12*A_PtrSize, "Ptr"), "Ptr", lib, "Ptr", attr) ; ITypeLib::ReleaseTLibAttr()
		}
		else
		{
			hr := DllCall(NumGet(NumGet(info+0), 03*A_PtrSize, "Ptr"), "Ptr", info, "Ptr*", attr, "Int") ; ITypeInfo::GetTypeAttr()
			if (ITL_FAILED(hr) || !attr)
			{
				;throw Exception("TYPEATTR could not be read.", -1, ITL_FormatError(hr))
				throw Exception(ITL_FormatException("A type GUID could not be read."
												, "ITypeInfo::GetTypeAttr() failed."
												, ErrorLevel, hr
												, !attr, "Invalid TYPEATTR pointer: " attr)*)
			}

			guid := ITL_Mem_Allocate(16), ITL_Mem_Copy(attr, guid, 16) ; TYPEATTR::guid
			if (returnRaw)
				result := guid
			else
				result := ITL_GUID_ToString(guid), ITL_Mem_Release(guid)

			DllCall(NumGet(NumGet(info+0), 19*A_PtrSize, "Ptr"), "Ptr", info, "Ptr", attr, "Int") ; ITypeInfo::ReleaseTypeAttr()
		}

		return result
	}
}
}