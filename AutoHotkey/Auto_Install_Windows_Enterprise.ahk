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
    windowsMap := Map(
        1, SelectLanguage,
        2, SelectKeyboard,
        3, SelectSetupOption,
        4, GetImageTypes,
        5, AcceptLicenseTerms,
        6, SelectDiskInstallation,
        7, InstallWindows
    )
    WinWait("Windows 11 Setup")
    WinActivate
    Sleep(1000)
    currentWindow := GetCurrentScreen()
    for (index in windowsMap) {
        if (index < currentWindow) {
            continue
        }
        windowsMap.Get(index)()
    }
    SoundBeep(, 1000)
    ExitApp
}

SelectLanguage() {
    if (WinWait(, "Select language settings", 10)) {
        SendInput("!n")
        return
    }
    DisplayErrorMessage()
}

SelectKeyboard() {
    if (WinWait(, "Select keyboard settings", 10)) {
        SendInput("!n")
        return
    }
    DisplayErrorMessage()
}

SelectSetupOption() {
    if (WinWait(, "Select setup option", 10)) {
        getProgramWindow := UIA.ElementFromHandle("Windows 11 Setup ahk_exe SetupHost.exe")
        getProgramWindow.FindElement({ AutomationId: "2307" }).ToggleState := 1
        SendInput("!n")
        return
    }
    DisplayErrorMessage()
}

GetImageTypes() {
    if (WinWait(, "Select Image", 10)) {
        getProgramWindow := UIA.ElementFromHandle("Windows 11 Setup ahk_exe SetupHost.exe")
        selectedImage := getProgramWindow.FindElement({ AutomationId: "104" })
        SelectImageTypes("Windows 11 Enterprise")
        SendInput("!n")
        return
    }
    DisplayErrorMessage()

    SelectImageTypes(imageType, counter := 0) {
        if (counter > 10) {
            DisplayErrorMessage("Could not find Image Type... ")
        }
        if (selectedImage.Name == imageType) {
            return
        }
        SendInput "{Down}"
        counter += 1
        Sleep(100)
        SelectImageTypes(imageType, counter)
    }
}

AcceptLicenseTerms() {
    if (WinWait(, "Applicable notices and license terms", 10)) {
        SendInput("!a")
        return
    }
    DisplayErrorMessage()
}

SelectDiskInstallation() {
    if (WinWait(, "Select location to install Windows 11", 20)) {
        tryCounter := 0
        while (!IsDisk0Unallocated()) {
            if (tryCounter > 10) {
                DisplayErrorMessage("Could not delete all the partitions...")
            }
            selectedRow := UIA.GetFocusedElement().Name
            if (InStr(selectedRow, "Disk 0 Partition")) {
                SendInput("!d")
                WaitForPartitionDeletion()
            }
            GoToOption(GetDiskSteps(selectedRow))
            tryCounter += 1
        }
        selectedRow := UIA.GetFocusedElement().Name
        if (InStr(selectedRow, "Disk 0 Unallocated Space")) {
            SendInput("!n")
        }
        return
    }
    DisplayErrorMessage()

    GetDiskSteps(selectedRow) {
        optionsStepsArray := []
        list := GetListContent()
        isBeforeSelectedRow := true
        loop parse list, "`n" {
            if (InStr(A_LoopField, "Disk")) {
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
        }
        return optionsStepsArray

        UpdateDiskSteps(boolean) {
            insertIndex := 0
            for (index, option in optionsStepsArray) {
                if (option < 0 && boolean) {
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
            boolean ? optionsStepsArray.Push(-1) : optionsStepsArray.InsertAt(insertIndex, 1)
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
        Loop navigation.steps {
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
        refresh := { X1: 45, Y1: 115, X2: 55, Y2: 125 }
        Sleep(1000)
        while (!PixelSearch(&pixelX, &pixelY, refresh.X1, refresh.Y1, refresh.X2, refresh.Y2, 0x3AA5E4, 3)) {
            Sleep(500)
        }
    }
}

InstallWindows() {
    if (WinWait(, "Ready to install", 20)) {
        SendInput("!i")
        return
    }
    DisplayErrorMessage()
}

DisplayErrorMessage(message := "Failed to proceed to the next screen...") {
    MsgBox(message " `n`nStopping the auto installer.", "Error!", "Iconx")
    Exit
}

GetCurrentScreen() {
    windowsArray := [
        "Select language settings",
        "Select keyboard settings",
        "Select setup option",
        "Select Image",
        "Applicable notices and license terms",
        "Select location to install Windows 11",
        "Ready to install"
    ]
    for (index, window in windowsArray) {
        if (WinExist(, window)) {
            return index
        }
    }
    DisplayErrorMessage("Could not find the active screen...")
}