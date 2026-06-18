function Invoke-RunAllOperations {
    param([System.Windows.Forms.Form]$mainForm)
    Hide-MainMenu -mainForm $mainForm
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
            Show-MainMenu -mainForm $mainForm
            $statusForm.Close()
            return
        }
        $isLaptop = $false
        try { $isLaptop = ($deviceType -match '(?i)(laptop|notebook|ultrabook)') } catch {}

        # STEP 0: Network Check and Driver Installation
        $progressBar.Value = 5
        Add-Status "STEP 0: Checking Internet connection..." $statusTextBox

        $hasInternet = $false
        try { $hasInternet = Test-NetConnection 8.8.8.8 -Port 53 -InformationLevel Quiet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue } catch {}

        if (-not $hasInternet) {
            Add-Status "No Internet detected. Attempting to install driver..." $statusTextBox ([System.Drawing.Color]::Yellow)

            # Try auto-install from config paths first
            if ($isLaptop) {
                $autoDriverPath = $Global:config.sourcePaths.wifiDriver
            }
            else {
                $autoDriverPath = $Global:config.sourcePaths.ethernetDriver
            }

            $autoInstalled = $false
            if ($autoDriverPath -and (Test-Path $autoDriverPath)) {
                $driverType = if ($isLaptop) { 'WiFi' } else { 'Ethernet' }
                $autoInstalled = Install-DriverExe -Path $autoDriverPath -statusTextBox $statusTextBox -Type $driverType
                if ($autoInstalled) {
                    Start-Sleep -Seconds 5
                    try { $hasInternet = Test-NetConnection 8.8.8.8 -Port 53 -InformationLevel Quiet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue } catch {}
                }
            }

            # If still no internet, show Browse Driver dialog
            if (-not $hasInternet) {
                Add-Status "Auto driver install failed or not found. Please browse to driver file." $statusTextBox ([System.Drawing.Color]::Yellow)

                $driverForm = New-Object System.Windows.Forms.Form
                $driverForm.Text = "No Internet Connection"
                $driverForm.Size = New-Object System.Drawing.Size(420, 170)
                $driverForm.StartPosition = "CenterScreen"
                $driverForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
                $driverForm.MaximizeBox = $false
                $driverForm.MinimizeBox = $false
                $driverForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
                $driverForm.TopMost = $true

                $lbl = New-Object System.Windows.Forms.Label
                $lbl.Text = "No Internet detected. Browse to network driver installer (.exe)"
                $lbl.Location = New-Object System.Drawing.Point(20, 15)
                $lbl.Size = New-Object System.Drawing.Size(370, 35)
                $lbl.ForeColor = [System.Drawing.Color]::FromArgb(255, 200, 50)
                $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
                $driverForm.Controls.Add($lbl)

                $btnBrowse = New-Object System.Windows.Forms.Button
                $btnBrowse.Text = "Browse Driver"
                $btnBrowse.Location = New-Object System.Drawing.Point(20, 65)
                $btnBrowse.Size = New-Object System.Drawing.Size(180, 45)
                $btnBrowse.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
                $btnBrowse.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 60)
                $btnBrowse.ForeColor = [System.Drawing.Color]::White
                $btnBrowse.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
                $btnBrowse.Add_Click({
                        $ofd = New-Object System.Windows.Forms.OpenFileDialog
                        $ofd.Title = "Select Network Driver Installer"
                        $ofd.Filter = "Driver Installer (*.exe)|*.exe|All Files (*.*)|*.*"
                        $ofd.InitialDirectory = "D:\"
                        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                            $driverForm.Tag = $ofd.FileName
                            $driverForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
                            $driverForm.Close()
                        }
                    })
                $driverForm.Controls.Add($btnBrowse)

                $btnSkip = New-Object System.Windows.Forms.Button
                $btnSkip.Text = "Skip"
                $btnSkip.Location = New-Object System.Drawing.Point(210, 65)
                $btnSkip.Size = New-Object System.Drawing.Size(180, 45)
                $btnSkip.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
                $btnSkip.BackColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
                $btnSkip.ForeColor = [System.Drawing.Color]::White
                $btnSkip.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
                $btnSkip.Add_Click({
                        $driverForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
                        $driverForm.Close()
                    })
                $driverForm.Controls.Add($btnSkip)

                $dialogResult = $driverForm.ShowDialog()

                if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK -and $driverForm.Tag) {
                    $selectedDriver = $driverForm.Tag
                    Add-Status "Installing driver: $(Split-Path $selectedDriver -Leaf)" $statusTextBox
                    $driverType = if ($isLaptop) { 'WiFi' } else { 'Ethernet' }
                    $installOk = Install-DriverExe -Path $selectedDriver -statusTextBox $statusTextBox -Type $driverType

                    if ($installOk) {
                        Add-Status "Driver installed. Waiting for network..." $statusTextBox
                        Start-Sleep -Seconds 8
                        try { $hasInternet = Test-NetConnection 8.8.8.8 -Port 53 -InformationLevel Quiet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue } catch {}
                    }
                }
                else {
                    Add-Status "Driver installation skipped by user." $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
        }

        # WiFi auto-connect for laptops (after driver is installed)
        if ($isLaptop -and $hasInternet -eq $false) {
            Add-Status "Laptop: Attempting WiFi auto-connect..." $statusTextBox
            $wifiResult = Invoke-WiFiAutoConnection $statusTextBox
            if ($wifiResult) {
                Add-Status "WiFi connection completed!" $statusTextBox
                Start-Sleep -Seconds 3
                try { $hasInternet = Test-NetConnection 8.8.8.8 -Port 53 -InformationLevel Quiet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue } catch {}
            }
        }

        # Final unified Internet status
        if ($hasInternet) {
            Add-Status "Internet: Connected" $statusTextBox ([System.Drawing.Color]::Green)
        }
        else {
            Add-Status "Internet: Not available (some steps will be skipped)" $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        # Optional: Windows Update background (requires Internet)
        if ($hasInternet) {
            Add-Status "STEP 0.5: Starting Windows Updates (Background)..." $statusTextBox
            $progressBar.Value = 8
            $updateResult = Invoke-WindowsUpdateCheck $statusTextBox
            if ($updateResult) {
                Add-Status "Windows Update process started successfully!" $statusTextBox ([System.Drawing.Color]::Green)
            }
            else {
                Add-Status "Windows Update start failed, but continuing..." $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        else {
            Add-Status "STEP 0.5: Skipping Windows Updates (no Internet)" $statusTextBox ([System.Drawing.Color]::Yellow)
            $progressBar.Value = 8
        }
        Add-Status "STEP 0 completed" $statusTextBox ([System.Drawing.Color]::Cyan)

        # STEP 1: Device Selection and Software Installation
        Add-Status "STEP 1: Software provisioning (Detect > Copy > Install)..." $statusTextBox
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
        Add-Status "STEP 4: Activating Windows and Office..." $statusTextBox
        $progressBar.Value = 56

        $activationResult = Invoke-ActivateConfiguration -deviceType $deviceType -statusTextBox $statusTextBox -HasInternet $hasInternet
        if ($activationResult) {
            Add-Status "STEP 4 completed successfully !!!" $statusTextBox ([System.Drawing.Color]::Cyan)
        }
        else {
            Add-Status "STEP 4 encountered errors. Check logs." $statusTextBox ([System.Drawing.Color]::Red)
        }

        # STEP 5: Windows Features Configuration
        if ($hasInternet) {
            Add-Status "STEP 5: Configuring Windows Features..." $statusTextBox
            $progressBar.Value = 70

            $featuresResult = Invoke-WindowsFeaturesConfiguration -deviceType $deviceType -statusTextBox $statusTextBox
            if ($featuresResult) {
                Add-Status "STEP 5 completed successfully !!!" $statusTextBox ([System.Drawing.Color]::Cyan)
            }
            else {
                Add-Status "STEP 5 encountered errors. Check logs." $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "STEP 5: Skipping Windows Features (no Internet)" $statusTextBox ([System.Drawing.Color]::Yellow)
            $progressBar.Value = 70
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

        # STEP 7: Domain Join (temporarily disabled)
        # TODO: Re-enable when Domain Join feature is stable
        Add-Status "STEP 7: Domain Join (temporarily disabled)" $statusTextBox ([System.Drawing.Color]::Gray)
        $progressBar.Value = 100

        # Offline summary
        if (-not $hasInternet) {
            Add-Status "" $statusTextBox
            Add-Status "=== OFFLINE SUMMARY ===" $statusTextBox ([System.Drawing.Color]::Yellow)
            Add-Status "Skipped: Windows Update, Activation (/ato), Features, Domain Join" $statusTextBox ([System.Drawing.Color]::Yellow)
            Add-Status "Keys installed: Windows + Office will auto-activate when online" $statusTextBox ([System.Drawing.Color]::Yellow)
            Add-Status "Please run skipped steps manually when Internet is available." $statusTextBox ([System.Drawing.Color]::Yellow)
        }
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
        $statusForm.Add_FormClosed({ Show-MainMenu -mainForm $mainForm })
    }

    # Keep status form open for user to review results
    # Loop exits when user closes the form (ESC or X button)
    while ($statusForm.Visible -and -not $statusForm.IsDisposed) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }
}

Export-ModuleMember -Function Invoke-RunAllOperations