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

function Test-AppInstalled {
    param($appConfig, [System.Windows.Forms.RichTextBox]$statusTextBox)

    if ($appConfig.checkType -eq 'function') {
        $cmd = $appConfig.checkFunction
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            try {
                $result = & $cmd -statusTextBox $statusTextBox
                if ($result -is [bool]) { return $result }
                if ($result -is [hashtable] -and $result.ContainsKey('Installed')) { return $result.Installed }
                if ($result.PSObject.Properties['Installed']) { return $result.Installed }
                return [bool]$result
            }
            catch {
                return $false
            }
        }
        return $false
    }
    elseif ($appConfig.checkType -eq 'path') {
        if ($appConfig.checkPaths) {
            foreach ($path in $appConfig.checkPaths) {
                $expandedPath = $ExecutionContext.InvokeCommand.ExpandString($path)
                if (Test-Path $expandedPath) { return $true }
            }
        }
        return $false
    }
    return $false
}
function Test-LAPSInstalledOrBuiltin {
    [CmdletBinding()]
    param([System.Windows.Forms.RichTextBox]$statusTextBox)

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

function Test-OneDriveInstalled {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    $uninstallKeys = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*")
    foreach ($keyPath in $uninstallKeys) {
        try {
            $programs = Get-ItemProperty $keyPath -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*OneDrive*" -or $_.DisplayName -like "*Microsoft OneDrive*" }
            if ($programs) { return $true }
        }
        catch { if ($statusTextBox) { Add-Status "ERROR: OneDrive installation check failed: $_" $statusTextBox ([System.Drawing.Color]::Red) } }
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

function Invoke-InstallerWithTimeout {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $false)][string]$ArgumentList = "",
        [Parameter(Mandatory = $false)][int]$TimeoutSeconds = 900,
        [Parameter(Mandatory = $false)][System.Diagnostics.ProcessWindowStyle]$WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden,
        [Parameter(Mandatory = $false)][System.Windows.Forms.RichTextBox]$StatusTextBox = $null,
        [Parameter(Mandatory = $false)][string]$AppName = "Installer"
    )
    
    try {
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $FilePath
        $processInfo.Arguments = $ArgumentList
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = ($WindowStyle -eq [System.Diagnostics.ProcessWindowStyle]::Hidden)
        $processInfo.WindowStyle = $WindowStyle
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        
        $processStarted = $process.Start()
        if (-not $processStarted) {
            if ($StatusTextBox) { Add-Status "$AppName : Failed to start installer process" $StatusTextBox ([System.Drawing.Color]::Red) }
            return @{ Success = $false; ExitCode = $null; TimedOut = $false; Process = $null }
        }
        
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)
        
        if (-not $completed) {
            # Timeout occurred
            try {
                $process.Kill()
                Start-Sleep -Seconds 1
            }
            catch { }
            
            if ($StatusTextBox) { Add-Status "$AppName : Installation timed out after $TimeoutSeconds seconds" $StatusTextBox ([System.Drawing.Color]::Red) }
            return @{ Success = $false; ExitCode = $null; TimedOut = $true; Process = $null }
        }
        
        $exitCode = $process.ExitCode
        $success = ($exitCode -eq 0 -or $exitCode -eq 3010) # 3010 = Success restart required
        
        return @{
            Success  = $success
            ExitCode = $exitCode
            TimedOut = $false
            Process  = $process
        }
    }
    catch {
        if ($StatusTextBox) { Add-Status "$AppName : Error executing installer - $($_.Exception.Message)" $StatusTextBox ([System.Drawing.Color]::Red) }
        return @{ Success = $false; ExitCode = $null; TimedOut = $false; Process = $null }
    }
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
                                $result = Invoke-InstallerWithTimeout -FilePath "cmd.exe" -ArgumentList "/c `"$cmd`"" -TimeoutSeconds 900 -StatusTextBox $statusTextBox -AppName "OneDrive Uninstall"
                                if ($result.Success) { $uninstallSuccess = $true; break }
                                elseif ($result.TimedOut) { Add-Status "OneDrive uninstall timed out after 15 minutes" $statusTextBox ([System.Drawing.Color]::Red) }
                                else { Add-Status "Exit code: $($result.ExitCode)" $statusTextBox ([System.Drawing.Color]::Red) }
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
                            $result = Invoke-InstallerWithTimeout -FilePath $setupPath -ArgumentList $silentArgs -TimeoutSeconds 900 -StatusTextBox $statusTextBox -AppName "OneDrive Setup Uninstall"
                            if ($result.Success) {
                                Start-Sleep -Seconds 3
                                if (-not (Test-OneDriveInstalled -statusTextBox $statusTextBox)) { return $true }
                            }
                            elseif ($result.TimedOut) { Add-Status "OneDriveSetup uninstall timed out after 15 minutes" $statusTextBox ([System.Drawing.Color]::Red) }
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
    param([ValidateSet('Desktop', 'Laptop')][string]$DeviceType, [System.Windows.Forms.RichTextBox]$statusTextBox, [switch]$ShowPendingList)
    $pending = @(); $skipped = @()
    
    $appsMeta = $Global:config.software
    
    foreach ($app in $appsMeta) {
        if (-not $app.enabled) { continue }
        if ($app.device -ne 'All' -and $app.device -ne $DeviceType) { continue }
        
        $isInstalled = Test-AppInstalled -appConfig $app -statusTextBox $statusTextBox
        
        # Special handling for uninstall tasks (like OneDrive)
        if ($app.task -eq 'uninstall') {
            if ($isInstalled) { $pending += $app } # Pending uninstall
            else { $skipped += $app }
        }
        else {
            if ($isInstalled) { $skipped += $app }
            else { $pending += $app }
        }
    }

    if ($ShowPendingList -and $statusTextBox) {
        if ($pending.Count -gt 0) {
            $pendingDisplays = $pending | ForEach-Object { 
                if ($_.task -eq 'uninstall') { "$($_.displayName) (Uninstall)" }
                else { $_.displayName }
            }
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
    if (-not (Test-Path $setupDir)) { New-Item -Path $setupDir -ItemType Directory -Force | Out-Null }
    
    if (-not (Test-Path $SourceSetupPath)) {
        Add-Status "Error: Source directory not found at $SourceSetupPath" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }

    $allCopied = $true
    
    foreach ($app in $Apps) {
        # Skip if it's an uninstall task
        if ($app.task -eq 'uninstall') { continue }

        $appName = $app.displayName
        
        # Special handling for Office type
        if ($app.installerType -eq 'office') {
            $srcOffice = Join-Path $SourceSetupPath $app.sourceSubDir
            $destOffice = Join-Path $setupDir $app.sourceSubDir
             
            if (Test-Path $srcOffice) {
                if (Test-Path $destOffice -and (Test-Path (Join-Path $destOffice $app.installerName))) {
                    Add-Status "Existed : $appName source" $statusTextBox
                }
                else {
                    if (-not (Test-Path $destOffice)) { New-Item -Path $destOffice -ItemType Directory -Force | Out-Null }
                    try { 
                        Copy-Item -Path (Join-Path $srcOffice '*') -Destination $destOffice -Recurse -Force 
                        Add-Status "Copying : $appName" $statusTextBox
                    } 
                    catch { 
                        $allCopied = $false; 
                        Add-Status "Failed : $appName ($($_.Exception.Message))" $statusTextBox ([System.Drawing.Color]::Red) 
                    }
                }
            }
            else { 
                $allCopied = $false; 
                Add-Status "Missing $appName source in $srcOffice" $statusTextBox ([System.Drawing.Color]::Yellow) 
            }
            continue
        }

        # Generic file copy
        if ($app.installerName) {
            $file = Get-ChildItem -Path $SourceSetupPath -Filter $app.installerName | Select-Object -First 1
            if ($file) {
                $dest = Join-Path $setupDir $file.Name
                if (Test-Path $dest) { 
                    Add-Status "Existed : $appName installer" $statusTextBox 
                }
                else { 
                    try { 
                        Copy-Item -Path $file.FullName -Destination $dest -Force 
                        Add-Status "Copying : $appName" $statusTextBox
                    } 
                    catch { 
                        $allCopied = $false; 
                        Add-Status "Failed : $appName ($($_.Exception.Message))" $statusTextBox ([System.Drawing.Color]::Red) 
                    } 
                }
            }
            else { 
                $allCopied = $false; 
                Add-Status "Missing $appName installer ($($app.installerName)) in $SourceSetupPath" $statusTextBox ([System.Drawing.Color]::Yellow) 
            }
        }
    }
    return $allCopied
}

function Install-Software {
    param ([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox, [array]$appsToInstall, [switch]$CleanupTemp)
    try {
        $setupDir = "$env:USERPROFILE\Downloads\SETUP"
        
        foreach ($app in $appsToInstall) {
            $appName = $app.displayName
            
            # Uninstall Task
            if ($app.task -eq 'uninstall') {
                if ($app.uninstallFunction) {
                    $cmd = $app.uninstallFunction
                    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                        & $cmd -statusTextBox $statusTextBox
                    }
                }
                continue
            }

            # Install Task
            if ($app.installerType -eq 'office') {
                # Office specific logic (config generation etc)
                $officeDir = Join-Path $setupDir $app.sourceSubDir
                if (-not (Test-Path $officeDir)) { Add-Status "${appName}: Source directory not found" $statusTextBox ([System.Drawing.Color]::Red); continue }
                
                $setupFile = Join-Path $officeDir $app.installerName
                $configFile = Join-Path $officeDir "config.xml"
                
                if (-not (Test-Path $setupFile)) { Add-Status "${appName}: Setup file not found" $statusTextBox ([System.Drawing.Color]::Red); continue }
                
                Add-Status "${appName}: Starting silent installation..." $statusTextBox
                
                # Generate config.xml if missing
                if (-not (Test-Path $configFile)) {
                    $key = $Global:config.officeActivation.productKey
                    $configContent = "<Configuration><Add OfficeClientEdition=""64"" Channel=""PerpetualVL2019""><Product ID=""ProPlus2019Volume"" PIDKEY=""$key""><Language ID=""en-us"" /><ExcludeApp ID=""Access"" /><ExcludeApp ID=""Groove"" /><ExcludeApp ID=""Lync"" /><ExcludeApp ID=""OneNote"" /><ExcludeApp ID=""Publisher"" /></Product></Add><Display Level=""None"" AcceptEULA=""TRUE"" /><Property Name=""AUTOACTIVATE"" Value=""1"" /><Property Name=""FORCEAPPSHUTDOWN"" Value=""TRUE"" /><Property Name=""SharedComputerLicensing"" Value=""0"" /><Property Name=""PinIconsToTaskbar"" Value=""TRUE"" /><Logging Level=""Standard"" Path=""%TEMP%"" /><RemoveMSI /></Configuration>"
                    Set-Content -Path $configFile -Value $configContent -Force
                    Add-Status "${appName}: Created configuration file" $statusTextBox
                }
                
                $result = Invoke-InstallerWithTimeout -FilePath $setupFile -ArgumentList "/configure `"$configFile`"" -TimeoutSeconds 2700 -StatusTextBox $statusTextBox -AppName $appName -WindowStyle Hidden
                if ($result.Success) { Add-Status "Installed : $appName" $statusTextBox }
                else { Add-Status "$appName : Failed/Timeout" $statusTextBox ([System.Drawing.Color]::Red) }
                continue
            }

            # Generic Exe/Msi
            $installerPath = $null
            if ($app.installerName) {
                $installerPath = Get-ChildItem -Path $setupDir -Filter $app.installerName -Recurse | Select-Object -First 1 | Select-Object -ExpandProperty FullName
            }
            
            if ($installerPath) {
                Add-Status "Installing : $appName" $statusTextBox
                
                $installArgs = if ($app.installArgs) { $app.installArgs } else { "" }
                
                if ($app.installerType -eq 'msi') {
                    if ($installArgs) {
                        $installArgs = $installArgs.Replace("{installerPath}", $installerPath)
                    }
                    $exe = "msiexec.exe"
                    $result = Invoke-InstallerWithTimeout -FilePath $exe -ArgumentList $installArgs -TimeoutSeconds 600 -StatusTextBox $statusTextBox -AppName $appName
                }
                else {
                    $result = Invoke-InstallerWithTimeout -FilePath $installerPath -ArgumentList $installArgs -TimeoutSeconds 600 -StatusTextBox $statusTextBox -AppName $appName
                }

                if ($result.Success) { Add-Status "Installed : $appName" $statusTextBox }
                elseif ($result.TimedOut) { Add-Status "$appName : Installation timed out" $statusTextBox ([System.Drawing.Color]::Red) }
                else { Add-Status "$appName : Error - Exit code $($result.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
            else {
                Add-Status "Warning: Installer for $appName not found" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
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
        catch { Add-Status "Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red) }
    }
}

function Invoke-InstallSoftware {
    param([ValidateSet('Desktop', 'Laptop')][string]$DeviceType, [System.Windows.Forms.RichTextBox]$statusTextBox, [switch]$CleanupTemp)
    
    $destCopy = "$env:USERPROFILE\Downloads"
    
    # Auto-detect if current config path is invalid
    if (-not (Test-Path $Global:config.sourcePaths.software)) {
        $usbRoot = Find-UsbSourcePath -statusTextBox $statusTextBox
        if ($usbRoot) {
            # Helper to replace drive letter (duplicated logic, but safe)
            $newDrive = $usbRoot
            $currentPath = $Global:config.sourcePaths.software
            if ($currentPath.Length -gt 1 -and $currentPath[1] -eq ':') {
                $Global:config.sourcePaths.software = $newDrive.Substring(0, 1) + $currentPath.Substring(1)
            }
        }
    }
    
    $srcSETUP = $Global:config.sourcePaths.software
    $destSETUP = "$env:USERPROFILE\Downloads\SETUP"
    $tempDir = $destSETUP

    

    try {
        Add-Status "Checking installed software..." $statusTextBox
        $plan = PlanSoftwareInstall -DeviceType $DeviceType -statusTextBox $statusTextBox -ShowPendingList:$false
        
        # Always check and copy ancillary files/folders regardless of pending installs
        if (Test-Path $srcSETUP) {
            $scFiles = Get-ChildItem -Path (Join-Path $srcSETUP 'SC-*') -File -ErrorAction SilentlyContinue
            if ($scFiles) {
                $scDest = Join-Path $destCopy $scFiles.Name
                if (-not (Test-Path $scDest)) {
                    if (Test-Path $scFiles.FullName) { Copy-Item -Path $scFiles.FullName -Destination $scDest -Force; Add-Status "Copying: ForceScout" $statusTextBox }
                    else { Add-Status "Warning: Not found ForceScout source file" $statusTextBox ([System.Drawing.Color]::Yellow) }
                }
                else { Add-Status "Existed: ForceScout" $statusTextBox }
            }
            else { Add-Status "Warning: Not found ForceScout source file" $statusTextBox ([System.Drawing.Color]::Yellow) }

            $unikeyFolder = Get-ChildItem -Path (Join-Path $srcSETUP 'unikey*') -Directory -ErrorAction SilentlyContinue
            if ($unikeyFolder) {
                $unikeyDest = "C:\" + $unikeyFolder.Name
                if (-not (Test-Path $unikeyDest)) {
                    if (Test-Path $unikeyFolder.FullName) {
                        New-Item -ItemType Directory -Path $unikeyDest -Force | Out-Null
                        Copy-Item -Path "$($unikeyFolder.FullName)\*" -Destination $unikeyDest -Recurse -Force
                        Add-Status "Copying: Unikey" $statusTextBox
                    }
                    else { Add-Status "Error: Not found Unikey source file" $statusTextBox ([System.Drawing.Color]::Red) }
                }
                else { Add-Status "Existed: Unikey" $statusTextBox }
            }
            else { Add-Status "Warning: Not found Unikey source file" $statusTextBox ([System.Drawing.Color]::Yellow) }

            $csFolder = Get-ChildItem -Path (Join-Path $srcSETUP 'CrowdStrike*') -Directory -ErrorAction SilentlyContinue
            if ($csFolder) {
                $csDest = Join-Path $destCopy $csFolder.Name
                if (-not (Test-Path $csDest)) {
                    if (Test-Path $csFolder.FullName) {
                        New-Item -ItemType Directory -Path $csDest -Force | Out-Null
                        Copy-Item -Path "$($csFolder.FullName)\*" -Destination $csDest -Recurse -Force
                        Add-Status "Copying: CrowdStrike" $statusTextBox
                    }
                    else { Add-Status "Error: Not found CrowdStrike source file" $statusTextBox ([System.Drawing.Color]::Red) }
                }
                else { Add-Status "Existed: CrowdStrike" $statusTextBox }
            }
            else { Add-Status "Warning: Not found CrowdStrike source file" $statusTextBox ([System.Drawing.Color]::Yellow) }

            if ($DeviceType -eq "Desktop") {
                $desktopAgent = Get-ChildItem -Path (Join-Path $srcSETUP 'Desktop Agent*.exe') -File -ErrorAction SilentlyContinue
                if ($desktopAgent) {
                    $agentDest = Join-Path $destCopy $desktopAgent.Name
                    if (-not (Test-Path $agentDest)) {
                        if (Test-Path $desktopAgent.FullName) { Copy-Item -Path $desktopAgent.FullName -Destination $agentDest -Force; Add-Status "Copying: DesktopAgent" $statusTextBox }
                        else { Add-Status "Error: Not found DesktopAgent source file" $statusTextBox ([System.Drawing.Color]::Red) }
                    }
                    else { Add-Status "Existed: DesktopAgent" $statusTextBox }
                }
                else { Add-Status "Error: Not found DesktopAgent source file" $statusTextBox ([System.Drawing.Color]::Red) }
            }
            else {
                $laptopAgent = Get-ChildItem -Path (Join-Path $srcSETUP 'Laptop Agent*.exe') -File -ErrorAction SilentlyContinue
                if ($laptopAgent) {
                    $agentDest = Join-Path $destCopy $laptopAgent.Name
                    if (-not (Test-Path $agentDest)) {
                        if (Test-Path $laptopAgent.FullName) { Copy-Item -Path $laptopAgent.FullName -Destination $agentDest -Force; Add-Status "Copying: Laptop Agent" $statusTextBox }
                        else { Add-Status "Error: Not found LaptopAgent source file" $statusTextBox ([System.Drawing.Color]::Red) }
                    }
                    else { Add-Status "Existed: Laptop Agent" $statusTextBox }
                }
                else { Add-Status "Error: Not found LaptopAgent source file" $statusTextBox ([System.Drawing.Color]::Red) }

                $mdmSource = Join-Path $srcSETUP "ManageEngine_MDMLaptopEnrollment"
                $mdmDest = Join-Path $destCopy "ManageEngine_MDMLaptopEnrollment"
                if (-not (Test-Path $mdmDest)) {
                    if (Test-Path $mdmSource) {
                        try {
                            $null = New-Item -Path $mdmDest -ItemType Directory -Force -ErrorAction Stop
                            Copy-Item -Path "$mdmSource\*" -Destination $mdmDest -Recurse -Force
                            Add-Status "Copying: ManageEngine" $statusTextBox
                        }
                        catch { Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red) }
                    }
                    else { Add-Status "Error: Not found ManageEngine source directory" $statusTextBox ([System.Drawing.Color]::Red) }
                }
                else { Add-Status "Existed: ManageEngine" $statusTextBox }
            }
        }
        else {
            Add-Status "Warning: Source path not found at $srcSETUP" $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        # Display pending list after copying ancillary files/folders
        if ($plan.Pending.Count -gt 0) {
            $pendingDisplays = $plan.Pending | ForEach-Object { 
                if ($_.task -eq 'uninstall') { "$($_.displayName) (Uninstall)" }
                else { $_.displayName }
            }
            Add-Status ("Pending: " + ($pendingDisplays -join ", ")) $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        if ($plan.Pending.Count -gt 0) {
            if (-not (Test-Path $srcSETUP)) { Add-Status "Error: Not found $srcSETUP" $statusTextBox ([System.Drawing.Color]::Red); return $false }
            Add-Status "Found $($plan.Pending.Count) software(s) to process" $statusTextBox
            if (-not (Test-Path $destSETUP)) { New-Item -Path $destSETUP -ItemType Directory -Force | Out-Null }
            $okCopy = Copy-SoftwareFilesSelective -DeviceType $DeviceType -Apps $plan.Pending -statusTextBox $statusTextBox -SourceSetupPath $srcSETUP
            if (-not $okCopy) { Add-Status "Error: Failed to copy installers" $statusTextBox ([System.Drawing.Color]::Red); return $false }
            $okInstall = Install-Software -deviceType $DeviceType -statusTextBox $statusTextBox -appsToInstall $plan.Pending -CleanupTemp:$CleanupTemp
            if (-not $okInstall) { Add-Status "Error: Some operations failed" $statusTextBox ([System.Drawing.Color]::Red); return $false }
            Add-Status "All software operations completed successfully" $statusTextBox
            return $true
        }
        else {
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


function Find-UsbSourcePath {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    
    # Get all file system drives
    $drives = Get-PSDrive -PSProvider FileSystem
    
    foreach ($drive in $drives) {
        # Check for SETUP folder at root
        $checkPath = Join-Path $drive.Root "SETUP"
        if (Test-Path $checkPath) {
            if ($statusTextBox) { Add-Status "Found installation source at: $checkPath" $statusTextBox ([System.Drawing.Color]::Green) }
            return $drive.Root
        }
    }
    
    if ($statusTextBox) { Add-Status "Could not auto-detect USB source. Using default configuration." $statusTextBox ([System.Drawing.Color]::Yellow) }
    return $null
}

Export-ModuleMember -Function Install-DriverExe, Show-InstallSoftwareDialog, Invoke-InstallSoftware, Test-OneDriveInstalled, Uninstall-OneDriveComplete, Install-Software, PlanSoftwareInstall, Test-AppInstalled, Copy-SoftwareFilesSelective, Find-UsbSourcePath