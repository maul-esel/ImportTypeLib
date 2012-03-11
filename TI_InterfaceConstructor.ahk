TI_InterfaceConstructor(this, instance)
{
	if (!instance)
	{
		throw Exception("An instance of abstract type " this.__class " must not be created without supplying a valid instance pointer.", -1)
	}
	; todo: QueryInterface
	this["internal://type-instance"] := instance
}