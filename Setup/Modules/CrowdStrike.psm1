# [10] CrowdStrike Functions
function Invoke-CrowdStrikeDialog {
    Hide-MainMenu 
    # Create CrowdStrike form with modern design
    $crowdStrikeForm = New-Object System.Windows.Forms.Form
    $crowdStrikeForm.Text = "BAOPROVIP - CROWDSTRIKE MANAGEMENT"
    $crowdStrikeForm.Size = New-Object System.Drawing.Size(665, 550)
    $crowdStrikeForm.MinimumSize = New-Object System.Drawing.Size(665, 550)
    $crowdStrikeForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $crowdStrikeForm.BackColor = [System.Drawing.Color]::Black
    $crowdStrikeForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
    $crowdStrikeForm.MaximizeBox = $true

    # Apply gradient background using global function
    Add-GradientBackground -form $crowdStrikeForm

    # Title label with animation
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "CROWDSTRIKE SECURITY MANAGEMENT"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 18, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.Size = New-Object System.Drawing.Size($crowdStrikeForm.ClientSize.Width, 50)
    $titleLabel.Location = New-Object System.Drawing.Point(0, 20)
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $titleLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $crowdStrikeForm.Controls.Add($titleLabel)

    # Add title animation
    Add-TitleAnimation -titleLabel $titleLabel

    # Department selection section
    $deptLabel = New-Object System.Windows.Forms.Label
    $deptLabel.Text = "SELECT DEPARTMENT:"
    $deptLabel.Location = New-Object System.Drawing.Point(10, 90)
    $deptLabel.Size = New-Object System.Drawing.Size(200, 25)
    $deptLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $deptLabel.ForeColor = [System.Drawing.Color]::White
    $deptLabel.BackColor = [System.Drawing.Color]::Transparent
    $crowdStrikeForm.Controls.Add($deptLabel)

    # Department dropdown
    $deptComboBox = New-Object System.Windows.Forms.ComboBox
    $deptComboBox.Location = New-Object System.Drawing.Point(10, 120)
    $deptComboBox.Size = New-Object System.Drawing.Size(310, 25)
    $deptComboBox.Font = New-Object System.Drawing.Font("Arial", 10)
    $deptComboBox.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $deptComboBox.ForeColor = [System.Drawing.Color]::White
    $deptComboBox.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $deptComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

    # Add departments (organized by security level)
    $departments = @(
        "",
        "------------ EDR (High Security) --------------",
        "Board-of-Directors",
        "Legal-Compliance",
        "Accounting",
        "HR-Admin",
        "Quality-of-Service",
        "Technical-Operation",
        "IT-Administration",
        "Account-System-Management",
        "Core-System",
        "Database-Management",
        "Customer-Service",
        "Digi-Gift",
        "Cyber-Security",
        "Fee-Control",
        "",
        "----- DEV (AV default, EDR for senior up) -----",
        "Product-Management",
        "System-Integration",
        "Network-Development",
        "Web",
        "Mobile-App",
        "Payoo-X-and-Biz-Solutions",
        "Payoo-Plus-Digital-Transformation",
        "",
        "---------- AV (Standard Security) ------------",
        "Marketing",
        "HN-Branch",
        "Data-Exchange",
        "Service-Operation-Division",
        "Training",
        "Project-Strategy-Division",
        "Financial-Service-Project",
        "Bill-Payment-Project",
        "Business-Development",
        "E-Commerce",
        "Omni",
        "Paycode",
        "Quality-Control",
        "Business-Analysis",
        "NTT",
        "Collaborator"
    )

    foreach ($dept in $departments) { $deptComboBox.Items.Add($dept) }

    # Set default to first actual department
    $deptComboBox.SelectedIndex = 1

    # Department change handler for smart recommendations
    $deptComboBox.Add_SelectedIndexChanged({
            $selectedDept = $deptComboBox.SelectedItem.ToString()

            # Skip section headers and empty lines
            if ($selectedDept -like "---*" -or $selectedDept -eq "") {
                $recommendLabel.Text = "Select department first"
                $recommendLabel.Location = New-Object System.Drawing.Point(400, 90)
                $recommendLabel.Size = New-Object System.Drawing.Size(200, 25)
                $recommendLabel.Font = New-Object System.Drawing.Font("Arial", 12)
                $recommendLabel.ForeColor = [System.Drawing.Color]::Gray
                return
            }

            # Get recommendation based on department
            $recommendation = Get-DepartmentRecommendation -Department $selectedDept
            $recommendLabel.Text = "Recommended: $($recommendation.Type)"
            $recommendLabel.Location = New-Object System.Drawing.Point(400, 90)
            $recommendLabel.Size = New-Object System.Drawing.Size(200, 25)
            $recommendLabel.Font = New-Object System.Drawing.Font("Arial", 12)
            $recommendLabel.ForeColor = $recommendation.Color

            # Auto-select recommended type
            if ($recommendation.Type -eq "EDR") { $radioEDR.Checked = $true } else { $radioAV.Checked = $true }

            # Update status text with recommendation reason
            $statusTextBox.Text = "Department: $selectedDept`nRecommendation: $($recommendation.Type) - $($recommendation.Reason)"
        })

    $crowdStrikeForm.Controls.Add($deptComboBox)

    # Installation type section
    $typeLabel = New-Object System.Windows.Forms.Label
    $typeLabel.Text = "TYPE:"
    $typeLabel.Location = New-Object System.Drawing.Point(330, 90)
    $typeLabel.Size = New-Object System.Drawing.Size(60, 25)
    $typeLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $typeLabel.ForeColor = [System.Drawing.Color]::White
    $typeLabel.BackColor = [System.Drawing.Color]::Transparent
    $crowdStrikeForm.Controls.Add($typeLabel)

    # Installation type radio buttons
    $radioAV = New-Object System.Windows.Forms.RadioButton
    $radioAV.Text = "AV (Antivirus)"
    $radioAV.Location = New-Object System.Drawing.Point(350, 120)
    $radioAV.Size = New-Object System.Drawing.Size(120, 25)
    $radioAV.Font = New-Object System.Drawing.Font("Arial", 10)
    $radioAV.ForeColor = [System.Drawing.Color]::White
    $radioAV.BackColor = [System.Drawing.Color]::Transparent
    $radioAV.Checked = $true
    $crowdStrikeForm.Controls.Add($radioAV)

    $radioEDR = New-Object System.Windows.Forms.RadioButton
    $radioEDR.Text = "EDR (Enhanced Security)"
    $radioEDR.Location = New-Object System.Drawing.Point(470, 120)
    $radioEDR.Size = New-Object System.Drawing.Size(200, 25)
    $radioEDR.Font = New-Object System.Drawing.Font("Arial", 10)
    $radioEDR.ForeColor = [System.Drawing.Color]::White
    $radioEDR.BackColor = [System.Drawing.Color]::Transparent
    $radioEDR.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
    $crowdStrikeForm.Controls.Add($radioEDR)

    # Smart recommendation label
    $recommendLabel = New-Object System.Windows.Forms.Label
    $recommendLabel.Text = "Recommended: EDR"
    $recommendLabel.Location = New-Object System.Drawing.Point(400, 90)
    $recommendLabel.Size = New-Object System.Drawing.Size(200, 25)
    $recommendLabel.Font = New-Object System.Drawing.Font("Arial", 12)
    $recommendLabel.ForeColor = [System.Drawing.Color]::Orange
    $recommendLabel.BackColor = [System.Drawing.Color]::Transparent
    $crowdStrikeForm.Controls.Add($recommendLabel)


    # Action buttons (centered layout without uninstall)
    $btnInstall = New-DynamicButton -text "Install" -x 10 -y 180 -width 150 -height 50 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        $selectedDept = $deptComboBox.SelectedItem.ToString()

        # Filter out section headers and empty lines
        if ($null -eq $selectedDept -or $selectedDept -eq "" -or $selectedDept -like "---*") {
            [System.Windows.Forms.MessageBox]::Show(
                "Please select a valid department (not a section header).",
                "Invalid Selection",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        $installType = if ($radioEDR.Checked) { "EDR" } else { "AV" }

        try { Invoke-InstallCrowdStrike -statusTextBox $statusTextBox -Department $selectedDept -InstallType $installType }
        catch { Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red) }
    }
    $crowdStrikeForm.Controls.Add($btnInstall)

    # Status button
    $btnStatus = New-DynamicButton -text "Status" -x 170 -y 180 -width 150 -height 50 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0))  -clickAction { Invoke-CheckCrowdStrikeStatus -statusTextBox $statusTextBox }
    $crowdStrikeForm.Controls.Add($btnStatus)

    # Change GroupTag button
    $btnCrowdStrikeTag = New-DynamicButton -text "Change GroupTag" -x 330 -y 180 -width 150 -height 50 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction { Invoke-CrowdStrikeGroupTagDialog -Departments (@($deptComboBox.Items | ForEach-Object { $_.ToString() })) }
    $crowdStrikeForm.Controls.Add($btnCrowdStrikeTag)

    # Uninstall button
    $btnUninstall = New-DynamicButton -text "Uninstall" -x 490 -y 180 -width 150 -height 50 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "B?n c� mu?n m? c?a s? CrowdStrike Falcon Sensor Setup �? g? c�i �?t?",
            "X�c nh?n",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            Start-CrowdStrikeMaintenanceUI -statusTextBox $statusTextBox
        }
    }
    $crowdStrikeForm.Controls.Add($btnUninstall)

    # Status text box
    $statusTextBox = New-Object System.Windows.Forms.RichTextBox
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 280)
    $statusTextBox.Size = New-Object System.Drawing.Size(630, 220)
    $statusTextBox.BackColor = [System.Drawing.Color]::Black
    $statusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusTextBox.ReadOnly = $true
    $statusTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $statusTextBox.Text = "Ready to manage CrowdStrike installation...`n`nSelect department and installation type, then click INSTALL CROWDSTRIKE to begin."
    $statusTextBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $crowdStrikeForm.Controls.Add($statusTextBox)

    # Add escape handler with explicit KeyPreview
    $crowdStrikeForm.KeyPreview = $true
    $crowdStrikeForm.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $crowdStrikeForm.Close() } })

    # When the form is closed, show the main menu again
    $crowdStrikeForm.Add_FormClosed({ Show-MainMenu })

    # Trigger initial recommendation for first actual department selection
    $crowdStrikeForm.Add_Shown({
            # Trigger the department change event for initial recommendation
            if ($deptComboBox.Items.Count -gt 1) {
                $deptComboBox.SelectedIndex = 1  # Select first actual department
                # Manually trigger the event
                $selectedDept = $deptComboBox.SelectedItem.ToString()
                if (-not ($selectedDept -like "---*" -or $selectedDept -eq "")) {
                    $recommendation = Get-DepartmentRecommendation -Department $selectedDept
                    $recommendLabel.Text = "Recommended: $($recommendation.Type)"
                    $recommendLabel.ForeColor = $recommendation.Color
                    if ($recommendation.Type -eq "EDR") { $radioEDR.Checked = $true }
                    else { $radioAV.Checked = $true }
                    $statusTextBox.Text = "Department: $selectedDept`nRecommendation: $($recommendation.Type) - $($recommendation.Reason)`n`nInstallation will follow current policy automatically."
                }
            }
        })
    # Show the form
    $crowdStrikeForm.ShowDialog()
}

# [10.1] CrowdStrike Installation Funtions
function Invoke-InstallCrowdStrike {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox, [string]$Department, [string]$InstallType)
    # Ensure global install info object has properties before assignment
    if (-not $Global:CrowdStrikeInstallInfo) { $Global:CrowdStrikeInstallInfo = [pscustomobject]@{} }
    $Global:CrowdStrikeInstallInfo | Add-Member -NotePropertyName Department -NotePropertyValue $Department -Force
    $Global:CrowdStrikeInstallInfo | Add-Member -NotePropertyName InstallType -NotePropertyValue $InstallType -Force
    try {
        $statusTextBox.Clear()
        Add-Status "=== CROWDSTRIKE INSTALLATION STARTED ===" $statusTextBox ([System.Drawing.Color]::Cyan)
        Add-Status "Department: $Department" $statusTextBox ([System.Drawing.Color]::White)
        Add-Status "Installation Type: $InstallType (Policy-based)" $statusTextBox ([System.Drawing.Color]::White)

        # Check if CrowdStrike is already installed
        Add-Status "1. Checking existing installation..." $statusTextBox ([System.Drawing.Color]::Yellow)
        $csagentService = Get-Service -Name "csagent" -ErrorAction SilentlyContinue

        if ($csagentService) {
            Add-Status "   ? CrowdStrike is already installed!" $statusTextBox ([System.Drawing.Color]::Yellow)
            Add-Status "   Service Status: $($csagentService.Status)" $statusTextBox ([System.Drawing.Color]::Gray)

            $confirmResult = [System.Windows.Forms.MessageBox]::Show(
                "CrowdStrike is already installed. Do you want to reinstall?",
                "CrowdStrike Already Installed",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($confirmResult -eq [System.Windows.Forms.DialogResult]::No) { Add-Status "Installation cancelled by user." $statusTextBox ([System.Drawing.Color]::Yellow) ; return }

            Add-Status "   Proceeding with reinstallation..." $statusTextBox ([System.Drawing.Color]::Yellow)
        }
        else {
            Add-Status "   ? No existing installation found" $statusTextBox ([System.Drawing.Color]::Green)
        }

        # Check for installer script
        Add-Status "2. Locating CrowdStrike installer..." $statusTextBox ([System.Drawing.Color]::Yellow)
        $scriptPath = Join-Path $global:destCopy "CrowdStrike\core\auto_installer_integrated.ps1"

        if (-not (Test-Path $scriptPath)) {
            Add-Status "   ? CrowdStrike installer script not found!" $statusTextBox ([System.Drawing.Color]::Red)
            Add-Status "   Expected path: $scriptPath" $statusTextBox ([System.Drawing.Color]::Gray)
            Add-Status "   Please ensure CrowdStrike installer is properly installed." $statusTextBox ([System.Drawing.Color]::Red)
            return
        }

        Add-Status "   ? Installer script found" $statusTextBox ([System.Drawing.Color]::Green)

        # Check for installer executable
        $installerPath = Join-Path $global:destCopy "CrowdStrike\core\FalconSensor_Windows.exe"

        if (-not (Test-Path $installerPath)) {
            Add-Status "   ? CrowdStrike installer executable not found!" $statusTextBox ([System.Drawing.Color]::Red)
            Add-Status "   Expected path: $installerPath" $statusTextBox ([System.Drawing.Color]::Gray)
            Add-Status "   Please ensure FalconSensor_Windows.exe is in the core directory." $statusTextBox ([System.Drawing.Color]::Red)
            return
        }

        Add-Status "   ? Installer executable found" $statusTextBox ([System.Drawing.Color]::Green)

        # Prepare installation command
        Add-Status "3. Preparing installation..." $statusTextBox ([System.Drawing.Color]::Yellow)
        $psArgs = @(
            "-ExecutionPolicy", "Bypass",
            "-NoProfile",
            "-File", "`"$scriptPath`"",
            "-Department", "`"$Department`"",
            "-InstallType", "`"$InstallType`"",
            "-Silent"
        )

        Add-Status "   Command: powershell.exe $($psArgs -join ' ')" $statusTextBox ([System.Drawing.Color]::Gray)

        # Start installation
        Add-Status "4. Starting CrowdStrike installation..." $statusTextBox ([System.Drawing.Color]::Yellow)
        $startTime = Get-Date
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -Wait -PassThru -WindowStyle Hidden
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes

        Add-Status "   Duration: $([math]::Round($duration, 2)) minutes" $statusTextBox ([System.Drawing.Color]::Gray)
        Add-Status "   Exit Code: $($process.ExitCode)" $statusTextBox ([System.Drawing.Color]::Gray)

        if ($process.ExitCode -eq 0) {
            Add-Status "   ? Installation completed successfully!" $statusTextBox ([System.Drawing.Color]::Green)
            # L�u persistent v�o Registry cho l?n ki?m tra sau
            try {
                $regPath = "HKLM:\SOFTWARE\BAOPROVIP\CrowdStrike"
                if (-not (Test-Path $regPath)) {
                    New-Item -Path $regPath -Force | Out-Null
                }
                New-ItemProperty -Path $regPath -Name "Department" -Value $Department -PropertyType String -Force | Out-Null
                New-ItemProperty -Path $regPath -Name "InstallType" -Value $InstallType -PropertyType String -Force | Out-Null
                Add-Status "   ? Saved assignment to registry: $regPath" $statusTextBox ([System.Drawing.Color]::Green)
            }
            catch {
                Add-Status "   ? Could not save assignment to registry: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Yellow)
            }

            # Verify installation
            Add-Status "5. Verifying installation..." $statusTextBox ([System.Drawing.Color]::Yellow)
            Start-Sleep -Seconds 3

            $newService = Get-Service -Name "csagent" -ErrorAction SilentlyContinue
            if ($newService -and $newService.Status -eq "Running") {
                Add-Status "   ? CrowdStrike service is running!" $statusTextBox ([System.Drawing.Color]::Green)
                Add-Status "   Service Name: $($newService.DisplayName)" $statusTextBox ([System.Drawing.Color]::Gray)
            }
            else { Add-Status "   ? Service verification failed" $statusTextBox ([System.Drawing.Color]::Yellow)
                Add-Status "   The installation may need time to complete" $statusTextBox ([System.Drawing.Color]::Yellow)
            }

            # Cleanup only after successful installation
            try {
                $csDownloadsPath = Join-Path $env:USERPROFILE "Downloads\CrowdStrike"
                if (Test-Path -LiteralPath $csDownloadsPath -PathType Container) {
                    Remove-Item -LiteralPath $csDownloadsPath -Recurse -Force -ErrorAction Stop
                    Add-Status "   ? Cleaned up CrowdStrike folder from Downloads." $statusTextBox ([System.Drawing.Color]::Green)
                }
            }
            catch {
                Add-Status "   ? Could not remove CrowdStrike folder: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Yellow)
            }

            Add-Status "=== INSTALLATION SUCCESSFUL ===" $statusTextBox ([System.Drawing.Color]::Green)
        }
        else { Add-Status "   ? Installation failed!" $statusTextBox ([System.Drawing.Color]::Red)
            Add-Status "   Please check the log file: C:\Temp\FalconInstall.log" $statusTextBox ([System.Drawing.Color]::Yellow)
        }
    }
    catch { Add-Status "Error during CrowdStrike installation: $_" $statusTextBox ([System.Drawing.Color]::Red)
        Add-Status "Please check the log file: C:\Temp\FalconInstall.log" $statusTextBox ([System.Drawing.Color]::Yellow)
    }
}

function Get-DepartmentRecommendation {
    param ([string]$Department)
    # EDR Departments
    $edrDepartments = @(
        "Board-of-Directors", "Legal-Compliance", "Accounting", "HR-Admin",
        "Quality-of-Service", "Technical-Operation", "IT-Administration",
        "Account-System-Management", "Core-System", "Database-Management",
        "Customer-Service", "Digi-Gift", "Cyber-Security", "Fee-Control"
    )

    # DEV Departments (AV default, EDR for senior)
    $devDepartments = @(
        "Product-Management", "System-Integration", "Network-Development",
        "Web", "Mobile-App", "Payoo-X-and-Biz-Solutions",
        "Payoo-Plus-Digital-Transformation"
    )

    if ($edrDepartments -contains $Department) {
        return @{
            Type   = "EDR"
            Color  = [System.Drawing.Color]::Orange
            Reason = "High security department"
        }
    }
    elseif ($devDepartments -contains $Department) {
        return @{
            Type   = "AV"
            Color  = [System.Drawing.Color]::Cyan
            Reason = "DEV department (EDR for senior positions)"
        }
    }
    else {
        return @{
            Type   = "AV"
            Color  = [System.Drawing.Color]::Lime
            Reason = "Standard department"
        }
    }
}

# [10.2] CrowdStrike Status Functions
function Get-CrowdStrikeAssignment {
    try {
        $regPath = "HKLM:\SOFTWARE\BAOPROVIP\CrowdStrike"
        if (Test-Path $regPath) {
            $p = Get-ItemProperty $regPath -ErrorAction Stop
            $dept = $p.Department
            $type = $p.InstallType
            if ($dept -or $type) {
                return @{
                    Department = $dept
                    InstallType = $type
                    Source     = "Registry"
                }
            }
        }
    } catch {
        Add-Status "Error reading assignment registry: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Yellow)
    }

    # NEW: c? g?ng �?c t? CSSensorSettings.exe (n?u c�)
    try {
        $exePath = "C:\Program Files\CrowdStrike\CSSensorSettings.exe"
        if (Test-Path $exePath) {
            # Nhi?u b?n h? tr? "show" ho?c "get". Th? "show" tr�?c, r?i fallback "get"
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $exePath
            $psi.Arguments = "show --grouping-tags"
            $psi.UseShellExecute = $false
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.CreateNoWindow = $true

            $p = New-Object System.Diagnostics.Process
            $p.StartInfo = $psi
            $null = $p.Start()
            $out1 = $p.StandardOutput.ReadToEnd()
            $p.WaitForExit()
            
            $output = $out1
            if ([string]::IsNullOrWhiteSpace($out1) -and $p.ExitCode -ne 0) {
                # Fallback: d�ng "get --grouping-tags"
                $psi.Arguments = "get --grouping-tags"
                $p = New-Object System.Diagnostics.Process
                $p.StartInfo = $psi
                $null = $p.Start()
                $out2 = $p.StandardOutput.ReadToEnd()
                $p.WaitForExit()
                $output = $out2
            }

            if ($output) {
                # Parse ch?c ch?n d?ng Grouping Tags
                $lines = ($output -split "`r?`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

                # �u ti�n d?ng c� "Grouping Tags:"
                $line = $lines | Where-Object { $_ -match '^(?i)\s*Grouping\s*Tags\s*:' } | Select-Object -First 1

                # Fallback: d?ng c� "Tags:" (m?t s? phi�n b?n c� th? �?i nh?n)
                if (-not $line) {
                    $line = $lines | Where-Object { $_ -match '^(?i)\s*Tags\s*:' } | Select-Object -First 1
                }

                # Fallback cu?i: t?m d?ng c� v? ch? ch?a danh s�ch tag (ch?a d?u ph?y ho?c kho?ng tr?ng ph�n t�ch, nh�ng KH�NG ch?a �Tool�, �Version�, �CrowdStrike�)
                if (-not $line) {
                    $line = $lines |
                        Where-Object {
                            ($_ -match ',') -or ($_ -match '\s+') # c� ph�n t�ch
                        } |
                        Where-Object {
                            $_ -notmatch '(?i)crowdstrike|sensor|settings|tool|version|copyright'
                        } |
                        Select-Object -First 1
                }

                # L?y ph?n sau d?u �:�, n?u c�; n?u kh�ng c� ":" th? l?y nguy�n d?ng
                $rawTags = if ($line -match ':(.*)$') { $Matches[1].Trim() } else { $line }

                # Chu?n ho� v� t�ch tags
                $tags = $rawTags -split '\s*,\s*'
                $tags = $tags | Where-Object { $_ -and ($_ -notmatch '^(?i)(crowdstrike.*|sensor|settings|tool|version.*)$') }

                # Suy ra InstallType v� Department
                $installType = $null
                if ($tags | Where-Object { $_ -match '^(?i)EDR$' }) { $installType = 'EDR' }
                elseif ($tags | Where-Object { $_ -match '^(?i)AV$' }) { $installType = 'AV' }

                # Department: l?y tag kh�c AV/EDR �?u ti�n
                $department = ($tags | Where-Object { $_ -notmatch '^(?i:AV|EDR)$' } | Select-Object -First 1)

                if ($department -or $installType) {
                    return @{
                        Department  = $department
                        InstallType = $installType
                        Source      = "CSSensorSettings"
                    }
                }

                try {
                    $regPath = "HKLM:\SOFTWARE\BAOPROVIP\CrowdStrike"
                    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
                    if ($department)  { New-ItemProperty -Path $regPath -Name "Department"  -Value $department  -PropertyType String -Force | Out-Null }
                    if ($installType) { New-ItemProperty -Path $regPath -Name "InstallType" -Value $installType -PropertyType String -Force | Out-Null }
                } catch {}
            }
        }
    } catch {
        # B? qua: nhi?u b?n c� th? kh�ng h? tr? get/show m� kh�ng c?n token
    }

    # Fallback: th�ng tin l�u trong phi�n hi?n t?i (n?u c�)
    if ($global:CrowdStrikeInstallInfo -and ($global:CrowdStrikeInstallInfo.Department -or $global:CrowdStrikeInstallInfo.InstallType)) {
        return @{
            Department = $global:CrowdStrikeInstallInfo.Department
            InstallType = $global:CrowdStrikeInstallInfo.InstallType
            Source     = "Session"
        }
    }
    return $null
}

function Set-CrowdStrikeGroupingTag {
    param([Parameter(Mandatory = $true)][string]$Tag, [Parameter(Mandatory = $true)][string]$Token, [System.Windows.Forms.RichTextBox]$StatusTextBox)
    try {
        # Ensure we�re elevated
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            if ($StatusTextBox) { Add-Status "ERROR: This operation requires Administrator privileges." $StatusTextBox ([System.Drawing.Color]::Red) }
            return $false
        }

        # CSSensorSettings path
        $exePath = "C:\Program Files\CrowdStrike\CSSensorSettings.exe"
        if (-not (Test-Path $exePath)) {
            if ($StatusTextBox) { Add-Status "ERROR: CSSensorSettings.exe not found at '$exePath'." $StatusTextBox ([System.Drawing.Color]::Red) }
            return $false
        }

        if ($StatusTextBox) { Add-Status "Running: CSSensorSettings.exe set --grouping-tags `"$Tag`"" $StatusTextBox }

        # Prepare process with redirected stdio so we can feed the maintenance token
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $exePath
        $psi.Arguments = "set --grouping-tags `"$Tag`""
        $psi.UseShellExecute = $false
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        # Do NOT set Verb=runas when UseShellExecute=$false

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi

        $null = $proc.Start()

        # Feed maintenance token (followed by newline)
        $proc.StandardInput.WriteLine($Token)
        $proc.StandardInput.Flush()
        $proc.StandardInput.Close()

        # Read output/error
        $stdOut = $proc.StandardOutput.ReadToEnd()
        $stdErr = $proc.StandardError.ReadToEnd()

        $proc.WaitForExit()
        $exitCode = $proc.ExitCode

        if ($stdOut) { if ($StatusTextBox) { Add-Status ($stdOut.Trim()) $StatusTextBox } }
        if ($stdErr) { if ($StatusTextBox) { Add-Status ("[stderr] " + $stdErr.Trim()) $StatusTextBox ([System.Drawing.Color]::Yellow) } }

        if ($exitCode -eq 0) {
            if ($StatusTextBox) { Add-Status "CrowdStrike grouping tag updated successfully." $StatusTextBox }
            return $true
        }
        else {
            if ($StatusTextBox) { Add-Status "ERROR: CSSensorSettings exited with code $exitCode." $StatusTextBox ([System.Drawing.Color]::Red) }
            return $false
        }
    }
    catch {
        if ($StatusTextBox) { Add-Status ("ERROR: " + $_.Exception.Message) $StatusTextBox ([System.Drawing.Color]::Red) }
        return $false
    }
}

function Invoke-CheckCrowdStrikeStatus {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        $statusTextBox.Clear()
        Add-Status "CROWDSTRIKE STATUS CHECK" $statusTextBox ([System.Drawing.Color]::Cyan)

        # 1. Service Status (CRITICAL)
        Add-Status "1. Service Status:" $statusTextBox ([System.Drawing.Color]::White)
        $csagentService = Get-Service -Name "csagent" -ErrorAction SilentlyContinue

        if ($csagentService) {
            $statusColor = if ($csagentService.Status -eq "Running") { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
            Add-Status "   ? CrowdStrike Falcon: $($csagentService.Status)" $statusTextBox $statusColor
        }
        else { Add-Status "   ? CrowdStrike not installed!" $statusTextBox ([System.Drawing.Color]::Red); return }

        # 2. Department Assignment (IMPORTANT)
        Add-Status "2. Department Assignment:" $statusTextBox ([System.Drawing.Color]::White)

        $assign = Get-CrowdStrikeAssignment
        if ($assign) {
            if ($assign.Department) { Add-Status "   ? Department: $($assign.Department) ($($assign.Source))" $statusTextBox ([System.Drawing.Color]::Green) }
            if ($assign.InstallType) { Add-Status "   ? Installation Type: $($assign.InstallType) ($($assign.Source))" $statusTextBox ([System.Drawing.Color]::Green) }
        } else {
            Add-Status "   ? Assignment: Unknown (not configured or not yet synced)" $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        # 3. Protection Status (CRITICAL)
        Add-Status "3. Protection Status:" $statusTextBox ([System.Drawing.Color]::White)

        # Check key processes
        $criticalProcesses = @("CSFalconService", "CSFalconContainer")
        $runningProcesses = Get-Process | Where-Object { $criticalProcesses -contains $_.ProcessName } -ErrorAction SilentlyContinue

        if ($runningProcesses) { Add-Status "   ? Protection active ($($runningProcesses.Count) processes)" $statusTextBox ([System.Drawing.Color]::Green) }
        else { Add-Status "   ? Protection processes not detected" $statusTextBox ([System.Drawing.Color]::Yellow) }

        # Check installation integrity
        $installPath = "${env:ProgramFiles}\CrowdStrike"
        if (Test-Path $installPath) {
            $keyFiles = @("CSFalconService.exe", "SystemTray")
            $foundFiles = $keyFiles | Where-Object { Test-Path (Join-Path $installPath $_) }
            if ($foundFiles.Count -eq $keyFiles.Count) { Add-Status "   ? Installation integrity: OK" $statusTextBox ([System.Drawing.Color]::Green) }
            else { Add-Status "   ? Installation may be incomplete" $statusTextBox ([System.Drawing.Color]::Yellow) }
        }
        else { Add-Status "   ? Installation directory not found" $statusTextBox ([System.Drawing.Color]::Red) }

        # 4. Cloud Connectivity (IMPORTANT)
        Add-Status "4. Cloud Connectivity:" $statusTextBox ([System.Drawing.Color]::White)
        try { $testResult = Test-NetConnection -ComputerName "ts01-b.cloudsink.net" -Port 443 -InformationLevel Quiet -ErrorAction SilentlyContinue
            if ($testResult) { Add-Status "   ? CrowdStrike cloud: Connected" $statusTextBox ([System.Drawing.Color]::Green) }
            else { Add-Status "   ? CrowdStrike cloud: Disconnected" $statusTextBox ([System.Drawing.Color]::Yellow) }
        }
        catch { Add-Status "   ? Could not test connectivity" $statusTextBox ([System.Drawing.Color]::Yellow) }

        # 5. Overall Status (SUMMARY)
        $issues = @()
        $overallStatus = "HEALTHY"
        $statusColor = [System.Drawing.Color]::Green

        # Critical checks
        if (-not $csagentService -or $csagentService.Status -ne "Running") {
            $issues += "Service not running"
            $overallStatus = "CRITICAL"
            $statusColor = [System.Drawing.Color]::Red
        }

        if (-not $runningProcesses) { $issues += "Protection processes missing"
            if ($overallStatus -ne "CRITICAL") { $overallStatus = "WARNING"
                $statusColor = [System.Drawing.Color]::Yellow
            }
        }

        if (-not $global:CrowdStrikeInstallInfo.Department) { $issues += "No department assignment"
            if ($overallStatus -eq "HEALTHY") { $overallStatus = "WARNING"
                $statusColor = [System.Drawing.Color]::Yellow
            }
        }

        Add-Status "   Status: $overallStatus" $statusTextBox $statusColor

        if ($overallStatus -eq "HEALTHY") { Add-Status "   ? CrowdStrike is properly installed and protected" $statusTextBox ([System.Drawing.Color]::Green) }
        else { Add-Status "   Issues found: $issues" $statusTextBox ([System.Drawing.Color]::Yellow) }
    }
    catch { Add-Status "Error checking CrowdStrike status: $_" $statusTextBox ([System.Drawing.Color]::Red) }
}

# [10.3] CrowdStrike GroupTag Functions
function Invoke-CrowdStrikeGroupTagDialog {
    param([string[]]$Departments)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "CrowdStrike Grouping Tag"
    $form.Size = New-Object System.Drawing.Size(510, 360)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::Black
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    try { Add-GradientBackground -form $form } catch {}

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "CROWDSTRIKE TAG UPDATE"
    $titleLabel.Location = New-Object System.Drawing.Point(0, 15)
    $titleLabel.Size = New-Object System.Drawing.Size(500, 30)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $form.Controls.Add($titleLabel)

    try { Add-TitleAnimation -titleLabel $titleLabel } catch {}

    # Department label
    $lblDept = New-Object System.Windows.Forms.Label
    $lblDept.Text = "Department:"
    $lblDept.Location = New-Object System.Drawing.Point(20, 60)
    $lblDept.Size = New-Object System.Drawing.Size(120, 22)
    $lblDept.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $lblDept.ForeColor = [System.Drawing.Color]::White
    $lblDept.BackColor = [System.Drawing.Color]::Transparent
    $form.Controls.Add($lblDept)

    # Department dropdown
    $deptCombo = New-Object System.Windows.Forms.ComboBox
    $deptCombo.Location = New-Object System.Drawing.Point(150, 58)
    $deptCombo.Size = New-Object System.Drawing.Size(320, 25)
    $deptCombo.Font = New-Object System.Drawing.Font("Arial", 12)
    $deptCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $form.Controls.Add($deptCombo)

    # Populate from provided Departments (filter out headers and empty)
    if ($Departments -and $Departments.Count -gt 0) {
        foreach ($d in $Departments) {
            if ($d -and ($d -notlike '---*')) { [void]$deptCombo.Items.Add($d) }
        }
    }
    # Fallback: in case no list passed, at least avoid empty dropdown
    if ($deptCombo.Items.Count -eq 0) {
        [void]$deptCombo.Items.Add("General")
    }
    $deptCombo.SelectedIndex = 0

    # Token label
    $lblToken = New-Object System.Windows.Forms.Label
    $lblToken.Text = "Token:"
    $lblToken.Location = New-Object System.Drawing.Point(20, 95)
    $lblToken.Size = New-Object System.Drawing.Size(120, 22)
    $lblToken.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $lblToken.ForeColor = [System.Drawing.Color]::White
    $lblToken.BackColor = [System.Drawing.Color]::Transparent
    $form.Controls.Add($lblToken)

    # Token textbox
    $txtToken = New-Object System.Windows.Forms.TextBox
    $txtToken.Location = New-Object System.Drawing.Point(150, 93)
    $txtToken.Size = New-Object System.Drawing.Size(320, 25)
    $txtToken.BackColor = [System.Drawing.Color]::Black
    $txtToken.ForeColor = [System.Drawing.Color]::Lime
    $txtToken.Font = New-Object System.Drawing.Font("Consolas", 12)
    $txtToken.UseSystemPasswordChar = $true
    $form.Controls.Add($txtToken)

    # Show token checkbox
    $chkShow = New-Object System.Windows.Forms.CheckBox
    $chkShow.Text = "Show token"
    $chkShow.Location = New-Object System.Drawing.Point(150, 123)
    $chkShow.AutoSize = $true
    $chkShow.ForeColor = [System.Drawing.Color]::White
    $chkShow.BackColor = [System.Drawing.Color]::Transparent
    $chkShow.Add_CheckedChanged({ $txtToken.UseSystemPasswordChar = -not $chkShow.Checked })
    $form.Controls.Add($chkShow)

    # Statusbox
    $status = New-Object System.Windows.Forms.RichTextBox
    $status.Multiline = $true
    $status.ScrollBars = "Vertical"
    $status.Location = New-Object System.Drawing.Point(20, 155)
    $status.Size = New-Object System.Drawing.Size(450, 120)
    $status.BackColor = [System.Drawing.Color]::Black
    $status.ForeColor = [System.Drawing.Color]::Lime
    $status.Font = New-Object System.Drawing.Font("Consolas", 9)
    $status.ReadOnly = $true
    $status.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $status.Text = "Enter a tag and maintenance token, then click Apply..."
    $form.Controls.Add($status)

    # Apply Button
    $btnApply = New-Object System.Windows.Forms.Button
    $btnApply.Text = "Apply"
    $btnApply.Location = New-Object System.Drawing.Point(170, 285)
    $btnApply.Size = New-Object System.Drawing.Size(150, 30)
    $btnApply.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 0)
    $btnApply.ForeColor = [System.Drawing.Color]::White
    $btnApply.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnApply.Add_Click({
            $selectedDept = if ($deptCombo.SelectedItem) { $deptCombo.SelectedItem.ToString().Trim() } else { "" }
            $tok = $txtToken.Text
            $status.Clear()

            if (-not $selectedDept) { Add-Status "Please select a department." $status ([System.Drawing.Color]::Yellow); return }
            if ($selectedDept -like '---*') { Add-Status "Please select a valid department (not a section header)." $status ([System.Drawing.Color]::Yellow); return }
            if (-not $tok) { Add-Status "Please enter maintenance token." $status ([System.Drawing.Color]::Yellow); return }

            # Use department as the grouping tag
            $tag = $selectedDept
            Add-Status "Applying tag '$tag'..." $status
            try {
                $ok = Set-CrowdStrikeGroupingTag -Tag $tag -Token $tok -StatusTextBox $status
                if ($ok) {
                    Add-Status "Completed." $status
                }
                else {
                    Add-Status "Failed to update tag." $status ([System.Drawing.Color]::Red)
                }
            }
            catch {
                Add-Status ("ERROR: " + $_.Exception.Message) $status ([System.Drawing.Color]::Red)
            }
        })
    $form.Controls.Add($btnApply)

    $form.KeyPreview = $true
    $form.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $form.Close() } })

    $form.AcceptButton = $btnApply

    $form.ShowDialog() | Out-Null
}

# [10.4] CrowdStrike Uninstalltion Functions
function Get-CrowdStrikeUninstallCommand {
    try {
        $roots = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )

        foreach ($root in $roots) {
            if (-not (Test-Path $root)) { continue }
            foreach ($k in Get-ChildItem $root -ErrorAction SilentlyContinue) {
                try {
                    $p = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue
                    if (-not $p) { continue }

                    $name = "$($p.DisplayName) $($p.DisplayVersion)"
                    if ($name -match '(?i)crowdstrike.*(windows|falcon).*sensor') {
                        # �u ti�n ModifyPath (m? UI), n?u c�
                        $cmd = $p.ModifyPath
                        if ([string]::IsNullOrWhiteSpace($cmd)) {
                            $cmd = $p.UninstallString
                        }
                        if ([string]::IsNullOrWhiteSpace($cmd)) { continue }

                        # N?u l� MsiExec v� c� GUID ? d�ng /I �? m? Maintenance UI
                        if ($cmd -match '(?i)msiexec(\.exe)?' -and $cmd -match '\{[0-9A-Fa-f\-]{36}\}') {
                            $guid = $Matches[0]
                            return "msiexec.exe /I $guid"
                        }

                        # Kh�ng ph?i MSI ho?c kh�ng b?t GUID:
                        # Lo?i b? tham s? silent �? �p m? UI
                        $uiCmd = $cmd -replace '(?i)\s*/(qn|qb|quiet|passive|norestart)\b', ''
                        $uiCmd = $uiCmd.Trim()
                        return $uiCmd
                    }
                }
                catch {
                    Add-Status "Error reading $($k.PSPath): $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
        }
    }
    catch {
        Add-Status "Error scanning CrowdStrike registry: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Yellow)
    }
    return $null
}

function Start-CrowdStrikeMaintenanceUI {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.RichTextBox] $statusTextBox
    )

    $cmd = Get-CrowdStrikeUninstallCommand
    if (-not $cmd) {
        Add-Status "Error: CrowdStrike not found in Programs and Features." $statusTextBox ([System.Drawing.Color]::Yellow)
        return
    }

    Add-Status "Opening CrowdStrike Maintenance UI..." $statusTextBox
    try {
        $exe = $cmd
        $argumentList = $null

        if ($cmd -match '^\s*"(.*?)"\s*(.*)$') {
            $exe = $Matches[1]
            $argumentList = $Matches[2]
        } elseif ($cmd -match '^\s*(\S+)\s+(.*)$') {
            $exe = $Matches[1]
            $argumentList = $Matches[2]
        }

        if ([string]::IsNullOrWhiteSpace($argumentList)) {
            Start-Process -FilePath $exe | Out-Null
        } else {
            Start-Process -FilePath $exe -ArgumentList $argumentList | Out-Null
        }
        Add-Status "Please enter Token in the CrowdStrike window to uninstall." $statusTextBox ([System.Drawing.Color]::Cyan)
    }
    catch {
        Add-Status "Error opening CrowdStrike UI: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
    }
}