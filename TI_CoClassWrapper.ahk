class TI_CoClassWrapper extends TI_Wrapper.TI_WrapperBaseClass
{
	__New(typeInfo)
	{
		this.base.__New(typeInfo)
		this["__New"] := Func("TI_CoClassConstructor")
	}
}

TI_CoClassConstructor(_this, iid = 0)
{
}