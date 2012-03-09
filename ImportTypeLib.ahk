ImportTypeLib(lib, version = "1.0")
{
	if (TI_IsGUID(lib))
	{
		if (!TI_GetVersion(version, verMajor, verMinor))
		{
			throw Exception("Invalid version specified: """ version """.", -1)
		}
		if (!(hr := TI_ConvertGUID(lib, libid)))
		{
			throw Exception("LIBID could not be converted: """ libid """.", -1, TI_FormatError(hr))
		}

		hr := DllCall("OleAut32\LoadRegTypeLib", "Ptr", &libid, "UShort", verMajor, "UShort", verMinor, "Ptr*", lib, "Int")

		VarSetCapacity(libid, 0)
	}
	else
	{
		hr := DllCall("OleAut32\LoadTypeLib", "Str", lib, "Ptr*", lib, "Int")
	}

	if (FAILED(hr))
	{
		throw Exception("Loading of type library failed.", -1, TI_FormatError(hr))
	}
	return new TI_Wrapper.TI_TypeLibWrapper(lib)
}

#include TI_AbstractClass.ahk
#include TI_Wrapper.ahk