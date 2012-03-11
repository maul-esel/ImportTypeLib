class TI_StructureWrapper extends TI_Wrapper.TI_WrapperBaseClass
{
	__New(typeInfo)
	{
		if (this != TI_Wrapper.TI_StructureWrapper)
		{
			Base.__New(typeInfo)
			ObjInsert(this, "__New", Func("TI_StructureConstructor"))
		}
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