#Requires AutoHotkey v2.0
#Include .\Lib\UIA.ahk
DetectHiddenText(false)

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
    WinWait("Windows 11 Setup")
    WinActivate
    Sleep(1000)
    screensArray := [
        { function: SelectLanguage, title: "Select language settings" },
        { function: SelectKeyboard, title: "Select keyboard settings" },
        { function: SelectSetupOption, title: "Select setup option" },
        { function: GetImageTypes, title: "Select Image" },
        { function: AcceptLicenseTerms, title: "Applicable notices and license terms" },
        { function: SelectDiskInstallation, title: "Select location to install Windows 11" },
        { function: InstallWindows, title: "Ready to install" }
    ]
    currentScreen := GetCurrentScreen(screensArray)

    for (index, screenObject in screensArray) {
        if (index < currentScreen) {
            continue
        }

        screenObject.function.Call()
    }

    SoundBeep(, 1000)
    ExitApp
}

SelectLanguage() {
    if (!WinWait(, "Select language settings", 10)) {
        return DisplayErrorMessage()
    }

    SendInput("!n")
}

SelectKeyboard() {
    if (!WinWait(, "Select keyboard settings", 10)) {
        return DisplayErrorMessage()
    }

    SendInput("!n")
}

SelectSetupOption() {
    if (!WinWait(, "Select setup option", 10)) {
        return DisplayErrorMessage()
    }

    getProgramWindow := UIA.ElementFromHandle("Windows 11 Setup ahk_exe SetupHost.exe")
    getProgramWindow.FindElement({ AutomationId: "2307" }).ToggleState := 1
    SendInput("!n")
}

GetImageTypes() {
    if (!WinWait(, "Select Image", 10)) {
        return DisplayErrorMessage()
    }

    getProgramWindow := UIA.ElementFromHandle("Windows 11 Setup ahk_exe SetupHost.exe")
    selectedImage := getProgramWindow.FindElement({ AutomationId: "104" })
    SelectImageTypes("Windows 11 Enterprise")
    SendInput("!n")

    SelectImageTypes(imageType) {
        attempts := 10

        loop attempts {
            if (selectedImage.name == imageType) {
                return
            }

            SendInput "{Down}"
            Sleep(100)
        }

        return DisplayErrorMessage("Could not find the Image Type: " imageType "... ")
    }
}

AcceptLicenseTerms() {
    if (!WinWait(, "Applicable notices and license terms", 10)) {
        return DisplayErrorMessage()
    }

    SendInput("!a")
}

SelectDiskInstallation() {
    if (!WinWait(, "Select location to install Windows 11", 20)) {
        return DisplayErrorMessage()
    }

    attempts := 10

    while (!IsDisk0Unallocated()) {
        if (A_Index > attempts) {
            return DisplayErrorMessage("Could not delete all the partitions...")
        }

        selectedRow := UIA.GetFocusedElement().Name
        if (InStr(selectedRow, "Disk 0 Partition")) {
            SendInput("!d")
            WaitForPartitionDeletion()
        }

        GoToOption(GetDiskSteps(selectedRow))
    }

    selectedRow := UIA.GetFocusedElement().Name
    if (InStr(selectedRow, "Disk 0 Unallocated Space")) {
        SendInput("!n")
    }

    GetDiskSteps(selectedRow) {
        optionsStepsArray := []
        list := GetListContent()
        isBeforeSelectedRow := true

        loop parse list, "`n" {
            if (selectedRow == A_LoopField) {
                optionsStepsArray.Push(0)
                isBeforeSelectedRow := false
                continue
            }

            if (optionsStepsArray.Length < 1) {
                optionsStepsArray.Push(-1)
                continue
            }

            UpdateDiskSteps(isBeforeSelectedRow)
        }

        return optionsStepsArray

        UpdateDiskSteps(isBeforeSelectedRow) {
            insertIndex := 0

            for (index, option in optionsStepsArray) {
                if (option < 0 && isBeforeSelectedRow) {
                    optionsStepsArray[index] -= 1
                    continue
                }

                if (optionsStepsArray[index] == 1) {
                    insertIndex := index
                }

                if (option > 0) {
                    optionsStepsArray[index] += 1
                }
            }

            isBeforeSelectedRow ? optionsStepsArray.Push(-1) : optionsStepsArray.InsertAt(insertIndex, 1)
        }
    }

    GetListContent() {
        list := ""
        getProgramWindow := UIA.ElementFromHandle("Windows 11 Setup ahk_exe SetupHost.exe")
        parentElement := getProgramWindow.FindElement({ AutomationId: "2320" }, UIA.TreeScope.Children)
        listItems := parentElement.FindElements({ Type: "ListItem", LocalizedType: "list item" })

        for (item in listItems) {
            list := list item.Name "`n"
        }

        return list
    }

    GoToOption(optionsStepsArray) {
        navigation := { navigate: "", steps: 0 }

        for (, option in optionsStepsArray) {
            if (option == 0) {
                continue
            }

            (option < 0) ? navigation.navigate := "{Up}" : navigation.navigate := "{Down}"
                navigation.steps := Abs(option)
                break
        }

        loop navigation.steps {
            SendInput(navigation.navigate)
            Sleep(100)
        }
    }

    IsSelectedRowPartition() {
        selectedRow := UIA.GetFocusedElement().Name

        if (InStr(selectedRow, "Disk 0 Partition")) {
            return true
        }

        return false
    }

    IsDisk0Unallocated() {
        list := GetListContent()

        if (!RegexMatch(list, "m)^Disk 0 Partition")
        && RegexMatch(list, "Disk 0 Unallocated Space")) {
            return true
        }

        return false
    }

    WaitForPartitionDeletion() {
        programWindow := UIA.ElementFromHandle("Windows 11 Setup ahk_exe SetupHost.exe")
        refresh := programWindow.FindElement({ AutomationId: "2321" })

        Sleep(1000)
        while (!refresh.isEnabled) {
            Sleep(500)
        }
    }
}

InstallWindows() {
    if (!WinWait(, "Ready to install", 20)) {
        return DisplayErrorMessage()
    }

    SendInput("!i")
}

DisplayErrorMessage(message := "Failed to proceed to the next screen...") {
    MsgBox(message "`n`nStopping the auto installer.", "Error!", "Iconx")
    Exit
}

GetCurrentScreen(screensArray) {
    for (index, screen in screensArray) {
        if (WinExist(, screen.title)) {
            return index
        }
    }

    DisplayErrorMessage("Could not find the active screen...")
}
