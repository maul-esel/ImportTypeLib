class TI_EnumWrapper extends TI_Wrapper.TI_WrapperBaseClass
{
	__New(typeInfo)
	{
		this.base.__New(typeInfo)
		if (this != TI_Wrapper.TI_EnumWrapper)
			this.Insert("__New", Func("TI_AbstractClassConstructor"))
	}

	__Get(field)
	{
		; ...
	}
}