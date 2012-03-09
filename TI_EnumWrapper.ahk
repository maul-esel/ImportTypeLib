class TI_EnumWrapper extends TI_Wrapper.TI_WrapperBaseClass
{
	__New(typeInfo)
	{
		this.base.__New(typeInfo)
		this["__New"] := Func("TI_AbstractClassConstructor")
	}
}