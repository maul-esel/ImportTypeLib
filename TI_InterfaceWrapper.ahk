class TI_InterfaceWrapper extends TI_Wrapper.TI_ExecutableWrapperBaseClass
{
	__New(typeInfo)
	{
		Base.__New(typeInfo)
		if (this != TI_Wrapper.TI_InterfaceWrapper)
			ObjInsert(this, "__New", Func("TI_InterfaceConstructor"))
	}
}