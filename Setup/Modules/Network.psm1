function Invoke-WiFiAutoConnection {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # Check WLAN service
        try {
            $wlanService = Get-Service -Name "WlanSvc" -ErrorAction SilentlyContinue
            if (-not $wlanService) {
                Add-Status "No WiFi capability detected - skipping WiFi setup" $statusTextBox ([System.Drawing.Color]::Yellow)
                return $true
            }

            if ($wlanService.Status -ne "Running") {
                Start-Service -Name "WlanSvc" -ErrorAction Stop
                Start-Sleep -Seconds 3
            }
        }
        catch {
            Add-Status "WiFi service error: $_" $statusTextBox ([System.Drawing.Color]::Red)
            return $false
        }

        # Quick WiFi adapter check
        Add-Status "Detecting WiFi adapters..." $statusTextBox
        try {
            $wifiAdapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "(?i)(wireless|wifi|802\.11|wi-fi|wlan|wi\\s?fi|ax200|ax201|ax210|ac\\d{4})" -or $_.InterfaceType -eq 71 }

            if (-not $wifiAdapters) {
                # Thử Internet qua Ethernet trước
                try { $hasInternet = Test-NetConnection 8.8.8.8 -Port 53 -InformationLevel Quiet } catch { $hasInternet = $false }
                if ($hasInternet) {
                    Add-Status "No WiFi adapters, but Internet is available via Ethernet. Skipping WiFi." $statusTextBox ([System.Drawing.Color]::Cyan)
                    return $true
                }

                Add-Status "No WiFi adapters found. Trying WiFi driver EXE..." $statusTextBox ([System.Drawing.Color]::Yellow)
                $ownerForm = $null; try { $ownerForm = $statusTextBox.FindForm() } catch {}
                $exeOk = Install-DriverExe -Path $Global:WifiDriverExe -statusTextBox $statusTextBox -Type 'WiFi'
                if (-not $exeOk) {
                    # Fallback: nếu bạn đã có Install-WiFiDriversOffline dạng .inf, có thể gọi thêm:
                    if (Get-Command Install-WiFiDriversOffline -ErrorAction SilentlyContinue) {
                        $infOk = Install-WiFiDriversOffline -OwnerForm $ownerForm -statusTextBox $statusTextBox
                    }
                    else { $infOk = $false }
                    if (-not $infOk) {
                        Add-Status "WiFi driver install failed or no adapters present. Continuing without WiFi." $statusTextBox ([System.Drawing.Color]::Yellow)
                        return $false
                    }
                }

                # Re-scan sau khi cài
                $wifiAdapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "(?i)(wireless|wifi|802\.11|wi-fi|wlan|wi\\s?fi|ax200|ax201|ax210|ac\\d{4})" -or $_.InterfaceType -eq 71 }
                if (-not $wifiAdapters) {
                    Add-Status "WiFi adapters still not detected. Continuing without WiFi." $statusTextBox ([System.Drawing.Color]::Yellow)
                    return $false
                }
            }
            Add-Status "Found $($wifiAdapters.Count) WiFi adapter(s)" $statusTextBox ([System.Drawing.Color]::Green)
        }
        catch { Add-Status "WiFi adapter detection failed: $_" $statusTextBox ([System.Drawing.Color]::Red); return $false }

        # Check current WiFi connection
        $targetSSID = "VietUnion_5.0GHz"
        Add-Status "Checking current WiFi connection..." $statusTextBox

        try {
            $currentConnection = netsh wlan show interfaces

            # Parse current connection info
            $isConnected = $false
            $currentSSID = ""

            foreach ($line in $currentConnection) {
                if ($line -match "^\s*State\s*:\s*connected\s*$") { $isConnected = $true }
                if ($line -match "^\s*SSID\s*:\s*(.+)$") { $currentSSID = $matches[1].Trim() }
            }

            # Check if already connected to target network
            if ($isConnected -and $currentSSID -eq $targetSSID) { Add-Status "Already connected to $targetSSID - skipping WiFi setup" $statusTextBox ([System.Drawing.Color]::Green); return $true }
            elseif ($isConnected -and $currentSSID -ne "" -and $currentSSID -ne $targetSSID) { Add-Status "Currently connected to: $currentSSID" $statusTextBox ([System.Drawing.Color]::Yellow); Add-Status "Need to connect to: $targetSSID" $statusTextBox }
            else { Add-Status "No active WiFi connection detected" $statusTextBox ([System.Drawing.Color]::Yellow) }
        }
        catch { Add-Status "Could not check current WiFi status - proceeding with setup" $statusTextBox ([System.Drawing.Color]::Yellow) }

        # Create WiFi profile
        $SSID = "VietUnion_5.0GHz"
        $Password = "Pay00@17Years$"
        $profileFile = "$env:TEMP\VietUnion_5.0GHz_profile.xml"

        Add-Status "Creating WiFi profile for $SSID..." $statusTextBox

        try {
            $SSIDHEX = ($SSID.ToCharArray() | ForEach-Object { '{0:X2}' -f ([int]$_) }) -join ''

            $profileXML = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$SSID</name>
    <SSIDConfig>
        <SSID>
            <hex>$SSIDHEX</hex>
            <name>$SSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$Password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@

            [System.IO.File]::WriteAllText($profileFile, $profileXML, [System.Text.Encoding]::UTF8)
            Add-Status "WiFi profile created successfully" $statusTextBox ([System.Drawing.Color]::Green)
        }
        catch { Add-Status "Failed to create WiFi profile: $_" $statusTextBox ([System.Drawing.Color]::Red); return $false }

        # Add WiFi profile
        Add-Status "Adding WiFi profile to system..." $statusTextBox
        try {
            # Remove existing profile first
            $null = netsh wlan delete profile name="$SSID" 2>$null

            # Add new profile for all users
            $null = netsh wlan add profile filename="$profileFile" user=all
            if ($LASTEXITCODE -eq 0) { Add-Status "WiFi profile added successfully" $statusTextBox ([System.Drawing.Color]::Green) }
            else { Add-Status "Failed to add WiFi profile" $statusTextBox ([System.Drawing.Color]::Red); return $false }
        }
        catch { Add-Status "WiFi profile addition failed: $_" $statusTextBox ([System.Drawing.Color]::Red); return $false }

        # Connect to WiFi (with retries)
        Add-Status "Connecting to WiFi network..." $statusTextBox
        try {
            $maxRetries = 3
            for ($i = 1; $i -le $maxRetries; $i++) {
                $null = netsh wlan connect name="$SSID"
                if ($LASTEXITCODE -eq 0) { Add-Status "WiFi connection attempt #$i initiated" $statusTextBox ([System.Drawing.Color]::Green) }
                else { Add-Status "WiFi connection attempt #$i failed to initiate" $statusTextBox ([System.Drawing.Color]::Yellow) }
                Start-Sleep -Seconds (3 + $i * 2)
                $verify = netsh wlan show interfaces | Out-String
                if ($verify -match "State\s*:\s*connected" -and $verify -match ("SSID\s*:\s*{0}" -f [regex]::Escape($SSID))) { Add-Status "WiFi connected successfully to $SSID!" $statusTextBox ([System.Drawing.Color]::Green); return $true }
                else { Add-Status "WiFi verification attempt #$i not connected yet." $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
            Add-Status "WiFi connection verification failed after retries" $statusTextBox ([System.Drawing.Color]::Yellow)
            return $false
        }
        catch { Add-Status "WiFi connection error: $_" $statusTextBox ([System.Drawing.Color]::Red); return $false }
        finally { if (Test-Path $profileFile) { Remove-Item $profileFile -Force -ErrorAction SilentlyContinue } }
    }
    catch { Add-Status "WiFi setup failed: $_" $statusTextBox ([System.Drawing.Color]::Red); return $false }
}
function Invoke-WindowsUpdateCheck {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # Quick service check
        $wuService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        if ($wuService -and $wuService.Status -ne "Running") { Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue }

        # Test internet connectivity
        $testConnection = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if (-not $testConnection) { Add-Status "No internet connection - skipping Windows Update" $statusTextBox ([System.Drawing.Color]::Yellow); return $false }

        # Trigger updates in background
        try {
            # Use USOClient for immediate trigger
            Start-Process -FilePath "USOClient.exe" -ArgumentList "ScanInstallWait" -WindowStyle Hidden -ErrorAction Stop
            Start-Process -FilePath "USOClient.exe" -ArgumentList "StartDownload" -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "USOClient.exe" -ArgumentList "StartInstall" -WindowStyle Hidden -ErrorAction SilentlyContinue
            return $true
        }
        catch { # Fallback to wuauclt
            try {
                Start-Process -FilePath "wuauclt.exe" -ArgumentList "/detectnow" -WindowStyle Hidden -ErrorAction Stop
                Start-Process -FilePath "wuauclt.exe" -ArgumentList "/updatenow" -WindowStyle Hidden -ErrorAction SilentlyContinue
                return $true
            }
            catch { Add-Status "Warning: Windows Update trigger failed" $statusTextBox ([System.Drawing.Color]::Yellow); return $false }
        }
    }
    catch { Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red); return $false }
}

Export-ModuleMember -Function Invoke-WiFiAutoConnection, Invoke-WindowsUpdateCheck
