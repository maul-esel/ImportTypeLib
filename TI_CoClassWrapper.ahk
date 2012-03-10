class TI_CoClassWrapper extends TI_Wrapper.TI_WrapperBaseClass
{
	__New(typeInfo)
	{
		this.base.__New(typeInfo)
		if (this != TI_Wrapper.TI_CoClassWrapper)
			this.Insert("__New", Func("TI_CoClassConstructor"))
	}
}