# [4] Volume Management Functions
function Update-DriveList {
    $driveListBox.Items.Clear()
    $drives = Get-WmiObject Win32_LogicalDisk | Select-Object @{Name = 'Name'; Expression = { $_.DeviceID } }, `
    @{Name = 'VolumeName'; Expression = { $_.VolumeName } }, `
    @{Name = 'Size (GB)'; Expression = { [math]::round($_.Size / 1GB, 0) } }, `
    @{Name = 'FreeSpace (GB)'; Expression = { [math]::round($_.FreeSpace / 1GB, 0) } }

    foreach ($drive in $drives) {
        $driveInfo = "$($drive.Name) - $($drive.VolumeName) - Size: $($drive.'Size (GB)') GB - Free: $($drive.'FreeSpace (GB)') GB"
        $driveListBox.Items.Add($driveInfo)
    }

    if ($driveListBox.Items.Count -gt 0) {
        $driveListBox.SelectedIndex = 0
    }

    return $drives.Count
}
function Invoke-VolumeManagementDialog {
    Hide-MainMenu
    # Create volume management form
    $volumeForm = New-Object System.Windows.Forms.Form
    $volumeForm.Text = "Volume Management"
    $volumeForm.Size = New-Object System.Drawing.Size(795, 660) # Increase the size of the form
    $volumeForm.StartPosition = "CenterScreen"
    $volumeForm.BackColor = [System.Drawing.Color]::Black
    $volumeForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $volumeForm.MaximizeBox = $false
    $volumeForm.MinimizeBox = $false

    Add-GradientBackground -form $volumeForm

    # Title label with animation
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "VOLUME MANAGEMENT"
    $titleLabel.Location = New-Object System.Drawing.Point(0, 10) # Move the title label down
    $titleLabel.Size = New-Object System.Drawing.Size(795, 40) # Increase the size of the title label
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $titleLabel.Padding = New-Object System.Windows.Forms.Padding(5)

    Add-TitleAnimation -titleLabel $titleLabel

    $volumeForm.Controls.Add($titleLabel)

    # Drive list box with enhanced styling
    $driveListBox = New-Object System.Windows.Forms.ListBox
    $driveListBox.Location = New-Object System.Drawing.Point(10, 50) # Move the drive list box down
    $driveListBox.Size = New-Object System.Drawing.Size(760, 100) # Increase the size of the drive list box
    $driveListBox.BackColor = [System.Drawing.Color]::Black
    $driveListBox.ForeColor = [System.Drawing.Color]::Lime
    $driveListBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $driveListBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $volumeForm.Controls.Add($driveListBox)

    # Content Panel for function buttons
    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Location = New-Object System.Drawing.Point(10, 200)
    $contentPanel.Size = New-Object System.Drawing.Size(760, 260)
    $contentPanel.BackColor = [System.Drawing.Color]::Transparent
    $contentPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    # Add content panel to form
    $volumeForm.Controls.Add($contentPanel)

    # Status text box with enhanced styling
    $statusTextBox = New-Object System.Windows.Forms.RichTextBox
    $statusTextBox.Multiline = $true
    $statusTextBox.ScrollBars = "Vertical"
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 470) # Move the status text box down
    $statusTextBox.Size = New-Object System.Drawing.Size(760, 140) # Increase the size of the status text box
    $statusTextBox.BackColor = [System.Drawing.Color]::Black
    $statusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusTextBox.ReadOnly = $true
    $statusTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $statusTextBox.Text = "Status messages will appear here..."
    $volumeForm.Controls.Add($statusTextBox)

    Update-DriveList

    # Add a common event handler for driveListBox to update all input fields in all buttons
    $driveListBox.Add_SelectedIndexChanged({
            if ($driveListBox.SelectedItem) {
                $selectedDrive = $driveListBox.SelectedItem.ToString()
                if ($selectedDrive.Length -gt 0) {
                    $driveLetter = $selectedDrive.Substring(0, 1)

                    # Update for Change Letter button
                    if ($contentPanel.Controls.Count -gt 0 -and $contentPanel.Controls[0].Text -eq "Change Drive Letter") {
                        # Find the GroupBox in the change letter panel
                        $changeGroupBox = $contentPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.GroupBox] }
                        if ($changeGroupBox) {
                            # Find the old drive letter textbox (first textbox)
                            $oldLetterTextBox = $changeGroupBox.Controls | Where-Object { $_ -is [System.Windows.Forms.TextBox] } | Select-Object -First 1
                            if ($oldLetterTextBox) {
                                $oldLetterTextBox.Text = $driveLetter
                            }
                        }
                    }

                    # Update for Shrink Volume button
                    if ($contentPanel.Controls.Count -gt 0 -and $contentPanel.Controls[0].Text -eq "Shrink Volume") {
                        # Use script scope variable for shrink volume
                        if ($script:selectedDriveTextBox) {
                            $script:selectedDriveTextBox.Text = $driveLetter
                        }
                    }

                    # Update for Extend Volume button
                    if ($contentPanel.Controls.Count -gt 0 -and $contentPanel.Controls[0].Text -eq "Extend Volume") {
                        if ($script:extendSourceDriveTextBox -and $script:extendTargetDriveTextBox) {
                            $currentSource = $script:extendSourceDriveTextBox.Text.Trim()
                            $currentTarget = $script:extendTargetDriveTextBox.Text.Trim()

                            # Logic m?i:
                            # 1. N?u source tr?ng -> fill source (tr? ? C)
                            # 2. N?u source có r?i và khác v?i drive ðý?c ch?n -> fill target (cho phép C)
                            # 3. N?u c? 2 ð?u có r?i -> thay ð?i target

                            if ([string]::IsNullOrEmpty($currentSource)) {
                                # Case 1: Source tr?ng -> fill source (KHÔNG cho phép C)
                                if ($driveLetter -eq "C" -or $driveLetter -eq "c") {
                                    return
                                }
                                $script:extendSourceDriveTextBox.Text = $driveLetter
                            }
                            elseif ($driveLetter -eq $currentSource) {
                                # Case 2: Click vào drive ðang là source -> clear target ð? user có th? ch?n l?i
                                $script:extendTargetDriveTextBox.Text = ""
                            }
                            elseif ([string]::IsNullOrEmpty($currentTarget) -or $driveLetter -ne $currentTarget) {
                                # Case 3: Target tr?ng ho?c ch?n drive khác -> fill/update target (CHO PHÉP C)
                                $script:extendTargetDriveTextBox.Text = $driveLetter
                            }
                            else {
                                return
                            }
                        }
                    }

                    # Update for Rename Volume button
                    if ($contentPanel.Controls.Count -gt 0 -and $contentPanel.Controls[0].Text -eq "Rename Volume") {
                        # Find the GroupBox in the rename panel
                        $renameGroupBox = $contentPanel.Controls | Where-Object { $_ -is [System.Windows.Forms.GroupBox] }
                        if ($renameGroupBox) {
                            # Find the drive letter textbox (first textbox)
                            $driveLetterTextBox = $renameGroupBox.Controls | Where-Object { $_ -is [System.Windows.Forms.TextBox] } | Select-Object -First 1
                            if ($driveLetterTextBox) {
                                $driveLetterTextBox.Text = $driveLetter
                            }
                        }
                    }
                }
            }
        })

    # [4.1] Change Drive Letter button
    $btnChangeDriveLetter = New-DynamicButton -text "Change Letter" -x 10 -y 150 -width 150 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        # Clear the content panel
        $statusTextBox.Clear()
        $contentPanel.Controls.Clear()

        # Title label
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = "Change Drive Letter"
        $titleLabel.Location = New-Object System.Drawing.Point(0, 10)
        $titleLabel.Size = New-Object System.Drawing.Size(760, 30)
        $titleLabel.ForeColor = [System.Drawing.Color]::Lime
        $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
        $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $titleLabel.BackColor = [System.Drawing.Color]::Transparent
        $contentPanel.Controls.Add($titleLabel)

        # Create GroupBox for centered content
        $changeGroupBox = New-Object System.Windows.Forms.GroupBox
        $changeGroupBox.Text = "Drive Letter Configuration"
        $changeGroupBox.Location = New-Object System.Drawing.Point(180, 60)
        $changeGroupBox.Size = New-Object System.Drawing.Size(400, 150)
        $changeGroupBox.ForeColor = [System.Drawing.Color]::Lime
        $changeGroupBox.BackColor = [System.Drawing.Color]::Transparent
        $changeGroupBox.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)

        # Add GroupBox to content panel
        $contentPanel.Controls.Add($changeGroupBox)

        # Old drive letter label
        $oldLetterLabel = New-Object System.Windows.Forms.Label
        $oldLetterLabel.Text = "Select Drive Letter to Change:"
        $oldLetterLabel.Location = New-Object System.Drawing.Point(20, 30)
        $oldLetterLabel.Size = New-Object System.Drawing.Size(200, 20)
        $oldLetterLabel.ForeColor = [System.Drawing.Color]::White
        $oldLetterLabel.BackColor = [System.Drawing.Color]::Transparent
        $oldLetterLabel.Font = New-Object System.Drawing.Font("Arial", 10)
        $changeGroupBox.Controls.Add($oldLetterLabel)

        # Old drive letter textbox
        $script:oldLetterTextBox = New-Object System.Windows.Forms.TextBox
        $script:oldLetterTextBox.Location = New-Object System.Drawing.Point(230, 30)
        $script:oldLetterTextBox.Size = New-Object System.Drawing.Size(50, 20)
        $script:oldLetterTextBox.BackColor = [System.Drawing.Color]::Black
        $script:oldLetterTextBox.ForeColor = [System.Drawing.Color]::Lime
        $script:oldLetterTextBox.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
        $script:oldLetterTextBox.MaxLength = 1
        $script:oldLetterTextBox.ReadOnly = $true
        $script:oldLetterTextBox.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
        $changeGroupBox.Controls.Add($script:oldLetterTextBox)

        # New drive letter label
        $newLetterLabel = New-Object System.Windows.Forms.Label
        $newLetterLabel.Text = "New Drive Letter:"
        $newLetterLabel.Location = New-Object System.Drawing.Point(20, 60)
        $newLetterLabel.Size = New-Object System.Drawing.Size(200, 20)
        $newLetterLabel.ForeColor = [System.Drawing.Color]::White
        $newLetterLabel.BackColor = [System.Drawing.Color]::Transparent
        $newLetterLabel.Font = New-Object System.Drawing.Font("Arial", 10)
        $changeGroupBox.Controls.Add($newLetterLabel)

        # New drive letter textbox
        $script:newLetterTextBox = New-Object System.Windows.Forms.TextBox
        $script:newLetterTextBox.Location = New-Object System.Drawing.Point(230, 60)
        $script:newLetterTextBox.Size = New-Object System.Drawing.Size(50, 20)
        $script:newLetterTextBox.BackColor = [System.Drawing.Color]::Black
        $script:newLetterTextBox.ForeColor = [System.Drawing.Color]::Lime
        $script:newLetterTextBox.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
        $script:newLetterTextBox.MaxLength = 1
        $script:newLetterTextBox.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
        $changeGroupBox.Controls.Add($script:newLetterTextBox)



        # Set initial value if a drive is already selected
        if ($driveListBox.SelectedItem) {
            $selectedDrive = $driveListBox.SelectedItem.ToString()
            $driveLetter = $selectedDrive.Substring(0, 1)
            $script:oldLetterTextBox.Text = $driveLetter
        }

        # Change button (inside GroupBox)
        $changeButton = New-DynamicButton -text "Change" -x 100 -y 100 -width 200 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
            $oldLetter = if ($script:oldLetterTextBox) { $script:oldLetterTextBox.Text.Trim().ToUpper() } else { "" }
            $newLetter = if ($script:newLetterTextBox) { $script:newLetterTextBox.Text.Trim().ToUpper() } else { "" }

            # Validate input
            if ($oldLetter -eq "") {
                Add-Status "Error: Please select a drive letter to change." $statusTextBox ([System.Drawing.Color]::Red)
                return
            }

            if ($newLetter -eq "") {
                Add-Status "Error: Please enter a new drive letter." $statusTextBox ([System.Drawing.Color]::Red)
                return
            }

            # Validate drive letter format
            if (-not ($oldLetter -match '^[A-Z]$')) {
                Add-Status "Error: Old drive letter must be a single letter (A-Z)." $statusTextBox ([System.Drawing.Color]::Red)
                return
            }

            if (-not ($newLetter -match '^[A-Z]$')) {
                Add-Status "Error: New drive letter must be a single letter (A-Z)." $statusTextBox ([System.Drawing.Color]::Red)
                return
            }

            if ($oldLetter -eq $newLetter) {
                Add-Status "Error: New drive letter must be different from the current one." $statusTextBox ([System.Drawing.Color]::Red)
                return
            }

            # Check if new letter is already in use
            try {
                $existingDrives = Get-WmiObject Win32_LogicalDisk | Select-Object -ExpandProperty DeviceID
                if ($existingDrives -contains "$($newLetter):") {
                    Add-Status "Error: Drive letter $newLetter is already in use." $statusTextBox
                    return
                }
                Add-Status "Drive letter $newLetter is available." $statusTextBox
            }
            catch {
                Add-Status "Warning: Could not verify drive letter availability. Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Yellow)
                Add-Status "Proceeding with change operation..."
            }

            # Create diskpart script
            $tempFile = [System.IO.Path]::GetTempFileName()
            $diskpartScript = @"
select volume $oldLetter
assign letter=$newLetter
"@
            Set-Content -Path $tempFile -Value $diskpartScript

            $statusTextBox.Clear()
            Add-Status "Changing drive $oldLetter to $newLetter..." $statusTextBox

            try {
                # Run diskpart with elevated privileges
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = "diskpart.exe"
                $psi.Arguments = "/s `"$tempFile`""
                $psi.UseShellExecute = $true
                $psi.Verb = "runas"
                $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

                $process = [System.Diagnostics.Process]::Start($psi)
                $process.WaitForExit()

                # Check if successful
                if ($process.ExitCode -eq 0) {
                    Add-Status "Successfully changed drive letter from $oldLetter to $newLetter." $statusTextBox

                    # Wait for system to update
                    Add-Status "Waiting for system to update drive information..." $statusTextBox
                    Start-Sleep -Seconds 2

                    # Force refresh UI
                    [System.Windows.Forms.Application]::DoEvents()

                    # Update drive list
                    Update-DriveList

                    # Clear textboxes
                    if ($script:oldLetterTextBox) {
                        $script:oldLetterTextBox.Text = ""
                    }
                    if ($script:newLetterTextBox) {
                        $script:newLetterTextBox.Text = ""
                    }

                    Add-Status "Drive letter change completed successfully !!!" $statusTextBox
                }
                else {
                    Add-Status "Error changing drive letter. Exit code: $($process.ExitCode)" $statusTextBox
                }
            }
            catch {
                Add-Status "Error: $($_.Exception.Message)" $statusTextBox
            }
            finally {
                # Clean up temp file
                if (Test-Path $tempFile) {
                    Remove-Item $tempFile -Force
                }
            }
        }
        $changeGroupBox.Controls.Add($changeButton)
        # Cho phép Enter kích ho?t nút Change
        $volumeForm.AcceptButton = $changeButton

        # Enter trong ô nh?p k? t? m?i s? kích ho?t Change
        $script:newLetterTextBox.Add_KeyDown({
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                $_.SuppressKeyPress = $true
                $changeButton.PerformClick()
            }
        })

        # Set initial value if a drive is already selected
        if ($driveListBox.SelectedItem) {
            $selectedDrive = $driveListBox.SelectedItem.ToString()
            if ($selectedDrive.Length -gt 0) {
                $driveLetter = $selectedDrive.Substring(0, 1)
                if ($script:oldLetterTextBox) {
                    $script:oldLetterTextBox.Text = $driveLetter
                }
            }
        }
        Add-Status "Ready to change letter. Select a drive, enter a new letter, then click Change." $statusTextBox
        Update-DriveList $driveListBox
    }
    $volumeForm.Controls.Add($btnChangeDriveLetter)

    # [4.2] Shrink Volume button
    $btnShrinkVolume = New-DynamicButton -text "Shrink Volume" -x 170 -y 150 -width 150 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        # Clear the content panel
        $statusTextBox.Clear()
        $contentPanel.Controls.Clear()

        # Create title using function
        New-ShrinkVolumeTitle -contentPanel $contentPanel

        # Create drive selector using function
        New-ShrinkVolumeDriveSelector -contentPanel $contentPanel

        $selectedDriveTextBox = $script:selectedDriveTextBox

        # Create partition size options using function
        New-ShrinkVolumePartitionSizeOptions -contentPanel $contentPanel -selectedDriveTextBox $selectedDriveTextBox

        # Create new label input using function
        New-ShrinkVolumeNewLabelInput -contentPanel $contentPanel -selectedDriveTextBox $selectedDriveTextBox

        # Create shrink action button using function
        New-ShrinkVolumeActionButton -contentPanel $contentPanel -selectedDriveTextBox $selectedDriveTextBox

        # Update drive letter from selected drive IMMEDIATELY after controls are added
        if ($driveListBox.SelectedItem) {
            $selectedDrive = $driveListBox.SelectedItem.ToString()
            if ($selectedDrive.Length -gt 0) {
                $driveLetter = $selectedDrive.Substring(0, 1)
                if ($script:selectedDriveTextBox) {
                    $script:selectedDriveTextBox.Text = $driveLetter
                }
            }
        }

        Add-Status "Ready to shrink volume. Select a drive, choose partition size, then click Shrink." $statusTextBox
        Update-DriveList $driveListBox
    }
    $volumeForm.Controls.Add($btnShrinkVolume)

    # [4.3] Rename Volume button
    $btnRenameVolume = New-DynamicButton -text "Rename Volume" -x 330 -y 150 -width 150 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        # Clear the content panel
        $statusTextBox.Clear()
        $contentPanel.Controls.Clear()

        # Create title
        New-RenameVolumeTitle -parentPanel $contentPanel

        # Create GroupBox with all controls inside
        $renameControls = New-RenameVolumeGroupBox -parentPanel $contentPanel -driveListBox $driveListBox

        # Create rename button inside GroupBox
        New-RenameActionButton -groupBox $renameControls.GroupBox -driveListBox $driveListBox

        # Ensure drive letter is updated immediately when button is clicked
        if ($driveListBox.SelectedItem -and $renameControls.DriveLetterTextBox) {
            $selectedDrive = $driveListBox.SelectedItem.ToString()
            if ($selectedDrive.Length -gt 0) {
                $driveLetter = $selectedDrive.Substring(0, 1)
                $renameControls.DriveLetterTextBox.Text = $driveLetter
            }
        }

        Add-Status "Ready to rename volume. Select a drive, enter a new label, then click Rename Volume." $statusTextBox
        Update-DriveList $driveListBox
    }
    $volumeForm.Controls.Add($btnRenameVolume)

    # [4.4] Extend Volume button
    $btnExtendVolume = New-DynamicButton -text "Extend Volume" -x 490 -y 150 -width 150 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        # Clear the content panel
        $statusTextBox.Clear()
        $contentPanel.Controls.Clear()

        # Create title
        New-ExtendVolumeTitle -parentPanel $contentPanel

        # Create GroupBox with all controls inside
        $extendControls = New-ExtendVolumeGroupBox -parentPanel $contentPanel

        # Create merge button inside GroupBox
        New-ExtendActionButton -extendControls $extendControls

        # Ensure drives are updated immediately when button is clicked
        if ($driveListBox.SelectedItem -and $script:extendSourceDriveTextBox) {
            $selectedDrive = $driveListBox.SelectedItem.ToString()
            if ($selectedDrive.Length -gt 0) {
                $driveLetter = $selectedDrive.Substring(0, 1)
                $script:extendSourceDriveTextBox.Text = $driveLetter
            }
        }

        Add-Status "Ready to extend volume. Select source and target drives, then click Extend." $statusTextBox
        Update-DriveList $driveListBox
    }
    $volumeForm.Controls.Add($btnExtendVolume)

    # [4.0] Return to Main Menu button
    $btnReturn = New-DynamicButton -text "Return" -x 650 -y 150 -width 120 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(180, 0, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(220, 0, 0)) -pressColor ([System.Drawing.Color]::FromArgb(120, 0, 0)) -clickAction {
        $volumeForm.Close()
    }
    $volumeForm.Controls.Add($btnReturn)

    # When the form is closed, show the main menu again
    $volumeForm.Add_FormClosed({
            Show-MainMenu
        })

    # Set the cancel button (Escape key)
    $volumeForm.CancelButton = $btnReturn

    # Show the form
    $volumeForm.ShowDialog()
}

# [4.2] Shrink Volume Functions
function New-ShrinkVolumeTitle {
    param([System.Windows.Forms.Panel]$contentPanel)

    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Shrink Volume"
    $titleLabel.Location = New-Object System.Drawing.Point(0, 10)
    $titleLabel.Size = New-Object System.Drawing.Size(760, 30)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $contentPanel.Controls.Add($titleLabel)
}
function New-ShrinkVolumeDriveSelector {
    param([System.Windows.Forms.Panel]$contentPanel)

    # Selected drive letter label
    $selectedDriveLabel = New-Object System.Windows.Forms.Label
    $selectedDriveLabel.Text = "Selected Drive Letter:"
    $selectedDriveLabel.Location = New-Object System.Drawing.Point(20, 50)
    $selectedDriveLabel.Size = New-Object System.Drawing.Size(150, 20)
    $selectedDriveLabel.ForeColor = [System.Drawing.Color]::White
    $selectedDriveLabel.BackColor = [System.Drawing.Color]::Transparent
    $selectedDriveLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $contentPanel.Controls.Add($selectedDriveLabel)

    # Selected drive letter textbox - use script scope
    $script:selectedDriveTextBox = New-Object System.Windows.Forms.TextBox
    $script:selectedDriveTextBox.Location = New-Object System.Drawing.Point(180, 50)
    $script:selectedDriveTextBox.Size = New-Object System.Drawing.Size(50, 25)
    $script:selectedDriveTextBox.BackColor = [System.Drawing.Color]::Black
    $script:selectedDriveTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:selectedDriveTextBox.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
    $script:selectedDriveTextBox.MaxLength = 1
    $script:selectedDriveTextBox.ReadOnly = $true
    $script:selectedDriveTextBox.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
    $contentPanel.Controls.Add($script:selectedDriveTextBox)
}
function New-ShrinkVolumePartitionSizeOptions {
    param ([System.Windows.Forms.Panel]$contentPanel, [System.Windows.Forms.TextBox]$selectedDriveTextBox)

    # Partition size options group box
    $partitionGroupBox = New-Object System.Windows.Forms.GroupBox
    $partitionGroupBox.Text = "Choose Partition Size"
    $partitionGroupBox.Location = New-Object System.Drawing.Point(20, 80)
    $partitionGroupBox.Size = New-Object System.Drawing.Size(720, 120)
    $partitionGroupBox.ForeColor = [System.Drawing.Color]::Lime
    $partitionGroupBox.BackColor = [System.Drawing.Color]::Transparent
    $partitionGroupBox.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $contentPanel.Controls.Add($partitionGroupBox)

    # Create a panel inside the GroupBox to properly group radio buttons
    $radioPanel = New-Object System.Windows.Forms.Panel
    $radioPanel.Location = New-Object System.Drawing.Point(10, 20)
    $radioPanel.Size = New-Object System.Drawing.Size(700, 90)
    $radioPanel.BackColor = [System.Drawing.Color]::Transparent
    $partitionGroupBox.Controls.Add($radioPanel)

    # Declare radio buttons at script scope so they're accessible in the shrink button click event
    $script:radio100GB = New-Object System.Windows.Forms.RadioButton
    $script:radio100GB.Text = "100GB (recommended for 256GB drives)"
    $script:radio100GB.Location = New-Object System.Drawing.Point(10, 10)
    $script:radio100GB.Size = New-Object System.Drawing.Size(350, 20)
    $script:radio100GB.ForeColor = [System.Drawing.Color]::White
    $script:radio100GB.Font = New-Object System.Drawing.Font("Arial", 10)
    $script:radio100GB.Checked = $true
    $radioPanel.Controls.Add($script:radio100GB)

    # 200GB radio button
    $script:radio200GB = New-Object System.Windows.Forms.RadioButton
    $script:radio200GB.Text = "200GB (recommended for 500GB drives)"
    $script:radio200GB.Location = New-Object System.Drawing.Point(10, 35)
    $script:radio200GB.Size = New-Object System.Drawing.Size(350, 20)
    $script:radio200GB.ForeColor = [System.Drawing.Color]::White
    $script:radio200GB.Font = New-Object System.Drawing.Font("Arial", 10)
    $radioPanel.Controls.Add($script:radio200GB)

    # 500GB radio button
    $script:radio500GB = New-Object System.Windows.Forms.RadioButton
    $script:radio500GB.Text = "500GB (recommended for 1TB+ drives)"
    $script:radio500GB.Location = New-Object System.Drawing.Point(10, 60)
    $script:radio500GB.Size = New-Object System.Drawing.Size(350, 20)
    $script:radio500GB.ForeColor = [System.Drawing.Color]::White
    $script:radio500GB.Font = New-Object System.Drawing.Font("Arial", 10)
    $radioPanel.Controls.Add($script:radio500GB)

    # Custom size radio button
    $script:radioCustom = New-Object System.Windows.Forms.RadioButton
    $script:radioCustom.Text = "Custom size (MB):"
    $script:radioCustom.Location = New-Object System.Drawing.Point(370, 10)
    $script:radioCustom.Size = New-Object System.Drawing.Size(150, 20)
    $script:radioCustom.ForeColor = [System.Drawing.Color]::White
    $script:radioCustom.Font = New-Object System.Drawing.Font("Arial", 10)
    $radioPanel.Controls.Add($script:radioCustom)

    # Custom size textbox
    $script:customSizeTextBox = New-Object System.Windows.Forms.TextBox
    $script:customSizeTextBox.Location = New-Object System.Drawing.Point(370, 35)
    $script:customSizeTextBox.Size = New-Object System.Drawing.Size(150, 25)
    $script:customSizeTextBox.BackColor = [System.Drawing.Color]::Black
    $script:customSizeTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:customSizeTextBox.Font = New-Object System.Drawing.Font("Consolas", 11)
    $script:customSizeTextBox.Text = "103424"  # Default to 100GB in MB
    $script:customSizeTextBox.Enabled = $false
    $radioPanel.Controls.Add($script:customSizeTextBox)

    # Add event handlers for radio buttons to enable/disable custom textbox
    $script:radioCustom.Add_CheckedChanged({
            if ($script:radioCustom.Checked) {
                $script:customSizeTextBox.Enabled = $true
                $script:customSizeTextBox.Focus()
            }
            else {
                $script:customSizeTextBox.Enabled = $false
            }
        })

    # Add event handlers for other radio buttons to disable custom textbox
    $script:radio100GB.Add_CheckedChanged({
            if ($script:radio100GB.Checked) {
                $script:customSizeTextBox.Enabled = $false
            }
        })

    $script:radio200GB.Add_CheckedChanged({
            if ($script:radio200GB.Checked) {
                $script:customSizeTextBox.Enabled = $false
            }
        })

    $script:radio500GB.Add_CheckedChanged({
            if ($script:radio500GB.Checked) {
                $script:customSizeTextBox.Enabled = $false
            }
        })
}
function New-ShrinkVolumeNewLabelInput {
    param([System.Windows.Forms.Panel]$contentPanel, [System.Windows.Forms.TextBox]$selectedDriveTextBox)

    # New partition label
    $newLabelLabel = New-Object System.Windows.Forms.Label
    $newLabelLabel.Text = "New Partition Label:"
    $newLabelLabel.Location = New-Object System.Drawing.Point(300, 50)
    $newLabelLabel.Size = New-Object System.Drawing.Size(150, 20)
    $newLabelLabel.ForeColor = [System.Drawing.Color]::White
    $newLabelLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $contentPanel.Controls.Add($newLabelLabel)

    # New partition label textbox
    $script:newLabelTextBox = New-Object System.Windows.Forms.TextBox
    $script:newLabelTextBox.Location = New-Object System.Drawing.Point(450, 50)
    $script:newLabelTextBox.Size = New-Object System.Drawing.Size(250, 25)
    $script:newLabelTextBox.BackColor = [System.Drawing.Color]::Black
    $script:newLabelTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:newLabelTextBox.Font = New-Object System.Drawing.Font("Consolas", 11)
    $script:newLabelTextBox.Text = "DATA"
    $contentPanel.Controls.Add($script:newLabelTextBox)
}
function Get-ShrinkVolumePartitionSize {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    # Determine partition size based on selected radio button
    $sizeMB = 0

    if ($script:radio100GB.Checked) {
        $sizeMB = 103424
    }
    elseif ($script:radio200GB.Checked) {
        $sizeMB = 205824
    }
    elseif ($script:radio500GB.Checked) {
        $sizeMB = 513024
    }
    elseif ($script:radioCustom.Checked) {
        # Validate custom size input
        $customSize = $script:customSizeTextBox.Text.Trim()
        if ($customSize -match '^\d+$') {
            try {
                $sizeMB = [int]$customSize
                if ($sizeMB -lt 1024) {
                    Add-Status "Error: Custom size must be at least 1024 MB (1 GB)." $statusTextBox ([System.Drawing.Color]::Red)
                    return -1
                }
                if ($sizeMB -gt 2097152) {
                    # 2TB limit
                    Add-Status "Error: Custom size cannot exceed 2,097,152 MB (2 TB)." $statusTextBox ([System.Drawing.Color]::Red)
                    return -1
                }
            }
            catch {
                Add-Status "Error processing custom size: $_" $statusTextBox ([System.Drawing.Color]::Red)
                return -1
            }
        }
        else {
            Add-Status "Error: Custom size must be a valid number (digits only)." $statusTextBox ([System.Drawing.Color]::Red)
            return -1
        }
    }
    else {
        Add-Status "Error: Please select a partition size option." $statusTextBox ([System.Drawing.Color]::Red)
        return -1
    }

    return $sizeMB
}
function Test-ShrinkVolumeSpace {
    param([string]$driveLetter, [int]$sizeMB)

    # Validate drive exists and get info
    try {
        $driveInfo = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "$($driveLetter):" }
        if (-not $driveInfo) {
            Add-Status "Error: Drive $driveLetter does not exist." $statusTextBox ([System.Drawing.Color]::Red)
            return $false
        }

        $freeSpaceMB = [math]::Floor($driveInfo.FreeSpace / 1MB)

        # Get actual shrinkable space using PowerShell (more accurate)
        try {
            $partition = Get-Partition -DriveLetter $driveLetter -ErrorAction Stop
            $shrinkInfo = Get-PartitionSupportedSize -DriveLetter $driveLetter -ErrorAction Stop
            $maxShrinkBytes = $partition.Size - $shrinkInfo.SizeMin
            $maxShrinkMB = [math]::Floor($maxShrinkBytes / 1MB)

            if ($sizeMB -gt $maxShrinkMB) {
                Add-Status "Error: Requested size ($sizeMB MB) exceeds maximum shrinkable space ($maxShrinkMB MB)." $statusTextBox ([System.Drawing.Color]::Red)
                Add-Status "Try running disk defragmentation first or choose a smaller size."
                return $false
            }
        }
        catch {
            Add-Status "Warning: Could not get exact shrinkable space. Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
            # Fallback: Use 100% of free space as safe shrink limit
            $maxShrinkMB = [math]::Floor($freeSpaceMB * 1)
            Add-Status "Using fallback calculation: 100% of free space = $maxShrinkMB MB" $statusTextBox

            if ($sizeMB -gt $maxShrinkMB) {
                Add-Status "Error: Requested size ($sizeMB MB) exceeds estimated safe shrink limit ($maxShrinkMB MB)." $statusTextBox ([System.Drawing.Color]::Red)
                Add-Status "Try a smaller size or free up more space on the drive."
                return $false
            }
        }
    }
    catch {
        Add-Status "Error getting drive information: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }

    return $true
}
function Invoke-ShrinkVolumeOperation {
    param([string]$driveLetter, [int]$sizeMB, [string]$newLabel)

    # Create a batch file that will run diskpart (using exact install.ps1 approach)
    $batchFilePath = "shrink_volume.bat"

    $batchContent = @"
@echo off
echo ============================================================ > shrink_status.txt
echo                  Shrinking Volume $driveLetter >> shrink_status.txt
echo ============================================================ >> shrink_status.txt
echo. >> shrink_status.txt

echo Creating diskpart script... >> shrink_status.txt
(
    echo select volume $driveLetter
    echo shrink desired=$sizeMB
    echo create partition primary
    echo format fs=ntfs quick label="$newLabel"
    echo assign
    echo list volume
) > diskpart_script.txt

echo Running diskpart... >> shrink_status.txt
echo. >> shrink_status.txt
echo Diskpart script contents: >> shrink_status.txt
type diskpart_script.txt >> shrink_status.txt
echo. >> shrink_status.txt

diskpart /s diskpart_script.txt > diskpart_output.txt
if %errorlevel% neq 0 (
    echo Error: Diskpart failed with exit code %errorlevel% >> shrink_status.txt
    echo This could be due to insufficient free space or the drive being in use. >> shrink_status.txt
    echo Try defragmenting the drive first or closing any applications using the drive. >> shrink_status.txt
    echo. >> shrink_status.txt
    echo Diskpart output: >> shrink_status.txt
    type diskpart_output.txt >> shrink_status.txt

    echo. >> shrink_status.txt
    echo Checking drive information: >> shrink_status.txt
    powershell -command "Get-WmiObject Win32_LogicalDisk -Filter \"DeviceID='$($driveLetter):'\" | Select-Object DeviceID, VolumeName, Size, FreeSpace | Format-List" >> shrink_status.txt

    del diskpart_output.txt
    del diskpart_script.txt
    exit /b %errorlevel%
)

echo Diskpart completed successfully. >> shrink_status.txt
echo. >> shrink_status.txt

echo Cleaning up temporary files... >> shrink_status.txt
del diskpart_output.txt
del diskpart_script.txt

echo. >> shrink_status.txt
echo Getting available drives after operation... >> shrink_status.txt
powershell -command "Get-WmiObject Win32_LogicalDisk | Select-Object @{Name='Name';Expression={`$_.DeviceID}}, @{Name='VolumeName';Expression={`$_.VolumeName}}, @{Name='Size (GB)';Expression={[math]::round(`$_.Size/1GB, 0)}}, @{Name='FreeSpace (GB)';Expression={[math]::round(`$_.FreeSpace/1GB, 0)}} | Format-Table -AutoSize | Out-String" >> shrink_status.txt

echo Operation completed successfully. >> shrink_status.txt
"@
    Set-Content -Path $batchFilePath -Value $batchContent -Force -Encoding ASCII
    $statusTextBox.Clear()
    Add-Status "Shrinking drive $driveLetter..." $statusTextBox

    try {
        # Create a process to run batch file with admin privileges and hide cmd window
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "cmd.exe"
        $psi.Arguments = "/c `"$batchFilePath`""
        $psi.UseShellExecute = $true
        $psi.Verb = "runas"
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        # Run process
        $batchProcess = [System.Diagnostics.Process]::Start($psi)
        $batchProcess.WaitForExit()

        # Read status file and display in status box
        if (Test-Path "shrink_status.txt") {
            Remove-Item "shrink_status.txt" -Force -ErrorAction SilentlyContinue
        }

        # Check if operation was successful (using exact install.ps1 logic)
        if ($batchProcess.ExitCode -eq 0) {
            Add-Status "Operation completed." $statusTextBox
            Add-Status "Creating new partition..." $statusTextBox

            # Wait for system to update drive information
            Start-Sleep -Seconds 2

            # Find newly created drive (exact same logic as install.ps1)
            $newDriveFound = $false
            $newDriveLetter = ""

            # Wait a bit to ensure system has updated drive list
            Start-Sleep -Seconds 2

            # Find newly created drive (look for drives that weren't there before)
            $currentDrives = Get-WmiObject Win32_LogicalDisk | Select-Object DeviceID, VolumeName
            foreach ($drive in $currentDrives) {
                if ($drive.DeviceID -ne "$($driveLetter):" -and
                    ($drive.VolumeName -eq "New Volume" -or $drive.VolumeName -eq "" -or $drive.VolumeName -eq $newLabel)) {
                    $newDriveFound = $true
                    $newDriveLetter = $drive.DeviceID.TrimEnd(":")
                    Add-Status "Found new drive: $($drive.DeviceID) with label: '$($drive.VolumeName)'" $statusTextBox
                    break
                }
            }

            # Rename the new drive if found and label is not already set
            if ($newDriveFound) {
                $actualNewLabel = if (-not [string]::IsNullOrEmpty($newLabel)) { $newLabel } else { "DATA" }

                # Get current drive info to check if label is already set
                $currentDrive = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$($newDriveLetter):'"

                if ($currentDrive.VolumeName -ne $actualNewLabel) {
                    Add-Status "Setting label for drive $newDriveLetter to '$actualNewLabel'..." $statusTextBox

                    # Rename using the most reliable method (Set-Volume)
                    try {
                        Set-Volume -DriveLetter $newDriveLetter -NewFileSystemLabel $actualNewLabel -ErrorAction Stop
                        Add-Status "Successfully set drive $newDriveLetter label to '$actualNewLabel'." $statusTextBox
                    }
                    catch {
                        # Fallback to label command
                        try {
                            Start-Process -FilePath "cmd.exe" -ArgumentList "/c label $newDriveLetter`:$actualNewLabel" -WindowStyle Hidden -Wait
                            Add-Status "Successfully set drive $newDriveLetter label to '$actualNewLabel'." $statusTextBox
                        }
                        catch {
                            Add-Status "Failed to set drive $newDriveLetter label. Please rename manually to '$actualNewLabel'." $statusTextBox
                        }
                    }
                }
                else {
                    Add-Status "Drive $newDriveLetter already has the correct label '$actualNewLabel'." $statusTextBox
                }
            }
            else {
                Add-Status "Could not find the newly created drive. Please rename it manually." $statusTextBox ([System.Drawing.Color]::Red)
            }

            # Update drive list
            Update-DriveList
        }
        else {
            Add-Status "Operation completed with warnings. Check the event logs for details." $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        # Clean up all temporary files
        $tempFiles = @(
            $batchFilePath,
            "shrink_status.txt",
            "diskpart_script.txt"
        )

        foreach ($file in $tempFiles) {
            Remove-Item $file -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Add-Status "Error: $($_.Exception.Message)" $statusTextBox
        Add-Status "Make sure you have administrator privileges." $statusTextBox

        # Clean up all temporary files in case of error
        $tempFiles = @(
            $batchFilePath,
            "shrink_status.txt",
            "diskpart_script.txt"
        )

        foreach ($file in $tempFiles) {
            Remove-Item $file -Force -ErrorAction SilentlyContinue
        }
    }
}
function New-ShrinkVolumeActionButton {
    param([System.Windows.Forms.Panel]$contentPanel)

    # Shrink button
    $shrinkButton = New-DynamicButton -text "Shrink" -x 275 -y 210 -width 200 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        $driveLetter = $script:selectedDriveTextBox.Text.Trim().ToUpper()
        $newLabel = $script:newLabelTextBox.Text.Trim()

        # Validate input
        if ($driveLetter -eq "") {
            Add-Status "Error: Please select a drive."
            return
        }

        if ($newLabel -eq "") {
            Add-Status "Error: Please enter a label for the new partition."
            return
        }

        # Get partition size
        $sizeMB = Get-ShrinkVolumePartitionSize
        if ($sizeMB -eq -1) {
            return  # Error already displayed
        }

        # Test if shrink operation is possible
        if (-not (Test-ShrinkVolumeSpace -driveLetter $driveLetter -sizeMB $sizeMB)) {
            return  # Error already displayed
        }

        # Perform shrink operation
        Invoke-ShrinkVolumeOperation -driveLetter $driveLetter -sizeMB $sizeMB -newLabel $newLabel
    }
    $contentPanel.Controls.Add($shrinkButton)
}

# [4.3] Rename Volume Functions
function New-RenameVolumeTitle {
    param([System.Windows.Forms.Panel]$parentPanel)
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Rename Volume"
    $titleLabel.Location = New-Object System.Drawing.Point(0, 10)
    $titleLabel.Size = New-Object System.Drawing.Size(760, 30)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $parentPanel.Controls.Add($titleLabel)
}
function New-RenameVolumeGroupBox {
    param([System.Windows.Forms.Panel]$parentPanel, [System.Windows.Forms.ListBox]$driveListBox)
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Text = "Volume Rename Configuration"
    $groupBox.Location = New-Object System.Drawing.Point(180, 60)
    $groupBox.Size = New-Object System.Drawing.Size(400, 150)
    $groupBox.ForeColor = [System.Drawing.Color]::Lime
    $groupBox.BackColor = [System.Drawing.Color]::Transparent
    $groupBox.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $parentPanel.Controls.Add($groupBox)

    # Drive letter label
    $driveLetterLabel = New-Object System.Windows.Forms.Label
    $driveLetterLabel.Text = "Drive Letter:"
    $driveLetterLabel.Location = New-Object System.Drawing.Point(30, 30)
    $driveLetterLabel.Size = New-Object System.Drawing.Size(100, 20)
    $driveLetterLabel.ForeColor = [System.Drawing.Color]::White
    $driveLetterLabel.BackColor = [System.Drawing.Color]::Transparent
    $driveLetterLabel.Font = New-Object System.Drawing.Font("Arial", 10)
    $groupBox.Controls.Add($driveLetterLabel)

    # Drive letter textbox - use script scope
    $script:renameDriveLetterTextBox = New-Object System.Windows.Forms.TextBox
    $script:renameDriveLetterTextBox.Location = New-Object System.Drawing.Point(130, 30)
    $script:renameDriveLetterTextBox.Size = New-Object System.Drawing.Size(50, 20)
    $script:renameDriveLetterTextBox.BackColor = [System.Drawing.Color]::Black
    $script:renameDriveLetterTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:renameDriveLetterTextBox.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
    $script:renameDriveLetterTextBox.MaxLength = 1
    $script:renameDriveLetterTextBox.ReadOnly = $true
    $script:renameDriveLetterTextBox.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
    $groupBox.Controls.Add($script:renameDriveLetterTextBox)

    # New label label
    $newLabelLabel = New-Object System.Windows.Forms.Label
    $newLabelLabel.Text = "New Label:"
    $newLabelLabel.Location = New-Object System.Drawing.Point(30, 60)
    $newLabelLabel.Size = New-Object System.Drawing.Size(100, 20)
    $newLabelLabel.ForeColor = [System.Drawing.Color]::White
    $newLabelLabel.BackColor = [System.Drawing.Color]::Transparent
    $newLabelLabel.Font = New-Object System.Drawing.Font("Arial", 10)
    $groupBox.Controls.Add($newLabelLabel)

    # New label textbox - use script scope
    $script:renameNewLabelTextBox = New-Object System.Windows.Forms.TextBox
    $script:renameNewLabelTextBox.Location = New-Object System.Drawing.Point(130, 60)
    $script:renameNewLabelTextBox.Size = New-Object System.Drawing.Size(200, 20)
    $script:renameNewLabelTextBox.BackColor = [System.Drawing.Color]::Black
    $script:renameNewLabelTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:renameNewLabelTextBox.Font = New-Object System.Drawing.Font("Consolas", 11)
    $groupBox.Controls.Add($script:renameNewLabelTextBox)

    return @{
        GroupBox           = $groupBox
        DriveLetterTextBox = $script:renameDriveLetterTextBox
        NewLabelTextBox    = $script:renameNewLabelTextBox
    }
}
function New-RenameActionButton {
    param([System.Windows.Forms.GroupBox]$groupBox, [System.Windows.Forms.ListBox]$driveListBox)
    $renameButton = New-DynamicButton -text "Rename" -x 100 -y 100 -width 200 -height 40 -clickAction {
        if ($script:renameDriveLetterTextBox -and $script:renameNewLabelTextBox) {
            $dl = $script:renameDriveLetterTextBox.Text.Trim().ToUpper()
            $nl = $script:renameNewLabelTextBox.Text.Trim()
            if ($dl -and $nl) {
                try {
                    Set-Volume -DriveLetter $dl -NewFileSystemLabel $nl -ErrorAction Stop
                    Add-Status "Renamed drive $dl to $nl successfully." $statusTextBox
                }
                catch {
                    Add-Status "Error renaming drive: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "Please enter both drive letter and new label." $statusTextBox
            }
        }
    }
    $groupBox.Controls.Add($renameButton)
}

# [4.4] Extend Volume Functions
function New-ExtendVolumeTitle {
    param([System.Windows.Forms.Panel]$parentPanel)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Extend Volume"
    $titleLabel.Location = New-Object System.Drawing.Point(0, 10)
    $titleLabel.Size = New-Object System.Drawing.Size(760, 30)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $parentPanel.Controls.Add($titleLabel)
}
function New-ExtendVolumeGroupBox {
    param([System.Windows.Forms.Panel]$parentPanel)

    # Create GroupBox for centered content
    $extendGroupBox = New-Object System.Windows.Forms.GroupBox
    $extendGroupBox.Text = "Volume Merge Configuration"
    $extendGroupBox.Location = New-Object System.Drawing.Point(180, 60)
    $extendGroupBox.Size = New-Object System.Drawing.Size(400, 180)
    $extendGroupBox.ForeColor = [System.Drawing.Color]::Lime
    $extendGroupBox.BackColor = [System.Drawing.Color]::Transparent
    $extendGroupBox.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $parentPanel.Controls.Add($extendGroupBox)

    # Source drive label
    $sourceDriveLabel = New-Object System.Windows.Forms.Label
    $sourceDriveLabel.Text = "Source Drive (Delete):"
    $sourceDriveLabel.Location = New-Object System.Drawing.Point(75, 35)
    $sourceDriveLabel.Size = New-Object System.Drawing.Size(180, 20)
    $sourceDriveLabel.ForeColor = [System.Drawing.Color]::White
    $sourceDriveLabel.BackColor = [System.Drawing.Color]::Transparent
    $sourceDriveLabel.Font = New-Object System.Drawing.Font("Arial", 10)
    $extendGroupBox.Controls.Add($sourceDriveLabel)

    # Source drive textbox - use script scope
    $script:extendSourceDriveTextBox = New-Object System.Windows.Forms.TextBox
    $script:extendSourceDriveTextBox.Location = New-Object System.Drawing.Point(260, 30)
    $script:extendSourceDriveTextBox.Size = New-Object System.Drawing.Size(60, 25)
    $script:extendSourceDriveTextBox.BackColor = [System.Drawing.Color]::Black
    $script:extendSourceDriveTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:extendSourceDriveTextBox.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
    $script:extendSourceDriveTextBox.MaxLength = 1
    $script:extendSourceDriveTextBox.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
    # Add focus events for better user experience
    $script:extendSourceDriveTextBox.Add_GotFocus({ $this.SelectAll() })
    $script:extendSourceDriveTextBox.Add_TextChanged({
            $currentText = $this.Text.ToUpper()
            if ($currentText -eq "C") {
                $this.Text = ""
            }
        })
    $extendGroupBox.Controls.Add($script:extendSourceDriveTextBox)

    # Target drive label
    $targetDriveLabel = New-Object System.Windows.Forms.Label
    $targetDriveLabel.Text = "Target Drive (Extend):"
    $targetDriveLabel.Location = New-Object System.Drawing.Point(75, 65)
    $targetDriveLabel.Size = New-Object System.Drawing.Size(180, 20)
    $targetDriveLabel.ForeColor = [System.Drawing.Color]::White
    $targetDriveLabel.BackColor = [System.Drawing.Color]::Transparent
    $targetDriveLabel.Font = New-Object System.Drawing.Font("Arial", 10)
    $extendGroupBox.Controls.Add($targetDriveLabel)

    # Target drive textbox - use script scope
    $script:extendTargetDriveTextBox = New-Object System.Windows.Forms.TextBox
    $script:extendTargetDriveTextBox.Location = New-Object System.Drawing.Point(260, 60)
    $script:extendTargetDriveTextBox.Size = New-Object System.Drawing.Size(60, 25)
    $script:extendTargetDriveTextBox.BackColor = [System.Drawing.Color]::Black
    $script:extendTargetDriveTextBox.ForeColor = [System.Drawing.Color]::Lime
    $script:extendTargetDriveTextBox.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
    $script:extendTargetDriveTextBox.MaxLength = 1
    $script:extendTargetDriveTextBox.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
    # Add focus events for better user experience
    $script:extendTargetDriveTextBox.Add_GotFocus({ $this.SelectAll() })
    $script:extendTargetDriveTextBox.Add_TextChanged({
            $currentText = $this.Text.ToUpper()

            # Ki?m tra trùng v?i source
            if ($script:extendSourceDriveTextBox -and $currentText -eq $script:extendSourceDriveTextBox.Text.Trim()) {
                Add-Status "Target không th? trùng v?i Source Drive!" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        })
    $extendGroupBox.Controls.Add($script:extendTargetDriveTextBox)

    # Warning label
    $warningLabel = New-Object System.Windows.Forms.Label
    $warningLabel.Text = "WARNING: This will DELETE drive and all data!"
    $warningLabel.Location = New-Object System.Drawing.Point(30, 100)
    $warningLabel.Size = New-Object System.Drawing.Size(340, 25)
    $warningLabel.ForeColor = [System.Drawing.Color]::Red
    $warningLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $warningLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $extendGroupBox.Controls.Add($warningLabel)

    # Add Enter key navigation
    $script:extendSourceDriveTextBox.Add_KeyDown({
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                $_.SuppressKeyPress = $true
                $script:extendTargetDriveTextBox.Focus()
            }
        })

    return @{
        GroupBox           = $extendGroupBox
        SourceDriveTextBox = $script:extendSourceDriveTextBox
        TargetDriveTextBox = $script:extendTargetDriveTextBox
    }
}
function New-ExtendActionButton {
    param([hashtable]$extendControls, [System.Windows.Forms.RichTextBox]$statusTextBox)
    $groupBox = $extendControls.GroupBox

    # Extend button (inside GroupBox)
    $mergeButton = New-DynamicButton -text "Extend" -x 100 -y 130 -width 200 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        # Get values directly from script scope variables
        $sourceDrive = ""
        $targetDrive = ""

        if ($script:extendSourceDriveTextBox -and $script:extendSourceDriveTextBox.Text) {
            $sourceDrive = $script:extendSourceDriveTextBox.Text.Trim().ToUpper()
        }
        if ($script:extendTargetDriveTextBox -and $script:extendTargetDriveTextBox.Text) {
            $targetDrive = $script:extendTargetDriveTextBox.Text.Trim().ToUpper()
        }

        $statusTextBox.Clear()
        Add-Status "Source Drive: '$sourceDrive' | Target Drive: '$targetDrive'" $statusTextBox

        # Validate input
        if (-not (Test-ExtendVolumeInput -sourceDrive $sourceDrive -targetDrive $targetDrive)) {
            return
        }

        # Confirm operation
        $confirmResult = [System.Windows.Forms.MessageBox]::Show(
            "WARNING: This will DELETE drive $sourceDrive and all its data, then extend drive $targetDrive.`n`nAre you sure you want to continue?",
            "Confirm Merge",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if ($confirmResult -eq [System.Windows.Forms.DialogResult]::No) {
            Add-Status "Operation cancelled by user." $statusTextBox
            return
        }

        # Perform merge operation using script scope textboxes
        Add-Status "Merging volumes: deleting drive $sourceDrive and extending drive $targetDrive..." $statusTextBox
        Invoke-ExtendVolumeOperation -sourceDrive $sourceDrive -targetDrive $targetDrive -statusTextBox $statusTextBox
    }
    $groupBox.Controls.Add($mergeButton)

    # Set up Enter key for target textbox to trigger merge
    $script:extendTargetDriveTextBox.Add_KeyDown({
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                $_.SuppressKeyPress = $true
                $mergeButton.PerformClick()
            }
        })
    return $mergeButton
}
function Test-ExtendVolumeInput {
    param([string]$sourceDrive, [string]$targetDrive, [System.Windows.Forms.TextBox]$statusTextBox)

    # Check if source drive is C - CH? C?M SOURCE, KHÔNG C?M TARGET
    if ($sourceDrive -eq "C") {
        Add-Status "L?I: Không th? s? d?ng ? C làm Source Drive! ? C là ? h? th?ng Windows." $statusTextBox ([System.Drawing.Color]::Red)
        Add-Status "H?y ch?n ? ð?a khác làm Source Drive." $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
    # Basic validation
    if ([string]::IsNullOrEmpty($sourceDrive)) {
        Add-Status "Error: Please enter a source drive letter." $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
    if ([string]::IsNullOrEmpty($targetDrive)) {
        Add-Status "Error: Please enter a target drive letter." $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
    if (-not ($sourceDrive -match '^[A-Z]$') -or -not ($targetDrive -match '^[A-Z]$')) {
        Add-Status "Error: Drive letters must be single letters (A-Z)." $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
    if ($sourceDrive -eq $targetDrive) {
        Add-Status "Error: Source and target drives cannot be the same." $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }

    # Check if drives exist
    $existingDrives = Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -ExpandProperty DeviceID | ForEach-Object { $_.Substring(0, 1) }
    if ($existingDrives -notcontains $sourceDrive) {
        Add-Status "Error: Source drive $sourceDrive does not exist." $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
    if ($existingDrives -notcontains $targetDrive) {
        Add-Status "Error: Target drive $targetDrive does not exist." $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }

    # Check if drives are on same physical disk
    try {
        $sourcePartition = Get-Partition -DriveLetter $sourceDrive -ErrorAction Stop
        $targetPartition = Get-Partition -DriveLetter $targetDrive -ErrorAction Stop

        if ($sourcePartition.DiskNumber -ne $targetPartition.DiskNumber) {
            Add-Status "Error: Drives are not on the same physical disk. Operation aborted for safety." $statusTextBox ([System.Drawing.Color]::Red)
            Add-Status "Source drive is on disk $($sourcePartition.DiskNumber), target drive is on disk $($targetPartition.DiskNumber)."
            return $false
        }
        Add-Status "Verified: Both drives are on the same physical disk (Disk $($sourcePartition.DiskNumber))."
    }
    catch {
        Add-Status "Warning: Could not verify disk compatibility. Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Yellow)
        Add-Status "Proceeding anyway, but operation may fail if drives are on different disks."
    }

    return $true
}
function Invoke-ExtendVolumeOperation {
    param([string]$sourceDrive, [string]$targetDrive, [System.Windows.Forms.RichTextBox]$statusTextBox)

    try {
        # Verify disk compatibility first
        $sourcePartition = Get-Partition -DriveLetter $sourceDrive -ErrorAction Stop
        $targetPartition = Get-Partition -DriveLetter $targetDrive -ErrorAction Stop

        if ($sourcePartition.DiskNumber -ne $targetPartition.DiskNumber) {
            Add-Status "Error: Drives are not on the same physical disk. Operation aborted." $statusTextBox ([System.Drawing.Color]::Red)
            return
        }
        Add-Status "Verified: Both drives are on the same physical disk (Disk $($sourcePartition.DiskNumber))." $statusTextBox
    }
    catch {
        Add-Status "Warning: Could not verify disk compatibility. Error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Yellow)
    }

    # Create batch file
    $batchFilePath = "merge_volumes.bat"
    $batchContent = @"
@echo off
setlocal enabledelayedexpansion

echo ============================================================ > merge_log.txt
echo                  Merging Volumes >> merge_log.txt
echo ============================================================ >> merge_log.txt
echo. >> merge_log.txt

echo Deleting source drive $sourceDrive... >> merge_log.txt
powershell -WindowStyle Hidden -command "& { try { Remove-Partition -DriveLetter $sourceDrive -Confirm:`$false -ErrorAction Stop; Write-Output 'Successfully deleted source drive $sourceDrive.' } catch { Write-Error `$_.Exception.Message; exit 1 } }" > delete_output.txt 2>&1

type delete_output.txt >> merge_log.txt

if errorlevel 1 (
    echo PowerShell delete failed, trying diskpart... >> merge_log.txt
    (
        echo select volume $sourceDrive
        echo delete volume override
    ) > diskpart_delete.txt

    diskpart /s diskpart_delete.txt > diskpart_delete_output.txt 2>&1
    type diskpart_delete_output.txt >> merge_log.txt
    del diskpart_delete.txt diskpart_delete_output.txt
)
del delete_output.txt

echo Waiting for system to update... >> merge_log.txt
timeout /t 3 /nobreak > nul

echo Extending target drive $targetDrive... >> merge_log.txt
powershell -WindowStyle Hidden -command "& { try { `$size = (Get-PartitionSupportedSize -DriveLetter $targetDrive).SizeMax; Resize-Partition -DriveLetter $targetDrive -Size `$size -ErrorAction Stop; Write-Output 'Successfully extended partition.' } catch { Write-Error `$_.Exception.Message; exit 1 } }" > extend_output.txt 2>&1

type extend_output.txt >> merge_log.txt

if errorlevel 1 (
    echo PowerShell extend failed, trying diskpart... >> merge_log.txt
    (
        echo rescan
        echo select volume $targetDrive
        echo extend
    ) > diskpart_extend.txt

    diskpart /s diskpart_extend.txt > diskpart_extend_output.txt 2>&1
    type diskpart_extend_output.txt >> merge_log.txt
    del diskpart_extend.txt diskpart_extend_output.txt
)
del extend_output.txt

echo. >> merge_log.txt
echo Merge completed successfully! >> merge_log.txt
echo MERGE_SUCCESS >> merge_log.txt
exit /b 0
"@

    Set-Content -Path $batchFilePath -Value $batchContent -Force -Encoding ASCII
    Add-Status "Processing... Please wait while the operation completes." $statusTextBox

    try {
        # Create a process to run batch file with admin privileges and hide cmd window
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "cmd.exe"
        $psi.Arguments = "/c `"$batchFilePath`""
        $psi.UseShellExecute = $true
        $psi.Verb = "runas"  # Run as admin
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        # Start the process
        $process = [System.Diagnostics.Process]::Start($psi)

        if ($process) {
            Add-Status "Batch process started. Waiting for completion..." $statusTextBox

            # Wait for process to complete
            $process.WaitForExit()
            $exitCode = $process.ExitCode

            Add-Status "Batch process completed with exit code: $exitCode" $statusTextBox

            # Check results
            if (Test-Path "merge_log.txt") {
                $logContent = Get-Content "merge_log.txt" -Raw

                if ($logContent -match "MERGE_SUCCESS") {
                    Add-Status "Drive $sourceDrive has been deleted and drive $targetDrive has been extended." $statusTextBox
                    Update-DriveList
                }
                else {
                    Add-Status "?? Operation completed with warnings. Check merge_log.txt for details." $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            else {
                Add-Status "? No log file found. Operation may have failed." $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "? Failed to start batch process." $statusTextBox ([System.Drawing.Color]::Red)
        }
    }
    catch {
        Add-Status "? Error running batch operation: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
    }
    finally {
        # Clean up files after showing results
        Start-Sleep -Seconds 2
        $tempFiles = @($batchFilePath, "delete_output.txt", "extend_output.txt", "diskpart_delete.txt", "diskpart_extend.txt", "diskpart_delete_output.txt", "diskpart_extend_output.txt")
        foreach ($file in $tempFiles) {
            Remove-Item $file -Force -ErrorAction SilentlyContinue
        }
    }
}