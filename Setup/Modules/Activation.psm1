function Get-WindowsVersionShort {
    try {
        # Get Windows version info
        $osInfo = Get-WmiObject -Class Win32_OperatingSystem
        $windowsCaption = $osInfo.Caption
        $buildNumber = $osInfo.BuildNumber

        # Determine Windows version based on build number and caption
        if ($buildNumber -ge 22000) {
            # Windows 11
            if ($windowsCaption -match "Pro") {
                return "Win 11 Pro"
            }
            elseif ($windowsCaption -match "Home") {
                return "Win 11 Home"
            }
            elseif ($windowsCaption -match "Enterprise") {
                return "Win 11 Enterprise"
            }
            else {
                return "Win 11"
            }
        }
        elseif ($buildNumber -ge 10240) {
            # Windows 10
            if ($windowsCaption -match "Pro") {
                return "Win 10 Pro"
            }
            elseif ($windowsCaption -match "Home") {
                return "Win 10 Home"
            }
            elseif ($windowsCaption -match "Enterprise") {
                return "Win 10 Enterprise"
            }
            else {
                return "Win 10"
            }
        }
        else {
            # Older Windows versions
            return $windowsCaption
        }
    }
    catch {
        return "Unknown Windows Version"
    }
}

function Invoke-ActivateWindows10Pro {
    param([System.Windows.Forms.RichTextBox]$statusTextBox, [bool]$HasInternet = $true)
    try {
        # Display current Windows version
        $currentWindowsVersion = Get-WindowsVersionShort
        Add-Status "Checking Activation Status of Windows..." $statusTextBox
        Add-Status "OS: $currentWindowsVersion" $statusTextBox

        $windowsStatus = & cscript //nologo "$env:windir\system32\slmgr.vbs" /dli 2>&1 | Out-String
        $isWindowsActivated = $windowsStatus -match "License Status: Licensed"

        if ($isWindowsActivated) {
            Add-Status "Windows activated." $statusTextBox
            return
        }

        Add-Status "Windows not activated. Activating Windows 10 Pro..." $statusTextBox
        
        # Ensure Software Protection service is running
        if ((Get-Service "sppsvc" -ErrorAction SilentlyContinue).Status -ne "Running") {
            Start-Service "sppsvc" -ErrorAction SilentlyContinue
        }

        $key = $Global:config.windowsActivation.productKey
        
        # Install Key (works offline)
        Add-Status "Installing Product Key..." $statusTextBox
        $ipkResult = & cscript //nologo "$env:windir\system32\slmgr.vbs" /ipk $key 2>&1 | Out-String
        if ($ipkResult -match "successfully") {
            Add-Status "Product Key installed successfully." $statusTextBox
        }
        else {
            Add-Status "Key installation output: $ipkResult" $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        # Activate (requires Internet)
        if ($HasInternet) {
            Add-Status "Triggering Activation..." $statusTextBox
            $atoResult = & cscript //nologo "$env:windir\system32\slmgr.vbs" /ato 2>&1 | Out-String
            
            if ($atoResult -match "successfully") {
                Add-Status "Windows activated successfully!" $statusTextBox ([System.Drawing.Color]::Green)
            }
            else {
                Add-Status "Activation failed: $atoResult" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "No Internet: Key installed. Windows will auto-activate when online." $statusTextBox ([System.Drawing.Color]::Yellow)
        }
    }
    catch {
        Add-Status "Error activating Windows: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}




function Invoke-ActivateOffice2019 {
    param([System.Windows.Forms.RichTextBox]$statusTextBox, [bool]$HasInternet = $true)
    try {
        Add-Status "Checking Activation Status of Office..." $statusTextBox
        # Check multiple possible Office paths
        $officePaths = @(
            "C:\Program Files\Microsoft Office\Office16\ospp.vbs",
            "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs",
            "C:\Program Files\Microsoft Office\root\Office16\ospp.vbs",
            "C:\Program Files (x86)\Microsoft Office\root\Office16\ospp.vbs",
            "C:\Program Files\Microsoft Office\Office15\ospp.vbs",
            "C:\Program Files (x86)\Microsoft Office\Office15\ospp.vbs"
        )

        $officePath = $null
        foreach ($path in $officePaths) {
            if (Test-Path $path) {
                $officePath = $path
                break
            }
        }

        if (-not $officePath) {
            Add-Status "Office not found. Please install." $statusTextBox
            return
        }

        # Check current activation status
        try {
            $officeStatus = & cscript //nologo "$officePath" /dstatus 2>&1 | Out-String

            # Check if already activated (exclude UNLICENSED)
            $isActivated = ($officeStatus -match "---LICENSED---") -or
            ($officeStatus -match "LICENSE STATUS:\s*---LICENSED---") -or
            ($officeStatus -match "LICENSE STATUS:\s*LICENSED" -and $officeStatus -notmatch "UNLICENSED")

            if ($isActivated) {
                Add-Status "Office activated." $statusTextBox
                return
            }
        }
        catch {
            Add-Status "Could not check activation status: $_" $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        Add-Status "Office not activated. Starting activate..." $statusTextBox
        # Detect Office version and get matching key
        $officeKeyName = $null
        try {
            $dstatusOutput = & cscript //nologo "$officePath" /dstatus 2>&1 | Out-String
            if ($dstatusOutput -match "ProPlus") { $officeKeyName = "ProPlus2019" }
            elseif ($dstatusOutput -match "Standard") { $officeKeyName = "Standard2019" }
        }
        catch {}

        # Fallback: use version selected during install
        if (-not $officeKeyName -and $Global:SelectedOfficeVersion) {
            $selectedApp = $Global:config.software | Where-Object { $_.id -eq $Global:SelectedOfficeVersion }
            if ($selectedApp -and $selectedApp.activationKey) { $officeKeyName = $selectedApp.activationKey }
        }

        if (-not $officeKeyName) {
            Add-Status "Could not detect Office version. Using Standard2019 key as default." $statusTextBox ([System.Drawing.Color]::Yellow)
            $officeKeyName = "Standard2019"
        }

        $key = $Global:config.officeActivation.$officeKeyName
        if (-not $key) {
            Add-Status "No activation key found for $officeKeyName in config." $statusTextBox ([System.Drawing.Color]::Red)
            return
        }

        Add-Status "Office version: $officeKeyName" $statusTextBox
        # Install the product key
        try {
            $inpkeyResult = & cscript //nologo "$officePath" /inpkey:$key 2>&1 | Out-String
            if ($inpkeyResult -match "successful") {
                Add-Status "Office product key installed successfully." $statusTextBox
            }
            else {
                Add-Status "Key install output: $inpkeyResult" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        catch {
            Add-Status "Error installing product key: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # Wait a moment for key installation to complete
        Start-Sleep -Seconds 2

        # Activate (requires Internet)
        if ($HasInternet) {
            try {
                $activateResult = & cscript //nologo "$officePath" /act 2>&1 | Out-String

                if ($activateResult -match "successful" -or $activateResult -match "activated") {
                    Add-Status "Office activated successfully!" $statusTextBox ([System.Drawing.Color]::Green)
                }
                else {
                    Add-Status "Office activation result: $activateResult" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            catch {
                Add-Status "Error during activation: $_" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "No Internet: Key installed. Office will auto-activate when online." $statusTextBox ([System.Drawing.Color]::Yellow)
        }
    }
    catch {
        Add-Status "ERROR: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-UpgradeWindowsHomeToPro {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        Add-Status "Checking Windows version..." $statusTextBox

        # Get current Windows version using helper function
        $currentWindowsVersion = Get-WindowsVersionShort
        Add-Status "Current OS: $currentWindowsVersion" $statusTextBox

        # Check if already Pro
        if ($currentWindowsVersion -match "Pro") {
            Add-Status "Device is already running $currentWindowsVersion." $statusTextBox
            return
        }

        # Check if it's Home edition that can be upgraded
        if (-not ($currentWindowsVersion -match "Home")) {
            Add-Status "Device is not running Windows Home. Cannot upgrade to Pro using this method." $statusTextBox
            return
        }

        Add-Status "Upgrading $currentWindowsVersion to Pro..." $statusTextBox
        $key = $Global:config.windowsActivation.upgradeKey
        
        # Prepare commands
        $commands = @(
            "sc config LicenseManager start= auto",
            "net start LicenseManager",
            "sc config wuauserv start= auto",
            "net start wuauserv",
            "changepk.exe /productkey $key"
        )
        
        foreach ($cmd in $commands) {
            try {
                Add-Status "Executing: $cmd" $statusTextBox
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd" -WindowStyle Hidden -PassThru -Wait
                if ($process.ExitCode -eq 0) {
                    Add-Status "Command success." $statusTextBox
                }
                else {
                    Add-Status "Command exit code: $($process.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            catch {
                Add-Status "Command failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }

        Add-Status "Upgrade process initiated. System may restart." $statusTextBox
    }
    catch {
        Add-Status "Error upgrading Windows: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-ActivationDialog {
    Hide-MainMenu
    # Create activation form
    $activateForm = New-Object System.Windows.Forms.Form
    $activateForm.Text = "Activation Options"
    $activateForm.Size = New-Object System.Drawing.Size(500, 400)
    $activateForm.StartPosition = "CenterScreen"
    $activateForm.BackColor = [System.Drawing.Color]::Black
    $activateForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $activateForm.MaximizeBox = $false
    $activateForm.MinimizeBox = $false

    # Apply gradient background using global function
    Add-GradientBackground -form $activateForm

    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "ACTIVATION OPTIONS"
    $titleLabel.Location = New-Object System.Drawing.Point(120, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(250, 40)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $activateForm.Controls.Add($titleLabel)

    # Add animation to the title
    Add-TitleAnimation -titleLabel $titleLabel

    # Status text box
    $statusTextBox = New-Object System.Windows.Forms.RichTextBox
    $statusTextBox.Multiline = $true
    $statusTextBox.ScrollBars = "Vertical"
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 150)
    $statusTextBox.Size = New-Object System.Drawing.Size(465, 200)
    $statusTextBox.BackColor = [System.Drawing.Color]::Black
    $statusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusTextBox.ReadOnly = $true
    $statusTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $statusTextBox.Text = "Status messages will appear here..."
    $activateForm.Controls.Add($statusTextBox)

    # Activation buttons
    $btnWin10Pro = New-DynamicButton -text "Windows Pro" -x 10 -y 50 -width 235 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        Invoke-ActivateWindows10Pro -statusTextBox $statusTextBox
    }
    $activateForm.Controls.Add($btnWin10Pro)

    # Add button to activate Office 2019
    $btnOffice = New-DynamicButton -text "Office 2019" -x 250 -y 50 -width 225 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        Invoke-ActivateOffice2019 -statusTextBox $statusTextBox
    }
    $activateForm.Controls.Add($btnOffice)

    # Add button to upgrade Windows Home to Pro
    $btnWin10Home = New-DynamicButton -text "Upgrade Home to Pro" -x 10 -y 100 -width 465 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        Invoke-UpgradeWindowsHomeToPro -statusTextBox $statusTextBox
    }
    $activateForm.Controls.Add($btnWin10Home)

    $activateForm.KeyPreview = $true
    $activateForm.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $activateForm.Close() } })

    # When the form is closed, show the main menu again
    $activateForm.Add_FormClosed({
            Show-MainMenu
        })

    # Show the form
    $activateForm.ShowDialog()
}

function Invoke-ActivateConfiguration {
    param([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox, [bool]$HasInternet = $true)
    
    Add-Status "Starting Activation Configuration..." $statusTextBox
    Invoke-ActivateWindows10Pro -statusTextBox $statusTextBox -HasInternet $HasInternet
    Invoke-ActivateOffice2019 -statusTextBox $statusTextBox -HasInternet $HasInternet
    return $true
}

Export-ModuleMember -Function Get-WindowsVersionShort, Invoke-ActivateWindows10Pro, Invoke-ActivateOffice2019, Invoke-UpgradeWindowsHomeToPro, Invoke-ActivationDialog, Invoke-ActivateConfiguration
