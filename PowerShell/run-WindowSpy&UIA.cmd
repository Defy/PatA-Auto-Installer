@ECHO OFF
set "ahkExe=%CD:~0,3%AutoHotkey_2.0.19\AutoHotkey64.exe"
start "" "%ahkExe%" %CD:~0,3%AutoHotkey_2.0.19\Script\Lib\UIA.ahk
start "" "%ahkExe%" %CD:~0,3%AutoHotkey_2.0.19\UX\WindowSpy.ahk