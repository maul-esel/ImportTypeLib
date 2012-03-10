class TI_StructureWrapper extends TI_Wrapper.TI_WrapperBaseClass
{
	__New(typeInfo)
	{
		this.base.__New(typeInfo)
		if (this != TI_Wrapper.TI_StructureWrapper)
			this.Insert("__New", Func("TI_StructureConstructor"))
	}

	__Get(field)
	{
		; ...
	}

	__Set(field, value)
	{
		; ...
	}
}