ITL_InterfaceConstructor(this, instance)
{
	local interfacePtr
	if (!instance)
	{
		throw Exception("An instance of abstract type " this.__class " must not be created without supplying a valid instance pointer.", -1)
	}
	interfacePtr := ComObjQuery(instance, this["internal://interface-iid"])
	if (!interfacePtr)
		throw Exception("This interface is not supported by the given class instance.", -1)
	this["internal://type-instance"] := interfacePtr
}