TI_GetVersion(string, byRef ver_major, byRef ver_minor)
{
	return RegExMatch(string, "^(?P<major>\d+)\.(?P<minor>\d+)$", ver_)
}