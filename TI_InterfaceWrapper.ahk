class TI_InterfaceWrapper extends TI_Wrapper.TI_ExecutableWrapperBaseClass
{
	__New(typeInfo)
	{
		this.base.__New(typeInfo)
		if (this != TI_Wrapper.TI_InterfaceWrapper)
			this.Insert("__New", Func("TI_InterfaceConstructor"))
	}
}