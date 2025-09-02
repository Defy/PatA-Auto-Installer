$WIFI_NAME = "metaguest"

function Connect-Wifi {
    $XML_WIFI_PROFILE = ".\Wifi Profile\$WIFI_NAME-wifi-profile.xml"

    Get-Item $XML_WIFI_PROFILE | Out-Null -ErrorAction Stop
    netsh.exe wlan add profile filename=$XML_WIFI_PROFILE user=all
    netsh.exe wlan connect name=$WIFI_NAME
}

function Get-Networks {
    return netsh.exe wlan show networks
}

function Open-LocationSettings {
    $DRIVE_ROOT = (Get-Location).Path.Substring(0, 3)
    $AUTOHOTKEY = "$DRIVE_ROOT`AutoHotkey_2.0.19\AutoHotkey64.exe"
    $SCRIPT = "$DRIVE_ROOT`AutoHotkey_2.0.19\Script\Enable_Location_Services.ahk"

    Start-Process ms-settings:privacy-location
    Start-Process $AUTOHOTKEY -ArgumentList $SCRIPT -Wait
}

function Get-PrivacyLocation {
    $DURATION = 1
  
    Write-Output "Waiting for 'Location services' & 'Let apps access your location' to be enabled..."
    for ($i = 0; $i -lt 10; $i++) {
        $PRIVACY_LOCATION_VALUE = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location\ -Name "Value"

        Start-Sleep -Seconds $DURATION
        if ($PRIVACY_LOCATION_VALUE -eq "Allow") {
            $DURATION *= 2

            Start-Sleep -Seconds $DURATION
            return $true
        }
    }

    return $false
}

if (Get-Networks | Select-String -Pattern "(wlansvc)") {
    Set-ExecutionPolicy Unrestricted -Scope Process
    Start-Process powershell.exe $PSScriptRoot\get-drivers.ps1 -Wait -NoNewWindow
    for ($i = 1; $i -le 100; $i++ ) {
        $SLEEP_TIME = Get-Random -Minimum 0 -Maximum 200

        Write-Progress -Activity "Waiting for the device to detect the WiFi drivers..." -Status "$i%" -PercentComplete $i
        Start-Sleep -Milliseconds $SLEEP_TIME
    }
}

if (Get-Networks | Select-String -Pattern "Access is denied") {
    Open-LocationSettings
}

if ((-not (Get-PrivacyLocation)) -and (Get-Networks | Select-String -Pattern "Access is denied")) {
    Write-Output "Location services not enabled, please connect to metaguest wifi manually."
    exit 1
}

if (Get-Networks | Select-String -Pattern $WIFI_NAME) {
    Write-Output "Found $WIFI_NAME wifi `nAttempting connect $WIFI_NAME..."
    Connect-Wifi
}
else {
    Write-Output "Unable to find $WIFI_NAME"
    exit 1
}