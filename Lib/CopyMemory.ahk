CopyMemory(src, dest, size)
{
	DllCall("RtlMoveMemory", "Ptr", dest, "Ptr", src, "UInt", size)
}