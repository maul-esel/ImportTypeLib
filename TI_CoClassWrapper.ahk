class TI_CoClassWrapper extends TI_Wrapper.TI_ExecutableWrapperBaseClass
{
	__New(typeInfo, lib)
	{
		if (this != TI_Wrapper.TI_CoClassWrapper)
		{
			Base.__New(typeInfo, lib)
			ObjInsert(this, "__New", Func("TI_CoClassConstructor"))
			this["internal://class-clsid"] := lib.GetGUID(typeInfo, false, true)
			; TODO: get default interface
		}
	}
}