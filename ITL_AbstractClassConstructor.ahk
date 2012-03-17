; Function: ITL_AbstractClassConstructor
; This is simply a wrapper for "abstract classes", i.e. an exception is thrown when it is called.
; "Abstract" classes set this as their constructor.
ITL_AbstractClassConstructor(this, p*)
{
	throw Exception("An instance of the class """ this.__class """ must not be created.", -1)
}