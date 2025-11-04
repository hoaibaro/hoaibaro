function Install-DriverExe {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][System.Windows.Forms.RichTextBox]$statusTextBox, [ValidateSet('Ethernet', 'WiFi')][string]$Type = 'Ethernet')
    try {
        if (-not (Test-Path $Path)) {
            Add-Status "$Type driver not found at: $Path" $statusTextBox ([System.Drawing.Color]::Yellow)
            return $false
        }

        Add-Status "Installing $Type driver from: $Path" $statusTextBox
        $commonArgs = @(
            '/quiet /norestart',
            '/s',
            '/silent',
            '-s',
            '/qn'
        )
        $installed = $false
        foreach ($silentArgs in $commonArgs) {
            try {
                $p = Start-Process -FilePath $Path -ArgumentList $silentArgs -Wait -PassThru -NoNewWindow
                if ($p.ExitCode -in 0, 3010) {
                    Add-Status "$Type driver installer finished with code $($p.ExitCode)" $statusTextBox ([System.Drawing.Color]::Green)
                    $installed = $true
                    break
                }
                else { Add-Status "$Type driver installer returned code $($p.ExitCode) with args: $silentArgs" $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
            catch { Add-Status "$Type driver install attempt failed with args '$silentArgs': $_" $statusTextBox ([System.Drawing.Color]::Yellow) }
        }

        if (-not $installed) {
            Add-Status "$Type driver EXE did not install successfully with common silent switches." $statusTextBox ([System.Drawing.Color]::Yellow)
            return $false
        }

        Start-Sleep -Seconds 8
        return $true
    }
    catch { Add-Status "$Type driver installation error: $_" $statusTextBox ([System.Drawing.Color]::Red); return $false }
}

function Test-7ZipInstalled {
    $paths = @("C:\Program Files\7-Zip\7z.exe", "C:\Program Files (x86)\7-Zip\7z.exe")
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}
function Test-ChromeInstalled {
    $paths = @("C:\Program Files\Google\Chrome\Application\chrome.exe", "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}
function Test-LAPSInstalledOrBuiltin {
    [CmdletBinding()]
    param()

    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $isWindows11 = $osInfo.Caption -like "*Windows 11*" -or ($osInfo.BuildNumber -ge 22000 -and $osInfo.ProductType -eq 1)

        if ($isWindows11) {
            $lapsCsp = Get-CimInstance -Namespace "root\cimv2\mdm\dmmap" -ClassName "MDM_Policy_Config01_System02" -Filter "InstanceID='System' AND ParentID='./Device/Vendor/MSFT/Policy/Config'" -ErrorAction SilentlyContinue
            $hasLapsCsp = $null -ne $lapsCsp
            return @{ BuiltIn = $true; Installed = $true; Version = "Windows 11 Built-in"; SupportsCSP = $hasLapsCsp }
        }

        $lapsDll = "C:\Program Files\LAPS\CSE\AdmPwd.dll"
        $isLapsInstalled = Test-Path $lapsDll
        $version = $null

        if ($isLapsInstalled) {
            $fileInfo = (Get-Item $lapsDll).VersionInfo
            $version = "$($fileInfo.FileMajorPart).$($fileInfo.FileMinorPart).$($fileInfo.FileBuildPart).$($fileInfo.FilePrivatePart)"
        }

        return @{ BuiltIn = $false; Installed = $isLapsInstalled; Version = $version; SupportsCSP = $false }
    }
    catch {
        $lapsDll = "C:\Program Files\LAPS\CSE\AdmPwd.dll"
        return @{ BuiltIn = $false; Installed = (Test-Path $lapsDll); Version = $null; SupportsCSP = $false }
    }
}
function Test-FoxitInstalled {
    $paths = @("C:\Program Files (x86)\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe", "C:\Program Files\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe", "C:\Program Files (x86)\Foxit Software\Foxit Reader\FoxitReader.exe", "C:\Program Files\Foxit Software\Foxit Reader\FoxitReader.exe")
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}
function Test-Office2019Installed {
    $paths = @("C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE")
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}
function Test-ZoomInstalled {
    $paths = @("$env:USERPROFILE\AppData\Roaming\Zoom\bin\Zoom.exe", "C:\Program Files\Zoom\bin\Zoom.exe", "C:\Program Files (x86)\Zoom\bin\Zoom.exe")
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}
function Test-CheckPointVPNInstalled {
    $paths = @("C:\Program Files (x86)\CheckPoint\Endpoint Connect\trac.exe")
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}
function Test-OneDriveInstalled {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    $uninstallKeys = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*")
    foreach ($keyPath in $uninstallKeys) {
        try {
            $programs = Get-ItemProperty $keyPath -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*OneDrive*" -or $_.DisplayName -like "*Microsoft OneDrive*" }
            if ($programs) { return $true }
        }
        catch { if($statusTextBox) {Add-Status "ERROR: OneDrive installation check failed: $_" $statusTextBox ([System.Drawing.Color]::Red)} }
    }
    $oneDrivePaths = @("$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe", "$env:PROGRAMFILES\Microsoft OneDrive\OneDrive.exe", "$env:PROGRAMFILES(x86)\Microsoft OneDrive\OneDrive.exe")
    foreach ($path in $oneDrivePaths) { if (Test-Path $path) { return $true } }
    try {
        $package = Get-Package | Where-Object { $_.Name -like "*OneDrive*" }
        if ($package) { return $true }
    }
    catch { if ($statusTextBox) { Add-Status "ERROR: OneDrive installation check failed: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red) } }
    return $false
}

function Uninstall-OneDriveComplete {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        if (-not (Test-OneDriveInstalled -statusTextBox $statusTextBox)) {
            Add-Status "OneDrive: Not found" $statusTextBox
            return $true
        }
        Add-Status "OneDrive detected. Starting uninstallation..." $statusTextBox
        $oneDriveProcesses = @("OneDrive", "OneDriveSetup", "FileCoAuth", "OneDriveStandaloneUpdater", "OneDriveUpdaterService")
        foreach ($processName in $oneDriveProcesses) {
            try {
                $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
                if ($processes) {
                    foreach ($proc in $processes) { $proc.Kill(); Start-Sleep -Milliseconds 500 }
                }
            }
            catch { Add-Status "ERROR: OneDrive uninstallation failed: $_" $statusTextBox ([System.Drawing.Color]::Red) }
        }
        $uninstallSuccess = $false
        $registryPaths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
        foreach ($regPath in $registryPaths) {
            if ($uninstallSuccess) { break }
            try {
                $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue
                foreach ($key in $subKeys) {
                    $program = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
                    if ($program.DisplayName -like "*OneDrive*" -and $program.UninstallString) {
                        $uninstallString = $program.UninstallString
                        $uninstallCommands = @()
                        if ($program.QuietUninstallString) { $uninstallCommands += $program.QuietUninstallString }
                        if ($uninstallString -match '"([^"]+)"(.*)') {
                            $exe = $matches[1]; $arguments = $matches[2].Trim()
                            $uninstallCommands += "`"$exe`" $arguments /quiet /norestart"
                            $uninstallCommands += "`"$exe`" $arguments /S"
                            $uninstallCommands += "`"$exe`" $arguments /silent"
                        }
                        foreach ($cmd in $uninstallCommands) {
                            try {
                                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$cmd`"" -Wait -PassThru -WindowStyle Hidden
                                if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) { $uninstallSuccess = $true; break }
                                else { Add-Status "Exit code: $($process.ExitCode)" $statusTextBox ([System.Drawing.Color]::Red) }
                            }
                            catch { Add-Status "Command failed: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red) }
                        }
                        if ($uninstallSuccess) { break }
                    }
                }
            }
            catch { Add-Status "Registry access error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red) }
        }
        if ($uninstallSuccess) {
            Start-Sleep -Seconds 5
            if (Test-OneDriveInstalled -statusTextBox $statusTextBox) {
                Add-Status "OneDrive still detected after uninstall attempt" $statusTextBox ([System.Drawing.Color]::Yellow)
                $uninstallSuccess = $false
            }
            else { return $true }
        }
        if (-not $uninstallSuccess) {
            $setupPaths = @("$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe", "$env:SYSTEMROOT\System32\OneDriveSetup.exe", "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveSetup.exe")
            foreach ($setupPath in $setupPaths) {
                if (Test-Path $setupPath) {
                    try {
                        Add-Status "Using: $setupPath" $statusTextBox
                        $setupCommands = @("/uninstall /allusers", "/uninstall", "/uninstall /quiet")
                        foreach ($silentArgs in $setupCommands) {
                            $process = Start-Process -FilePath $setupPath -ArgumentList $silentArgs -Wait -PassThru -WindowStyle Hidden
                            if ($process.ExitCode -eq 0) {
                                Start-Sleep -Seconds 3
                                if (-not (Test-OneDriveInstalled -statusTextBox $statusTextBox)) { return $true }
                            }
                        }
                    }
                    catch { Add-Status "OneDriveSetup failed: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red) }
                }
            }
        }
        if (Test-OneDriveInstalled -statusTextBox $statusTextBox) {
            Add-Status "OneDrive still present. Manual intervention may be required." $statusTextBox ([System.Drawing.Color]::Yellow)
            try {
                Start-Process -FilePath "appwiz.cpl" -WindowStyle Normal
                [System.Windows.Forms.MessageBox]::Show("Automatic uninstall failed.`n`nControl Panel has been opened.`nPlease manually uninstall 'Microsoft OneDrive'.", "Manual Uninstall Required", "OK", "Warning")
            }
            catch { Add-Status "Could not open Control Panel" $statusTextBox ([System.Drawing.Color]::Red) }
            return $false
        }
        else {
            Add-Status "OneDrive has been uninstalled." $statusTextBox
            try { Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue }
            catch { Add-Status "Could not clean up OneDrive registry entry" $statusTextBox ([System.Drawing.Color]::Red) }
            return $true
        }
    }
    catch { Add-Status "Critical error in OneDrive removal: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red); return $false }
}

function PlanSoftwareInstall {
    param([ValidateSet('Desktop', 'Laptop')][string]$DeviceType, [System.Windows.Forms.RichTextBox]$statusTextBox)
    $pending = @(); $skipped = @()
    $appsMeta = @(
        @{ Id = 'onedrive'; Display = 'OneDrive'; Device = 'All' },
        @{ Id = '7zip'; Display = '7-Zip'; Device = 'All' },
        @{ Id = 'chrome'; Display = 'Google Chrome'; Device = 'All' },
        @{ Id = 'laps'; Display = 'LAPS'; Device = 'All' },
        @{ Id = 'foxit'; Display = 'Foxit Reader'; Device = 'All' },
        @{ Id = 'office2019'; Display = 'Office 2019'; Device = 'All' },
        @{ Id = 'zoom'; Display = 'Zoom'; Device = 'Laptop' },
        @{ Id = 'checkpointvpn'; Display = 'CheckPoint VPN'; Device = 'Laptop' }
    )
    foreach ($app in $appsMeta) {
        if ($app.Device -ne 'All' -and $app.Device -ne $DeviceType) { continue }
        switch ($app.Id) {
            'onedrive' { if (Test-OneDriveInstalled -statusTextBox $statusTextBox) { $pending += $app } else { $skipped += $app } }
            '7zip' { if (Test-7ZipInstalled) { $skipped += $app } else { $pending += $app } }
            'chrome' { if (Test-ChromeInstalled) { $skipped += $app } else { $pending += $app } }
            'laps' { $laps = Test-LAPSInstalledOrBuiltin; if ($laps.Installed) { $skipped += $app } else { $pending += $app } }
            'foxit' { if (Test-FoxitInstalled) { $skipped += $app } else { $pending += $app } }
            'office2019' { if (Test-Office2019Installed) { $skipped += $app } else { $pending += $app } }
            'zoom' { if (Test-ZoomInstalled) { $skipped += $app } else { $pending += $app } }
            'checkpointvpn' { if (Test-CheckPointVPNInstalled) { $skipped += $app } else { $pending += $app } }
        }
    }
    if ($statusTextBox) {
        if ($pending.Count -gt 0) {
            $pendingDisplays = $pending | ForEach-Object { $_.Display }
            Add-Status ("Pending: " + ($pendingDisplays -join ", ")) $statusTextBox ([System.Drawing.Color]::Yellow)
        }
    }
    return @{ Pending = $pending; Skipped = $skipped; Meta = $appsMeta }
}

function Copy-SoftwareFilesSelective {
    param(
        [ValidateSet('Desktop', 'Laptop')][string]$DeviceType,
        [array]$Apps,
        [System.Windows.Forms.RichTextBox]$statusTextBox,
        [string]$SourceSetupPath = ''
    )
    $setupDir = Join-Path $env:USERPROFILE 'Downloads\SETUP'
    $office2019Dir = Join-Path $setupDir 'Office 2019'
    if (-not (Test-Path $setupDir)) { New-Item -Path $setupDir -ItemType Directory -Force | Out-Null }
    if (-not (Test-Path $SourceSetupPath)) {
        Add-Status "Error: Source directory not found at $SourceSetupPath" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
    $srcOffice = Join-Path $SourceSetupPath 'Office 2019'
    $allCopied = $true
    foreach ($app in $Apps) {
        switch ($app.Id) {
            '7zip' {
                $file = Get-ChildItem -Path $SourceSetupPath -Filter '7z*.exe' | Select-Object -First 1
                if ($file) { try { Copy-Item -Path $file.FullName -Destination $setupDir -Force } catch { $allCopied = $false; Add-Status "Failed : 7-Zip ($($_.Exception.Message))" $statusTextBox ([System.Drawing.Color]::Red) } }
                else { $allCopied = $false; Add-Status "Missing 7-Zip installer in $SourceSetupPath" $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
            'chrome' {
                $src = Join-Path $SourceSetupPath 'ChromeSetup.exe'
                if (Test-Path $src) { try { Copy-Item -Path $src -Destination (Join-Path $setupDir 'ChromeSetup.exe') -Force } catch { $allCopied = $false; Add-Status "Failed : Chrome ($($_.Exception.Message))" $statusTextBox ([System.Drawing.Color]::Red) } }
                else { $allCopied = $false; Add-Status "Missing ChromeSetup.exe in $SourceSetupPath" $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
            'laps' {
                $src = Join-Path $SourceSetupPath 'LAPS_x64.msi'
                if (Test-Path $src) { try { Copy-Item -Path $src -Destination (Join-Path $setupDir 'LAPS_x64.msi') -Force } catch { $allCopied = $false; Add-Status "Failed : LAPS ($($_.Exception.Message))" $statusTextBox ([System.Drawing.Color]::Red) } }
                else { $allCopied = $false; Add-Status "Missing LAPS_x64.msi in $SourceSetupPath" $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
            'foxit' {
                $file = Get-ChildItem -Path $SourceSetupPath -Filter 'FoxitPDFReader*.exe' | Select-Object -First 1
                if ($file) { try { Copy-Item -Path $file.FullName -Destination $setupDir -Force } catch { $allCopied = $false; Add-Status "Failed : Foxit ($($_.Exception.Message))" $statusTextBox ([System.Drawing.Color]::Red) } }
                else { $allCopied = $false; Add-Status "Missing Foxit installer in $SourceSetupPath" $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
            'office2019' {
                if (Test-Path $srcOffice) {
                    if (-not (Test-Path $office2019Dir)) { New-Item -Path $office2019Dir -ItemType Directory -Force | Out-Null }
                    try { Copy-Item -Path (Join-Path $srcOffice '*') -Destination $office2019Dir -Recurse -Force } catch { $allCopied = $false; Add-Status "Failed : Office 2019 ($($_.Exception.Message))" $statusTextBox ([System.Drawing.Color]::Red) }
                } else { $allCopied = $false; Add-Status "Missing Office 2019 source in $srcOffice" $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
            'zoom' {
                $src = Join-Path $SourceSetupPath 'ZoomInstallerFull.exe'
                if (Test-Path $src) { try { Copy-Item -Path $src -Destination (Join-Path $setupDir 'ZoomInstallerFull.exe') -Force } catch { $allCopied = $false; Add-Status "Failed : Zoom ($($_.Exception.Message))" $statusTextBox ([System.Drawing.Color]::Red) } }
                else { $allCopied = $false; Add-Status "Missing ZoomInstallerFull.exe in $SourceSetupPath" $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
            'checkpointvpn' {
                $src = Join-Path $SourceSetupPath 'CheckPointVPN.msi'
                if (Test-Path $src) { try { Copy-Item -Path $src -Destination (Join-Path $setupDir 'CheckPointVPN.msi') -Force } catch { $allCopied = $false; Add-Status "Failed : CheckPointVPN ($($_.Exception.Message))" $statusTextBox ([System.Drawing.Color]::Red) } }
                else { $allCopied = $false; Add-Status "Missing CheckPointVPN.msi in $SourceSetupPath" $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
            default { Add-Status "Error: '$($app.Id)'" $statusTextBox ([System.Drawing.Color]::Yellow) }
        }
    }
    return $allCopied
}

function Install-Software {
    param ([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox, [array]$appsToInstall, [switch]$CleanupTemp)
    try {
        $setupDir = "$env:USERPROFILE\Downloads\SETUP"
        $office2019Dir = "$setupDir\Office 2019"
        $appIds = $appsToInstall | ForEach-Object { $_.Id }

        if (Test-OneDriveInstalled -statusTextBox $statusTextBox) {
            $result = Uninstall-OneDriveComplete -statusTextBox $statusTextBox
            if ($result) { Add-Status "OneDrive: Has been uninstalled!" $statusTextBox }
            else { Add-Status "OneDrive: Removal incomplete. Check Control Panel." $statusTextBox ([System.Drawing.Color]::Yellow) }
        }
        else { Add-Status "Not Installed : OneDrive" $statusTextBox }

        if ($appIds -contains '7zip') {
            $sevenZipInstaller = Get-ChildItem -Path $setupDir -Include "7z*.exe", "7-Zip*.exe", "7zip*.exe" -Recurse | Select-Object -First 1
            if ($sevenZipInstaller) {
                Add-Status "Installing : 7-Zip" $statusTextBox
                try {
                    $process = Start-Process -FilePath $sevenZipInstaller.FullName -ArgumentList "/S" -Wait -PassThru -WindowStyle Hidden
                    if ($process.ExitCode -eq 0) { Add-Status "Installed : 7-Zip" $statusTextBox }
                    else { Add-Status "Error: $($process.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow) }
                } catch { Add-Status "Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red) }
            } else { Add-Status "Warning: Installer not found" $statusTextBox ([System.Drawing.Color]::Red) }
        } else { Add-Status "Existed : 7-Zip" $statusTextBox }

        if ($appIds -contains 'chrome') {
            $chromeInstaller = Join-Path $setupDir "ChromeSetup.exe"
            if (Test-Path $chromeInstaller) {
                Add-Status "Installing : Chrome" $statusTextBox
                try {
                    $process = Start-Process -FilePath $chromeInstaller -ArgumentList "/silent /install" -Wait -PassThru -WindowStyle Hidden
                    if ($process.ExitCode -eq 0) { Add-Status "Installed : Chrome" $statusTextBox }
                    else { Add-Status "Error: $($process.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow) }
                } catch { Add-Status "Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red) }
            } else { Add-Status "Warning: Installer not found" $statusTextBox ([System.Drawing.Color]::Red) }
        } else { Add-Status "Existed : Chrome" $statusTextBox }

        if ($appIds -contains 'laps') {
            $osInfo = Get-ComputerInfo
            if ($osInfo.WindowsProductName -match "Windows 10") {
                $lapsInstaller = Join-Path $setupDir "LAPS_x64.msi"
                if (Test-Path $lapsInstaller) {
                    Add-Status "Installing : LAPS" $statusTextBox
                    try {
                        $result = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$lapsInstaller`" /qn /norestart" -Wait -PassThru
                        if ($result.ExitCode -eq 0) { Add-Status "Installed : LAPS" $statusTextBox }
                        else { Add-Status "Error: $($result.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow) }
                    } catch { Add-Status "Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red) }
                } else { Add-Status "Warning: Installer not found" $statusTextBox ([System.Drawing.Color]::Red) }
            } else { Add-Status "Built-in on Windows 11, skipping installation" $statusTextBox }
        } else { Add-Status "Existed : LAPS" $statusTextBox }

        if ($appIds -contains 'foxit') {
            $foxitInstaller = Get-ChildItem -Path $setupDir -Include "Foxit*.exe" -Recurse | Select-Object -First 1
            if ($foxitInstaller) {
                Add-Status "Installing : Foxit Reader" $statusTextBox
                try {
                    $result = Start-Process -FilePath $foxitInstaller.FullName -ArgumentList "/VERYSILENT /NORESTART /SUPPRESSMSGBOXES" -Wait -PassThru
                    if ($result.ExitCode -eq 0) { Add-Status "Installed : Foxit Reader" $statusTextBox }
                    else { Add-Status "Error: $($result.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow) }
                } catch { Add-Status "Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red) }
            } else { Add-Status "Warning: Installer not found" $statusTextBox ([System.Drawing.Color]::Red) }
        } else { Add-Status "Existed : Foxit Reader" $statusTextBox }

        if ($appIds -contains 'office2019') {
            if (-not (Test-Path $office2019Dir)) { Add-Status "Office 2019: Source directory not found at $office2019Dir" $statusTextBox ([System.Drawing.Color]::Red); return $false }
            $officeSetup = Join-Path $office2019Dir "setup.exe"
            $configFile = Join-Path $office2019Dir "config.xml"
            if (-not (Test-Path $officeSetup)) { Add-Status "Office 2019: Setup file not found at $officeSetup" $statusTextBox ([System.Drawing.Color]::Red); return $false }
            Add-Status "Office 2019: Starting silent installation..." $statusTextBox
            try {
                if (-not (Test-Path $configFile)) {
                    $configContent = '<Configuration><Add OfficeClientEdition="64" Channel="PerpetualVL2019"><Product ID="ProPlus2019Volume" PIDKEY="Q2NKY-J42YJ-X2KVK-9Q9PT-MKP63"><Language ID="en-us" /><ExcludeApp ID="Access" /><ExcludeApp ID="Groove" /><ExcludeApp ID="Lync" /><ExcludeApp ID="OneNote" /><ExcludeApp ID="Publisher" /></Product></Add><Display Level="None" AcceptEULA="TRUE" /><Property Name="AUTOACTIVATE" Value="1" /><Property Name="FORCEAPPSHUTDOWN" Value="TRUE" /><Property Name="SharedComputerLicensing" Value="0" /><Property Name="PinIconsToTaskbar" Value="TRUE" /><Logging Level="Standard" Path="%TEMP%" /><RemoveMSI /></Configuration>'
                    Set-Content -Path $configFile -Value $configContent -Force
                    Add-Status "Office 2019: Created configuration file" $statusTextBox
                }
                $process = Start-Process -FilePath $officeSetup -ArgumentList "/configure `"$configFile`"" -Wait -PassThru -NoNewWindow
                if ($process.ExitCode -eq 0) { Add-Status "Installed : Office2019ProPlus" $statusTextBox }
                else { Add-Status "Error: $($process.ExitCode)" $statusTextBox ([System.Drawing.Color]::Red); return $false }
            }
            catch { Add-Status "Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red); return $false }
        } else { Add-Status "Existed : Office2019ProPlus" $statusTextBox }

        if ($deviceType -eq "Laptop" -and $appIds -contains 'zoom') {
            $zoomInstaller = Get-ChildItem -Path $setupDir -Include "ZoomInstaller*.exe","ZoomInstallerFull*.exe" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
            if ($zoomInstaller) {
                Add-Status "Installing : Zoom" $statusTextBox
                try {
                    $process = Start-Process -FilePath $zoomInstaller -ArgumentList "/silent /norestart" -Wait -PassThru
                    if ($process.ExitCode -eq 0) { Add-Status "Installed : Zoom" $statusTextBox }
                    else { Add-Status "Error: $($process.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow) }
                } catch { Add-Status "Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red) }
            } else { Add-Status "Zoom: Installer not found" $statusTextBox ([System.Drawing.Color]::Red) }
        } elseif ($deviceType -eq "Laptop") { Add-Status "Existed : Zoom" $statusTextBox }

        if ($deviceType -eq "Laptop" -and $appIds -contains 'checkpointvpn') {
            $vpnInstaller = Join-Path $setupDir "CheckPointVPN.msi"
            if (Test-Path $vpnInstaller) {
                Add-Status "Installing : CheckPoint VPN" $statusTextBox
                try {
                    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$vpnInstaller`" /qn /norestart" -Wait -PassThru
                    if ($process.ExitCode -eq 0) { Add-Status "Installed : CheckPoint VPN" $statusTextBox }
                    else { Add-Status "Error: $($process.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow) }
                } catch { Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red) }
            } else { Add-Status "CheckPoint VPN: Installer not found" $statusTextBox ([System.Drawing.Color]::Red) }
        } elseif ($deviceType -eq "Laptop") { Add-Status "Existed : CheckPoint VPN" $statusTextBox }
        return $true
    }
    catch { Add-Status "Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red); return $false }
    finally {
        try {
            if ($CleanupTemp) {
                $tempDir = "$env:USERPROFILE\Downloads\SETUP"
                if (Test-Path $tempDir) {
                    Add-Status "Cleaning up temporary files..." $statusTextBox
                    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                    if (-not (Test-Path $tempDir)) { Add-Status "Temporary folders cleaned up successfully!" $statusTextBox }
                    else { Add-Status "Warning: Could not fully remove temporary directory." $statusTextBox ([System.Drawing.Color]::Yellow) }
                }
            }
        }
        catch {Add-Status "Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)}
    }
}

function Invoke-InstallSoftware {
    param([ValidateSet('Desktop', 'Laptop')][string]$DeviceType, [System.Windows.Forms.RichTextBox]$statusTextBox, [switch]$CleanupTemp)
    
    $destCopy = "$env:USERPROFILE\Downloads"
    $srcSETUP = $Global:config.sourcePaths.software
    $destSETUP = "$env:USERPROFILE\Downloads\SETUP"
    $tempDir = $destSETUP

    $scFiles = Get-ChildItem -Path (Join-Path $srcSETUP 'SC-*') -File -ErrorAction SilentlyContinue
    if ($scFiles) {
        $scDest = Join-Path $destCopy $scFiles.Name
        if (-not (Test-Path $scDest)) {
            if (Test-Path $scFiles.FullName) { Copy-Item -Path $scFiles.FullName -Destination $scDest -Force; Add-Status "Copying: ForceScout" $statusTextBox }
            else { Add-Status "Warning: Not found ForceScout source file" $statusTextBox ([System.Drawing.Color]::Yellow) }
        } else { Add-Status "Existed: ForceScout" $statusTextBox }
    } else { Add-Status "Warning: Not found ForceScout source file" $statusTextBox ([System.Drawing.Color]::Yellow) }

    $unikeyFolder = Get-ChildItem -Path (Join-Path $srcSETUP 'unikey*') -Directory -ErrorAction SilentlyContinue
    if ($unikeyFolder) {
        $unikeyDest = "C:\" + $unikeyFolder.Name
        if (-not (Test-Path $unikeyDest)) {
            if (Test-Path $unikeyFolder.FullName) {
                New-Item -ItemType Directory -Path $unikeyDest -Force | Out-Null
                Copy-Item -Path "$($unikeyFolder.FullName)\*" -Destination $unikeyDest -Recurse -Force
                Add-Status "Copying: Unikey" $statusTextBox
            } else { Add-Status "Error: Not found Unikey source file" $statusTextBox ([System.Drawing.Color]::Red) }
        } else { Add-Status "Existed: Unikey" $statusTextBox }
    } else { Add-Status "Warning: Not found Unikey source file" $statusTextBox ([System.Drawing.Color]::Yellow) }

    $csFolder = Get-ChildItem -Path (Join-Path $srcSETUP 'CrowdStrike*') -Directory -ErrorAction SilentlyContinue
    if ($csFolder) {
        $csDest = Join-Path $destCopy $csFolder.Name
        if (-not (Test-Path $csDest)) {
            if (Test-Path $csFolder.FullName) {
                New-Item -ItemType Directory -Path $csDest -Force | Out-Null
                Copy-Item -Path "$($csFolder.FullName)\*" -Destination $csDest -Recurse -Force
                Add-Status "Copying: CrowdStrike" $statusTextBox
            } else { Add-Status "Error: Not found CrowdStrike source file" $statusTextBox ([System.Drawing.Color]::Red) }
        } else { Add-Status "Existed: CrowdStrike" $statusTextBox }
    } else { Add-Status "Warning: Not found CrowdStrike source file" $statusTextBox ([System.Drawing.Color]::Yellow) }

    if ($DeviceType -eq "Desktop") {
        $desktopAgent = Get-ChildItem -Path (Join-Path $srcSETUP 'Desktop Agent*.exe') -File -ErrorAction SilentlyContinue
        if ($desktopAgent) {
            $agentDest = Join-Path $destCopy $desktopAgent.Name
            if (-not (Test-Path $agentDest)) {
                if (Test-Path $desktopAgent.FullName) { Copy-Item -Path $desktopAgent.FullName -Destination $agentDest -Force; Add-Status "Copying: DesktopAgent" $statusTextBox }
                else { Add-Status "Error: Not found DesktopAgent source file" $statusTextBox ([System.Drawing.Color]::Red) }
            } else { Add-Status "Existed: DesktopAgent" $statusTextBox }
        } else { Add-Status "Error: Not found DesktopAgent source file" $statusTextBox ([System.Drawing.Color]::Red) }
    }
    else {
        $laptopAgent = Get-ChildItem -Path (Join-Path $srcSETUP 'Laptop Agent*.exe') -File -ErrorAction SilentlyContinue
        if ($laptopAgent) {
            $agentDest = Join-Path $destCopy $laptopAgent.Name
            if (-not (Test-Path $agentDest)) {
                if (Test-Path $laptopAgent.FullName) { Copy-Item -Path $laptopAgent.FullName -Destination $agentDest -Force; Add-Status "Copying: Laptop Agent" $statusTextBox }
                else { Add-Status "Error: Not found LaptopAgent source file" $statusTextBox ([System.Drawing.Color]::Red) }
            } else { Add-Status "Existed: Laptop Agent" $statusTextBox }
        } else { Add-Status "Error: Not found LaptopAgent source file" $statusTextBox ([System.Drawing.Color]::Red) }

        $mdmSource = Join-Path $srcSETUP "ManageEngine_MDMLaptopEnrollment"
        $mdmDest = Join-Path $destCopy "ManageEngine_MDMLaptopEnrollment"
        if (-not (Test-Path $mdmDest)) {
            if (Test-Path $mdmSource) {
                try {
                    $null = New-Item -Path $mdmDest -ItemType Directory -Force -ErrorAction Stop
                    Copy-Item -Path "$mdmSource\*" -Destination $mdmDest -Recurse -Force
                    Add-Status "Copying: ManageEngine" $statusTextBox
                } catch { Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red) }
            } else { Add-Status "Error: Not found ManageEngine source directory" $statusTextBox ([System.Drawing.Color]::Red) }
        } else { Add-Status "Existed: ManageEngine" $statusTextBox }
    }

    try {
        if (-not (Test-Path $srcSETUP)) { Add-Status "Error: Not found $srcSETUP" $statusTextBox ([System.Drawing.Color]::Red); return $false }
        Add-Status "Checking installed software..." $statusTextBox
        $plan = PlanSoftwareInstall -DeviceType $DeviceType -statusTextBox $statusTextBox
        if ($plan.Pending.Count -gt 0) {
            Add-Status "Found $($plan.Pending.Count) software(s) to install" $statusTextBox
            if (-not (Test-Path $destSETUP)) { New-Item -Path $destSETUP -ItemType Directory -Force | Out-Null }
            $okCopy = Copy-SoftwareFilesSelective -DeviceType $DeviceType -Apps $plan.Pending -statusTextBox $statusTextBox -SourceSetupPath $srcSETUP
            if (-not $okCopy) { Add-Status "Error: Failed to copy installers" $statusTextBox ([System.Drawing.Color]::Red); return $false }
            $okInstall = Install-Software -deviceType $DeviceType -statusTextBox $statusTextBox -appsToInstall $plan.Pending -CleanupTemp:$CleanupTemp
            if (-not $okInstall) { Add-Status "Error: Some installations failed" $statusTextBox ([System.Drawing.Color]::Red); return $false }
            Add-Status "All software installation completed successfully" $statusTextBox
            return $true
        } else {
            Add-Status "All required software is already installed." $statusTextBox
            return $true
        }
    }
    catch { Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red); return $false }
    finally {
        if ($CleanupTemp -and $tempDir -and (Test-Path $tempDir) -and (-not $tempDir.Contains("MDM_Setup"))) {
            try { Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue; Add-Status "Temporary files cleaned up successfully!" $statusTextBox }
            catch { Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red) }
        }
    }
}

function Show-InstallSoftwareDialog {
    param($mainForm)

    Hide-MainMenu -mainForm $mainForm
    $deviceTypeForm = New-Object System.Windows.Forms.Form
    $deviceTypeForm.Text = "Select Device Type"
    $deviceTypeForm.Size = New-Object System.Drawing.Size(485, 490)
    $deviceTypeForm.StartPosition = "CenterScreen"
    $deviceTypeForm.BackColor = [System.Drawing.Color]::Black
    $deviceTypeForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $deviceTypeForm.MaximizeBox = $false
    $deviceTypeForm.MinimizeBox = $false
    Add-GradientBackground -form $deviceTypeForm
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "SELECT DEVICE TYPE"
    $titleLabel.Location = New-Object System.Drawing.Point(110, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(250, 40)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $deviceTypeForm.Controls.Add($titleLabel)
    Add-TitleAnimation -titleLabel $titleLabel
    $statusTextBox = New-Object System.Windows.Forms.RichTextBox
    $statusTextBox.Multiline = $true
    $statusTextBox.ScrollBars = "Vertical"
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 110)
    $statusTextBox.Size = New-Object System.Drawing.Size(450, 330)
    $statusTextBox.BackColor = [System.Drawing.Color]::Black
    $statusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusTextBox.ReadOnly = $true
    $statusTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $statusTextBox.Text = "Please select a device type..."
    $deviceTypeForm.Controls.Add($statusTextBox)
    $btnDesktop = New-DynamicButton -text "DESKTOP" -x 10 -y 50 -width 200 -height 50 -clickAction {
        Add-Status "Starting Desktop setup workflow..." $statusTextBox
        Invoke-InstallSoftware -DeviceType "Desktop" -statusTextBox $statusTextBox
    }
    $deviceTypeForm.Controls.Add($btnDesktop)
    $btnLaptop = New-DynamicButton -text "LAPTOP" -x 260 -y 50 -width 200 -height 50 -clickAction {
        Add-Status "Starting Laptop setup workflow..." $statusTextBox
        Invoke-InstallSoftware -DeviceType "Laptop" -statusTextBox $statusTextBox
    }
    $deviceTypeForm.Controls.Add($btnLaptop)
    $deviceTypeForm.KeyPreview = $true
    $deviceTypeForm.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $deviceTypeForm.Close() } })
    $deviceTypeForm.Add_FormClosed({ Show-MainMenu -mainForm $mainForm })
    $deviceTypeForm.ShowDialog()
}

Export-ModuleMember -Function Install-DriverExe, Show-InstallSoftwareDialog, Invoke-InstallSoftware, Test-OneDriveInstalled, Uninstall-OneDriveComplete