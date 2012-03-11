#NoEnv
#SingleInstance off
#Warn
#KeyHistory 0
SetBatchLines -1
ListLines Off
#include ImportTypeLib.ahk

UIAutomationCore := ImportTypeLib(A_WinDir "\System32\UIAutomationCore.dll\1")

MsgBox % "Enum value: " UIAutomationCore.OrientationType.Horizontal
;MsgBox % IsObject(UIAutomationCore)
auto := new UIAutomationCore.CUIAutomation()
;MsgBox % IsObject(auto) " - " auto["internal://default-iid"]
MsgBox % auto.RemoveAllEventHandlers()