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
    WinWait("Microsoft account")
    WinActivate
    Sleep(1000)
    screenArray := [
        { function: SelectCountry, element: { Type: "Pane", Name: "Is this the right country", MatchMode: "StartsWith" } },
        { function: SelectKeyboard, element: { Type: "Text", Name: "Is this the right keyboard", MatchMode: "StartsWith" } },
        { function: AddSecondKeyboard, element: { Type: "Pane", Name: "Want to add", MatchMode: "StartsWith" } },
        { function: ConnectToNetwork, element: { Type: "Window", Name: "Network Connection Flow" } },
        { function: LoginScreen, element: { Type: "Pane", Name: "Sign in to your account" } },
        { function: ProvisionOptions, element: { Type: "Pane", Name: "What would you", MatchMode: "StartsWith" } },
        { function: PreProvisionWithAutopilot, element: { AutomationId: "qrCodeImageLite" } }
    ]
    programWindow := UIA.ElementFromHandle("Microsoft account ahk_exe WWAHost.exe")
    currentScreen := GetCurrentScreen(programWindow, screenArray)

    for (index, screenObject in screenArray) {
        if (index < currentScreen) {
            continue
        }

        screenObject.function.Call(programWindow)
    }

    SoundBeep(, 1000)
    ExitApp
}

SelectCountry(window, country := "United States") {
    parentElement := window.WaitElement({ Type: "Pane", Name: "Is this the right country", MatchMode: "StartsWith" },
    5000,
    UIA.TreeScope.Children)

    if (!parentElement) {
        return DisplayErrorMessage()
    }

    parentElement.WaitElement({ Type: "ListItem", Name: country }, 5000).Invoke()
    parentElement.FindElement({ Type: "Button", Name: "Yes" }, , , "LastToFirstOrder").Invoke()
}

SelectKeyboard(window, country := "US") {
    getTitle := window.WaitElement({ Type: "Text", Name: "Is this the right keyboard", MatchMode: "StartsWith" }, 5000)

    if (!getTitle) {
        return DisplayErrorMessage()
    }

    parentElement := getTitle.WalkTree("p")
    parentElement.FindElement({ Type: "ListItem", Name: country }).Invoke()
    parentElement.FindElement({ Type: "Button", Name: "Yes" }, , , "LastToFirstOrder").Invoke()
}

AddSecondKeyboard(window) {
    parentElement := window.WaitElement({ Type: "Pane", Name: "Want to add", MatchMode: "StartsWith" }, 5000,
    UIA.TreeScope.Children)

    if (!parentElement) {
        return DisplayErrorMessage()
    }

    parentElement.FindElement({ Type: "Button", Name: "Skip", MatchMode: "StartsWith" }, , , "LastToFirstOrder").Invoke()
}

ConnectToNetwork(window) {
    parentElement := window.WaitElement({ Type: "Window", Name: "Network Connection Flow" }, 30000)

    if (!parentElement) {
        return DisplayErrorMessage()
    }

    metaguestItem := parentElement.FindElement({ Type: "ListItem", Name: "metaguest", MatchMode: "StartsWith" })
    isConnected := metaguestItem.WaitElement({ Type: "Text", Name: "Connected", MatchMode: "StartsWith" }, 10000)

    if (isConnected) {
        parentElement.FindElement({ Type: "Button", Name: "Next" }, , , "LastToFirstOrder").Invoke()
        return
    }

    try {
        metaguestItem.Select()
        metaguestItem.ScrollIntoView()
        metaguestItem.FindElement({ Type: "CheckBox", Name: "Connect automatically" }).ToggleState := 1
        metaguestItem.FindElement({ Type: "Button", Name: "Connect" }).Invoke()
        metaguestItem.WaitElement([
            { AutomationId: "PassKeyPasswordBox" },
            { AutomationId: "WCNComboPasswordBox" }
        ],
        10000).SetValue("effici3ncy")
        metaguestItem.FindElement({ AutomationId: "NextButton" }, , , "LastToFirstOrder").Invoke()
        isConnected := parentElement.WaitElement({ Type: "Text", Name: "Connected, secured" }, 5000)

        if (isConnected) {
            parentElement.FindElement({ AutomationId: "NextButton" }, , , "LastToFirstOrder").Invoke()
            return
        }
    }

    MsgBox("Unable to connect to the Wifi, please manually connect to the network.", "Warning!", "Icon!")
    Exit
}

LoginScreen(window) {
    parentElement := window.WaitElement({ Type: "Pane", Name: "Sign in to your account" },
    60000,
    UIA.TreeScope.Children)
    companyLogo := parentElement.WaitElement({ Type: "Image", LocalizedType: "image" }, 5000).Name

    if (!(companyLogo == "Microsoft") && !(companyLogo == "Organization banner logo")) {
        return DisplayErrorMessage()
    }

    if (companyLogo == "Microsoft") {
        MsgBox "
        (
        Register the device for Autopilot in Intune before proceeding!
        Restart the machine once the device is registered in Intune.
        )",
            "Warning!", "Icon!"
        return Exit
    }

    if (companyLogo == "Organization banner logo") {
        companyEmail := parentElement.FindElement({ AutomationId: "i0116" })

        if (!(companyEmail.Name ~= "meta.com$")) {
            return DisplayErrorMessage("Asset belongs to another organization. Please pick a different asset...")
        }

        companyEmail.Invoke()
        SendInput("{LWin 5}")
    }
}

ProvisionOptions(window) {
    getTitle := window.WaitElement({ Type: "Pane", Name: "What would you", MatchMode: "StartsWith" }, 10000)

    if (!getTitle) {
        return DisplayErrorMessage()
    }

    buttons := getTitle.FindElements([
        { Type: "ListItem", Name: "Pre-provision", MatchMode: "StartsWith" },
        { Type: "Button",
            Name: "Next" }
    ])

    for (button in buttons) {
        button.Invoke()
    }
}

PreProvisionWithAutopilot(window) {
    getQRCode := window.WaitElement({ AutomationId: "qrCodeImageLite" }, 60000, , , "LastToFirstOrder")
    manufacturer := RunCMD(
        "Powershell Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property Manufacturer")

    if (manufacturer ~= "Micro-Star International") {
        ; Add -NoExit paramater if terminal closes
        Run("PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command %~dp0check-me.ps1")
        ExitApp
    }

    if (!getQRCode) {
        return DisplayErrorMessage()
    }

    parentElement := getQRCode.WalkTree("p")
    deploymentProfile := parentElement.WaitElement({ Type: "Text", Name: "[User Device]", MatchMode: "StartsWith" },
    5000)

    if (!deploymentProfile) {
        return DisplayErrorMessage("Couldn't confirm Autopilot Profile.")
    }

    parentElement.FindElement({ Type: "Button", Name: "Next" }, , , "LastToFirstOrder").Invoke()
}

DisplayErrorMessage(message := "Failed to proceed to the next screen...") {
    MsgBox(message "`n`nStopping the auto installer.", "Error!", "Iconx")
    Exit
}

GetCurrentScreen(programWindow, screenArray) {
    for (index, screen in screenArray) {
        if (programWindow.ElementExist(screen.element)) {
            return index
        }
    }

    DisplayErrorMessage("Could not find the active screen...")
}
