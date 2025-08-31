#Requires AutoHotkey v2.0
#Include .\Lib\UIA.ahk

EnableLocationServices()

EnableLocationServices() {
    if (WinWait("Settings", , 10)) {
        WinActivate
        window := UIA.ElementFromHandle("Settings ahk_exe ApplicationFrameHost.exe")
        getTitle := window.WaitElement({ Type: "Button", Name: "Location", MatchMode: "StartsWith" }, 5000)
        buttons := getTitle.WalkTree("p2, +1").FindElements([{ Type: "Button", Name: "Location services" }, { Type: "Button", Name: "Let apps access your location" }])
        for (button in buttons) {
            button.ToggleState := 1
        }
        WinMinimize("Settings")
        ExitApp
        return
    }
    DisplayErrorMessage()
}

DisplayErrorMessage() {
    MsgBox "Failed to enable location services... Exitting the auto installer", "Error!", "Iconx"
    ExitApp
}