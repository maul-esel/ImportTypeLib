class TI_StructureWrapper extends TI_Wrapper.TI_WrapperBaseClass
{
	__New(typeInfo)
	{
		this.base.__New(typeInfo)
		this["__New"] := Func("TI_StructureClassConstructor")
	}
}

TI_StructureClassConstructor(_this, p*)
{
	
}