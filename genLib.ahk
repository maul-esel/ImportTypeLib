#NoEnv
#SingleInstance ignore
#KeyHistory 0
ListLines Off
SetBatchLines -1

FileDelete ITL.ahk
FileAppend, % ProcessFile(A_ScriptDir "\ImportTypeLib.ahk"), ITL.ahk
MsgBox finished
ExitApp

ProcessFile(path)
{
	FileRead content, %path%

	pos := 1
	While (pos := RegExMatch(content, "im)^\s*#include\s+(i\*\s+)?(?P<file>.*)$", match_, pos))
	{
		StringReplace content, content, %match_%, % ProcessFile(match_file), All
		pos += StrLen(match_)
	}

	return content
}