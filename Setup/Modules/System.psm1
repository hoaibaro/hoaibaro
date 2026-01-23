function Invoke-RunAllOperations {
    param([System.Windows.Forms.Form]$mainForm)
    Hide-MainMenu
    # Create status form
    $statusForm = New-Object System.Windows.Forms.Form
    $statusForm.Text = "Running All Operations"
    $statusForm.Size = New-Object System.Drawing.Size(595, 480)
    $statusForm.StartPosition = "CenterScreen"
    $statusForm.BackColor = [System.Drawing.Color]::Black
    $statusForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $statusForm.MaximizeBox = $false
    $statusForm.MinimizeBox = $false

    # Add gradient background
    Add-GradientBackground -form $statusForm

    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "RUNNING ALL OPERATIONS"
    $titleLabel.Location = New-Object System.Drawing.Point(0, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(580, 30)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $statusForm.Controls.Add($titleLabel)

    # Status text box
    $statusTextBox = New-Object System.Windows.Forms.RichTextBox
    $statusTextBox.Multiline = $true
    $statusTextBox.ScrollBars = "Vertical"
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 60)
    $statusTextBox.Size = New-Object System.Drawing.Size(560, 350)
    $statusTextBox.BackColor = [System.Drawing.Color]::Black
    $statusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusTextBox.ReadOnly = $true
    $statusTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $statusForm.Controls.Add($statusTextBox)

    # Add title animation
    Add-TitleAnimation -titleLabel $titleLabel

    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(10, 420)
    $progressBar.Size = New-Object System.Drawing.Size(560, 15)
    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    $statusForm.Controls.Add($progressBar)

    # Show the form
    $statusForm.Show()
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # Pre-step: Device type selection to decide WiFi behavior
        $deviceType = Select-DeviceType -Owner $statusForm
        if (-not $deviceType) {
            Show-MainMenu
            $statusForm.Close()
            return
        }
        $isLaptop = $false
        try { $isLaptop = ($deviceType -match '(?i)(laptop|notebook|ultrabook)') } catch {}

        # STEP 0: Network preparation (WiFi only for laptops)
        $progressBar.Value = 5
        if ($isLaptop) {
            Add-Status "STEP 0: Laptop detected - connecting to WiFi..." $statusTextBox
            $wifiResult = Invoke-WiFiAutoConnection $statusTextBox
            if ($wifiResult) { Add-Status "WiFi connection completed!" $statusTextBox }
            else { Add-Status "WiFi connection failed, but continuing..." $statusTextBox ([System.Drawing.Color]::Yellow) }
        }
        else {
            Add-Status "STEP 0: Desktop detected - skipping WiFi, using Ethernet" $statusTextBox ([System.Drawing.Color]::Cyan)
            try { $hasInternet = Test-NetConnection 8.8.8.8 -Port 53 -InformationLevel Quiet }
            catch { $hasInternet = $false }
            if ($hasInternet) { Add-Status "Internet reachable via Ethernet." $statusTextBox ([System.Drawing.Color]::Green) }
            else {
                Add-Status "No Internet via Ethernet. Attempting to install Ethernet driver..." $statusTextBox ([System.Drawing.Color]::Yellow)
                $ok = Install-DriverExe -Path $Global:EthernetDriverExe -statusTextBox $statusTextBox -Type 'Ethernet'
                if ($ok) {
                    # Re-check Internet
                    try { $hasInternet = Test-NetConnection 8.8.8.8 -Port 53 -InformationLevel Quiet } catch { $hasInternet = $false }
                    if ($hasInternet) { Add-Status "Internet reachable after Ethernet driver installation." $statusTextBox ([System.Drawing.Color]::Green) }
                    else { Add-Status "Still no Internet after Ethernet driver installation. Continuing offline-friendly steps." $statusTextBox ([System.Drawing.Color]::Yellow) }
                }
                else { Add-Status "Ethernet driver installation failed or not applicable. Continuing offline-friendly steps." $statusTextBox ([System.Drawing.Color]::Yellow) }
            }
        }

        # Optional: Windows Update background
        Add-Status "STEP 0.5: Starting Windows Updates (Background)..." $statusTextBox
        $progressBar.Value = 8
        $updateResult = Invoke-WindowsUpdateCheck $statusTextBox
        if ($updateResult) {
            Add-Status "Windows Update process started successfully!" $statusTextBox ([System.Drawing.Color]::Green)
        }
        else {
            Add-Status "Windows Update start failed, but continuing..." $statusTextBox ([System.Drawing.Color]::Yellow)
        }
        Add-Status "STEP 0 completed - Updates will continue in background..." $statusTextBox ([System.Drawing.Color]::Cyan)

        # STEP 1: Device Selection and Software Installation
        Add-Status "STEP 1: Software provisioning (Detect ? Copy ? Install)..." $statusTextBox
        $progressBar.Value = 14

        $provisionOk = Invoke-InstallSoftware -DeviceType $deviceType -statusTextBox $statusTextBox -CleanupTemp
        if (-not $provisionOk) { Add-Status "STEP 1 finished with warnings/errors." $statusTextBox ([System.Drawing.Color]::Yellow) }
        Add-Status "STEP 1 completed successfully !!!" $statusTextBox ([System.Drawing.Color]::Cyan)

        # STEP 2: Rename Device
        Add-Status "STEP 2: Rename Device ..." $statusTextBox
        $progressBar.Value = 28

        $configResult = Invoke-RenamebyDevice -deviceType $deviceType $statusTextBox
        if ($configResult) {
            Add-Status "STEP 2 completed successfully !!!" $statusTextBox ([System.Drawing.Color]::Cyan)
        }
        else {
            Add-Status "STEP 2 encountered errors. Check logs." $statusTextBox ([System.Drawing.Color]::Red)
        }

        # STEP 3: Power Options
        Add-Status "STEP 3: Configuring Power Options and Timezone..." $statusTextBox
        $progressBar.Value = 42

        $cleanupResult = Invoke-SystemCleanup -deviceType $deviceType -statusTextBox $statusTextBox
        if ($cleanupResult) {
            Add-Status "STEP 3 completed successfully !!!" $statusTextBox ([System.Drawing.Color]::Cyan)
        }
        else {
            Add-Status "STEP 3 encountered errors. Check logs." $statusTextBox ([System.Drawing.Color]::Red)
        }

        # STEP 4: Windows and Office Activation
        Add-Status "STEP 4: Activating Windows 10 Pro and Office 2019 Pro Plus..." $statusTextBox
        $progressBar.Value = 56

        $activationResult = Invoke-ActivateConfiguration -deviceType $deviceType -statusTextBox $statusTextBox
        if ($activationResult) {
            Add-Status "STEP 4 completed successfully !!!" $statusTextBox ([System.Drawing.Color]::Cyan)
        }
        else {
            Add-Status "STEP 4 encountered errors. Check logs." $statusTextBox ([System.Drawing.Color]::Red)
        }

        # STEP 5: Windows Features Configuration
        Add-Status "STEP 5: Configuring Windows Features..." $statusTextBox
        $progressBar.Value = 70

        $featuresResult = Invoke-WindowsFeaturesConfiguration -deviceType $deviceType -statusTextBox $statusTextBox
        if ($featuresResult) {
            Add-Status "STEP 5 completed successfully !!!" $statusTextBox ([System.Drawing.Color]::Cyan)
        }
        else {
            Add-Status "STEP 5 encountered errors. Check logs." $statusTextBox ([System.Drawing.Color]::Red)
        }

        # STEP 6: User Password Management
        Add-Status "STEP 6: Managing user password..." $statusTextBox
        $progressBar.Value = 80

        $passwordResult = Invoke-UserPasswordManagement -deviceType $deviceType -statusTextBox $statusTextBox
        if ($passwordResult) {
            Add-Status "STEP 6 completed successfully !!!" $statusTextBox ([System.Drawing.Color]::Cyan)
        }
        else {
            Add-Status "STEP 6 encountered errors. Check logs." $statusTextBox ([System.Drawing.Color]::Red)
        }

        # STEP 7: Domain Join
        Add-Status "STEP 7: Joining domain..." $statusTextBox
        $progressBar.Value = 100

        $domainResult = Show-DomainManagementForm -deviceType $deviceType -statusTextBox $statusTextBox
        if ($domainResult) {
            Add-Status "STEP 7 completed successfully !!!" $statusTextBox ([System.Drawing.Color]::Cyan)
        }
        else {
            Add-Status "STEP 7 encountered errors. Check logs." $statusTextBox ([System.Drawing.Color]::Red)
        }

        Add-Status "Computer will restart if domain join was successful." $statusTextBox
    }
    catch {
        Add-Status "Error occurred: $_" $statusTextBox ([System.Drawing.Color]::Red)
        [System.Windows.Forms.MessageBox]::Show(
            "An error occurred during the operations: $_",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
    finally {
        $statusForm.KeyPreview = $true
        $statusForm.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $statusForm.Close() } })
        $statusForm.Add_FormClosed({ Show-MainMenu })
    }
}

Export-ModuleMember -Function Invoke-RunAllOperations