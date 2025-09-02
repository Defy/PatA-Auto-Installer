function Get-InstalledHardDrives {
    $INSTALLED_DRIVERS = (wmic logicaldisk get description | Select-String -Pattern "Local Fixed Disk" | Measure-Object)

    if ($INSTALLED_DRIVERS.Count -gt 1) {
        Write-Output "More than 1 hard drive installed. Please pick a different asset."
        return $false
    }
    return $true
}

function Get-BatteryPercentage {
    # Cameron's Battery check script
}

if (Get-InstalledHardDrives) {
    $CONNECT_WIFI_PROCESS = Start-Process powershell.exe $PSScriptRoot\connect-wifi.ps1 -NoNewWindow -Wait -PassThru

    if ($CONNECT_WIFI_PROCESS.ExitCode -eq 1) {
        Write-Output "Try plugging in the ethernet cable and run autopilot auto installer again."
        return
    }
    $DRIVE_ROOT = (Get-Location).Path.Substring(0, 3)
    $AUTOHOTKEY = "$DRIVE_ROOT`AutoHotkey_2.0.19\AutoHotkey64.exe"
    $SCRIPT = "$DRIVE_ROOT`AutoHotkey_2.0.19\Script\Auto_Install_Windows_Autopilot.ahk"

    Start-Process $AUTOHOTKEY -ArgumentList $SCRIPT
    Write-Output "`nHold on to 'Ctrl + Alt + S' to stop the automated installer"
    Write-Output "Press 'Ctrl + Alt + Z' to resume the automated installer"
    Write-Output "Press 'Ctrl + Alt + X' to terminate the automated installer"
}