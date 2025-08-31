function Get-InstalledHardDrives {
    $INSTALLED_DRIVERS = (wmic logicaldisk get description | Select-String -Pattern "Local Fixed Disk" | Measure-Object)
    if ($INSTALLED_DRIVERS.Count -gt 1) {
        Write-Output "More than 1 hard drive installed. Please pick a different asset"
        return $false
    }
    else {
        return $true
    }
    
}

if (Get-InstalledHardDrives) {
    $DRIVE_ROOT = (Get-Location).Path.Substring(0, 3)
    $AUTOHOTKEY = "$DRIVE_ROOT`AutoHotkey_2.0.19\AutoHotkey64.exe"
    $SCRIPT = "$DRIVE_ROOT`AutoHotkey_2.0.19\Script\Auto_Install_Windows_Autopilot.ahk"
    Start-Process powershell.exe $PSScriptRoot\connect-wifi.ps1 -NoNewWindow -Wait
    Start-Process $AUTOHOTKEY -ArgumentList $SCRIPT
    Write-Output "`nHold on to 'Ctrl + Alt + S' to stop the automated installer"
    Write-Output "Press 'Ctrl + Alt + Z' to resume the automated installer"
    Write-Output "Press 'Ctrl + Alt + X' to terminate the automated installer"
}