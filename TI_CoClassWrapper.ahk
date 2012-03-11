class TI_CoClassWrapper extends TI_Wrapper.TI_ExecutableWrapperBaseClass
{
	__New(typeInfo)
	{
		Base.__New(typeInfo)
		if (this != TI_Wrapper.TI_CoClassWrapper)
			ObjInsert(this, "__New", Func("TI_CoClassConstructor"))
	}
}