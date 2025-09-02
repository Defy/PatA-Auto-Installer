#Requires AutoHotkey v2.0
#Include .\Lib\UIA.ahk
#Include .\Lib\RunCMD.ahk

Main()

^!z::
{
    Main()
}

^!s::
{
    Exit
}

^!r::
{
    Reload
}

^!x::
{
    ExitApp
}

Main() {
    screenMap := Map(
        1, SelectCountry,
        2, SelectKeyboard,
        3, AddSecondKeyboard,
        4, ConnectToNetwork,
        5, LoginScreen,
        6, ProvisionOptions,
        7, PreProvisionWithAutopilot
    )
    WinWait("Microsoft account")
    WinActivate
    Sleep(1000)
    getProgramWindow := UIA.ElementFromHandle("Microsoft account ahk_exe WWAHost.exe")
    currentScreen := GetCurrentScreen(getProgramWindow)
    for (index in screenMap) {
        if (index < currentScreen) {
            continue
        }
        screenMap.Get(index)(getProgramWindow)
    }
    SoundBeep(, 1000)
    ExitApp
}

SelectCountry(window, country := "United States") {
    parentElement := window.WaitElement({ Type: "Pane", Name: "Is this the right country", MatchMode: "StartsWith" },
        5000,
        UIA.TreeScope.Children)
    if (parentElement) {
        parentElement.WaitElement({ Type: "ListItem", Name: country }, 5000).Invoke()
        parentElement.FindElement({ Type: "Button", Name: "Yes" }, , , "LastToFirstOrder").Invoke()
        return
    }
    DisplayErrorMessage()
}

SelectKeyboard(window, country := "US") {
    getTitle := window.WaitElement({ Type: "Text", Name: "Is this the right keyboard", MatchMode: "StartsWith" }, 5000)
    if (getTitle) {
        parentElement := getTitle.WalkTree("p")
        parentElement.FindElement({ Type: "ListItem", Name: country }).Invoke()
        parentElement.FindElement({ Type: "Button", Name: "Yes" }, , , "LastToFirstOrder").Invoke()
        return
    }
    DisplayErrorMessage()
}

AddSecondKeyboard(window) {
    parentElement := window.WaitElement({ Type: "Pane", Name: "Want to add", MatchMode: "StartsWith" }, 5000,
        UIA.TreeScope.Children)
    if (parentElement) {
        parentElement.FindElement({ Type: "Button", Name: "Skip", MatchMode: "StartsWith" }, , , "LastToFirstOrder").Invoke()
        return
    }
    DisplayErrorMessage()
}

ConnectToNetwork(window) {
    parentElement := window.WaitElement({ Type: "Window", Name: "Network Connection Flow" }, 30000,
        UIA.TreeScope.Children)
    if (parentElement) {
        metaguestItem := parentElement.FindElement({ Type: "ListItem", Name: "metaguest", MatchMode: "StartsWith" })
        isConnected := metaguestItem.WaitElement({ Type: "Text", Name: "Connected" }, 10000)
        if (isConnected) {
            parentElement.FindElement({ Type: "Button", Name: "Connect" }, , , "LastToFirstOrder").Invoke()
            return
        }
        ; metaguestItem.Invoke()
        ; metaguestItem.FindElement({ Type: "CheckBox", Name: "Connect automatically" }).Invoke()
        ; metaguestItem.FindElement({ Type: "Button", Name: "Connect" }).Invoke()
        ; metaguestItem.FindElement({ AutomationId: "PassKeyPasswordBox" }).Value := "effici3ncy"
        ; metaguestItem.FindElement({ AutomationId: "NextButton" }, , , "LastToFirstOrder")
        ; isConnected := metaguestItem.WaitElement({ AutomationId: "SystemSettings_Connection", Name: "Connected, secured" }, 10000)
        ; if (isConnected) {
        ;     parentElement.FindElement({ Type: "Button", Name: "Connect" }, , , "LastToFirstOrder").Invoke()
        ;     return
        ; }
        MsgBox("Unable to connect to the Wifi, please manually connect to the network.", "Warning!", "Icon!")
        Exit
        return
    }
    DisplayErrorMessage()
}

LoginScreen(window) {
    parentElement := window.WaitElement({ Type: "Pane", Name: "Sign in to your account" },
        60000,
        UIA.TreeScope.Children)
    companyLogo := parentElement.WaitElement({ Type: "Image", LocalizedType: "image" }, 5000).Name
    if (companyLogo == "Microsoft") {
        MsgBox "
        (
        Register the device for Autopilot in Intune before proceeding!
        Restart the machine once the device is registered in Intune.
        )", "Warning!", "Icon!"
        Exit
        return
    }
    if (companyLogo == "Organization banner logo") {
        companyEmail := parentElement.FindElement({ AutomationId: "i0116" })
        if (companyEmail.Name ~= "meta.com$") {
            companyEmail.Invoke()
            SendInput("{LWin 5}")
            return
        }
        DisplayErrorMessage("Asset belongs to another organization. Please pick a different asset...")
    }
    DisplayErrorMessage()
}

ProvisionOptions(window) {
    getTitle := window.WaitElement({ Type: "Pane", Name: "What would you", MatchMode: "StartsWith" }, 10000)
    if (getTitle) {
        buttons := getTitle.FindElements([{ Type: "ListItem", Name: "Pre-provision", MatchMode: "StartsWith" }, { Type: "Button", Name: "Next" }])
        for (button in buttons) {
            button.Invoke()
        }
        return
    }
    DisplayErrorMessage()
}

PreProvisionWithAutopilot(window) {
    getQRCode := window.WaitElement({ AutomationId: "qrCodeImageLite" }, 60000, , , "LastToFirstOrder")
    manufacturer := RunCMD("Powershell Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property Manufacturer")
    if (manufacturer ~= "MSI") {
        ; Add -NoExit paramater if terminal closes
        Run("PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0check-me.ps1")
        ExitApp
    }
    if (getQRCode) {
        parentElement := getQRCode.WalkTree("p")
        deploymentProfile := parentElement.WaitElement({ Type: "Text", Name: "[User Device]", MatchMode: "StartsWith" }, 5000)
        if (deploymentProfile) {
            parentElement.FindElement({ Type: "Button", Name: "Next" }, , , "LastToFirstOrder").Invoke()
            return
        }
        DisplayErrorMessage("Couldn't confirm Autopilot Profile.")
    }
    DisplayErrorMessage()
}

DisplayErrorMessage(message := "Failed to proceed to the next screen...") {
    MsgBox(message " `n`nStopping the auto installer.", "Error!", "Iconx")
    Exit
}

GetCurrentScreen(programWindow) {
    screenArray := [{ Type: "Pane", Name: "Is this the right country", MatchMode: "StartsWith" }, { Type: "Text", Name: "Is this the right keyboard", MatchMode: "StartsWith" }, { Type: "Pane", Name: "Want to add", MatchMode: "StartsWith" }, { Type: "Window", Name: "Network Connection Flow" }, { Type: "Pane", Name: "Sign in to your account" }, { Type: "Pane", Name: "What would you", MatchMode: "StartsWith" }, { AutomationId: "qrCodeImageLite" },
    ]
    for (index, screen in screenArray) {
        if (programWindow.ElementExist(screen)) {
            return index
        }
    }
    DisplayErrorMessage("Could not find the active screen...")
}