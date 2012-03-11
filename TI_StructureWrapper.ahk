class TI_StructureWrapper extends TI_Wrapper.TI_WrapperBaseClass
{
	__New(typeInfo)
	{
		Base.__New(typeInfo)
		if (this != TI_Wrapper.TI_StructureWrapper)
			ObjInsert(this, "__New", Func("TI_StructureConstructor"))
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