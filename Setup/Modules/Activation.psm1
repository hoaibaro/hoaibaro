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
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # Display current Windows version
        $currentWindowsVersion = Get-WindowsVersionShort
        Add-Status "Checking Activation Status of Windows..." $statusTextBox
        Add-Status "OS: $currentWindowsVersion" $statusTextBox

        $windowsStatus = & cscript //nologo "$env:windir\system32\slmgr.vbs" /dli
        $isWindowsActivated = $windowsStatus -match "License Status: Licensed"

        if ($isWindowsActivated) {
            Add-Status "Windows activated." $statusTextBox
            return
        }

        Add-Status "Windows not activated. Activating Windows 10 Pro..." $statusTextBox
        $command = "slmgr /ipk R84N4-RPC7Q-W8TKM-VM7Y4-7H66Y && slmgr /ato"

        # Create a process to run the command with elevated privileges
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-Command Start-Process cmd.exe -ArgumentList '/c $command' -Verb RunAs -WindowStyle Hidden"
        $psi.UseShellExecute = $true
        $psi.Verb = "runas"
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        # Start the process
        [System.Diagnostics.Process]::Start($psi)
    }
    catch {
        Add-Status "Error activating Windows: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-ActivateOffice2019 {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        Add-Status "Checking Activation Status of Office..." $statusTextBox
        # Check multiple possible Office paths
        $officePaths = @(
            "C:\Program Files\Microsoft Office\Office16\ospp.vbs",
            "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs",
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
            $officeStatus = & cscript //nologo "$officePath" /dstatus 2>&1

            # Check if already activated (multiple possible patterns)
            $isActivated = ($officeStatus -match "LICENSE STATUS:.*LICENSED") -or
            ($officeStatus -match "---LICENSED---") -or
            ($officeStatus -match "LICENSED")

            if ($isActivated) {
                Add-Status "Office activated." $statusTextBox
                return
            }
        }
        catch {
            Add-Status "Could not check activation status: $_" $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        Add-Status "Office not activated. Starting activate..." $statusTextBox
        # Install the product key
        try {
            & cscript //nologo "$officePath" /inpkey:Q2NKY-J42YJ-X2KVK-9Q9PT-MKP63 2>&1
        }
        catch {
            Add-Status "Error installing product key: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # Wait a moment for key installation to complete
        Start-Sleep -Seconds 2

        try {
            $activateResult = & cscript //nologo "$officePath" /act 2>&1

            if ($activateResult -match "successful" -or $activateResult -match "activated") {
                Add-Status "Office 2019 Pro Plus activated successfully!" $statusTextBox
            }
            else {
                Add-Status "Office activation completed. Result: $($activateResult -join ' ')" $statusTextBox
            }
        }
        catch {
            Add-Status "Error during activation: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # Check final status
        try {
            Start-Sleep -Seconds 3
        }
        catch {
            Add-Status "Could not verify final activation status: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
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
        $command = "sc config LicenseManager start= auto & net start LicenseManager & sc config wuauserv start= auto & net start wuauserv & changepk.exe /productkey VK7JG-NPHTM-C97JM-9MPGT-3V66T"

        # Create a process to run the command with elevated privileges
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-Command Start-Process cmd.exe -ArgumentList '/c $command' -Verb RunAs -WindowStyle Hidden"
        $psi.UseShellExecute = $true
        $psi.Verb = "runas"
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        # Start the process
        [System.Diagnostics.Process]::Start($psi)

        Add-Status "Starting upgrade process for $currentWindowsVersion to Pro." $statusTextBox
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
    $btnOffice = New-DynamicButton -text "Office2019ProPlus" -x 250 -y 50 -width 225 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
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
    param([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox)
    
    Add-Status "Starting Activation Configuration..." $statusTextBox
    Invoke-ActivateWindows10Pro -statusTextBox $statusTextBox
    Invoke-ActivateOffice2019 -statusTextBox $statusTextBox
    return $true
}

Export-ModuleMember -Function Get-WindowsVersionShort, Invoke-ActivateWindows10Pro, Invoke-ActivateOffice2019, Invoke-UpgradeWindowsHomeToPro, Invoke-ActivationDialog, Invoke-ActivateConfiguration
