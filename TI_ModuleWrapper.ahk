class TI_ModuleWrapper extends TI_Wrapper.TI_ConstantMemberWrapperBaseClass
{
	__New(typeInfo, lib)
	{
		local Base

		if (this != TI_Wrapper.TI_ModuleWrapper)
		{
			Base.__New(typeInfo, lib)
			ObjInsert(this, "__New", Func("TI_AbstractClassConstructor"))
		}
	}

	__Call(method, params*)
	{
	}
}