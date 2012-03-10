class TI_AbstractClass
{
	static __New := Func("TI_AbstractClassConstructor")
}

TI_AbstractClassConstructor(_this, p*)
{
	throw Exception("An instance of the class """ _this.__class """ must not be created.", -1)
}