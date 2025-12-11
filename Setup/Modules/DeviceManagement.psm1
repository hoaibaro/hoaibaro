# [7] Rename Device Functions
function Invoke-RenameDialog {
    param(
        [string]$DeviceType = $null,
        [System.Windows.Forms.RichTextBox]$StatusTextBox = $null,
        [bool]$IsChildWindow = $false
    )

    if (-not $IsChildWindow) {
        Hide-MainMenu
    }

    # Create device rename form
    $renameForm = New-Object System.Windows.Forms.Form
    $renameForm.Text = "Rename Device"
    $renameForm.Size = New-Object System.Drawing.Size(495, 350)
    $renameForm.StartPosition = "CenterScreen"
    $renameForm.BackColor = [System.Drawing.Color]::Black
    $renameForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $renameForm.MaximizeBox = $false
    $renameForm.MinimizeBox = $false

    # Apply gradient background using global function
    Add-GradientBackground -form $renameForm

    # Create title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "RENAME DEVICE"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 0)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.Size = New-Object System.Drawing.Size(470, 40)
    $titleLabel.Location = New-Object System.Drawing.Point(0, 20)
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $renameForm.Controls.Add($titleLabel)

    Add-TitleAnimation -titleLabel $titleLabel

    # Get current computer name
    $currentName = $env:COMPUTERNAME

    # Create a colored label for the current name
    $currentNameLabel = New-Object System.Windows.Forms.Label
    $currentNameLabel.Text = $currentName
    $currentNameLabel.Font = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
    $currentNameLabel.ForeColor = [System.Drawing.Color]::WhiteSmoke
    $currentNameLabel.BackColor = [System.Drawing.Color]::Transparent
    $currentNameLabel.AutoSize = $true
    $currentNameLabel.Location = New-Object System.Drawing.Point(180, 68)
    $renameForm.Controls.Add($currentNameLabel)

    # Current device name label
    $currentLabel = New-Object System.Windows.Forms.Label
    $currentLabel.Text = "Current Name:"
    $currentLabel.Font = New-Object System.Drawing.Font("Arial", 12)
    $currentLabel.ForeColor = [System.Drawing.Color]::White
    $currentLabel.Size = New-Object System.Drawing.Size(480, 30)
    $currentLabel.Location = New-Object System.Drawing.Point(10, 70)
    $currentLabel.BackColor = [System.Drawing.Color]::Transparent
    $renameForm.Controls.Add($currentLabel)

    # Device type selection group box
    $deviceGroupBox = New-Object System.Windows.Forms.GroupBox
    $deviceGroupBox.Text = "Device Type"
    $deviceGroupBox.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $deviceGroupBox.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 0)
    $deviceGroupBox.Size = New-Object System.Drawing.Size(460, 80)
    $deviceGroupBox.Location = New-Object System.Drawing.Point(10, 110)
    $deviceGroupBox.BackColor = [System.Drawing.Color]::Transparent

    # Desktop radio button
    $radioDesktop = New-Object System.Windows.Forms.RadioButton
    $radioDesktop.Text = "Desktop"
    $radioDesktop.Font = New-Object System.Drawing.Font("Arial", 10)
    $radioDesktop.ForeColor = [System.Drawing.Color]::White
    $radioDesktop.Location = New-Object System.Drawing.Point(20, 30)
    $radioDesktop.Size = New-Object System.Drawing.Size(150, 30)
    $radioDesktop.BackColor = [System.Drawing.Color]::Transparent
    $radioDesktop.Checked = $true # Default selection

    # Laptop radio button
    $radioLaptop = New-Object System.Windows.Forms.RadioButton
    $radioLaptop.Text = "Laptop"
    $radioLaptop.Font = New-Object System.Drawing.Font("Arial", 10)
    $radioLaptop.ForeColor = [System.Drawing.Color]::White
    $radioLaptop.Location = New-Object System.Drawing.Point(190, 30)
    $radioLaptop.Size = New-Object System.Drawing.Size(100, 30)
    $radioLaptop.BackColor = [System.Drawing.Color]::Transparent

    # Custom radio button
    $radioCustom = New-Object System.Windows.Forms.RadioButton
    $radioCustom.Text = "Custom"
    $radioCustom.Location = New-Object System.Drawing.Point(340, 30)
    $radioCustom.Size = New-Object System.Drawing.Size(150, 30)
    $radioCustom.ForeColor = [System.Drawing.Color]::White
    $radioCustom.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $radioCustom.BackColor = [System.Drawing.Color]::Transparent

    # Add radio buttons to group box
    $deviceGroupBox.Controls.Add($radioDesktop)
    $deviceGroupBox.Controls.Add($radioLaptop)
    $deviceGroupBox.Controls.Add($radioCustom)
    $renameForm.Controls.Add($deviceGroupBox)

    # New name label
    $newNameLabel = New-Object System.Windows.Forms.Label
    $newNameLabel.Text = "New Device Name:"
    $newNameLabel.Font = New-Object System.Drawing.Font("Arial", 12)
    $newNameLabel.ForeColor = [System.Drawing.Color]::White
    $newNameLabel.Size = New-Object System.Drawing.Size(150, 30)
    $newNameLabel.Location = New-Object System.Drawing.Point(10, 205)
    $newNameLabel.BackColor = [System.Drawing.Color]::Transparent
    $renameForm.Controls.Add($newNameLabel)

    # New name textbox
    $newNameTextBox = New-Object System.Windows.Forms.RichTextBox
    $newNameTextBox.Font = New-Object System.Drawing.Font("Arial", 12)
    $newNameTextBox.Size = New-Object System.Drawing.Size(290, 30)
    $newNameTextBox.Location = New-Object System.Drawing.Point(180, 200)
    $newNameTextBox.BackColor = [System.Drawing.Color]::White
    $newNameTextBox.ForeColor = [System.Drawing.Color]::Black
    $newNameTextBox.Text = "HOD100" # Default to Desktop
    $renameForm.Controls.Add($newNameTextBox)

    # Pre-select based on DeviceType param
    if ($DeviceType -eq "Laptop") {
        $radioLaptop.Checked = $true
        $newNameTextBox.Text = "HOL100"
    }
    elseif ($DeviceType -eq "Desktop") {
        $radioDesktop.Checked = $true
        $newNameTextBox.Text = "HOD100"
    }

    # Event handlers for radio buttons to update the default name
    $radioDesktop.Add_CheckedChanged({
            if ($radioDesktop.Checked) {
                $newNameTextBox.Text = "HOD100"
            }
        })

    $radioLaptop.Add_CheckedChanged({
            if ($radioLaptop.Checked) {
                $newNameTextBox.Text = "HOL100"
            }
        })

    $radioCustom.Add_CheckedChanged({
            if ($radioCustom.Checked) {
                $newNameTextBox.Text = ""
            }
        })

    # Rename button
    $renameButton = New-Object System.Windows.Forms.Button
    $renameButton.Text = "Rename Device"
    $renameButton.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $renameButton.ForeColor = [System.Drawing.Color]::White
    $renameButton.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 0)
    $renameButton.Size = New-Object System.Drawing.Size(200, 40)
    $renameButton.Location = New-Object System.Drawing.Point(30, 240)
    $renameButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $renameButton.Add_Click({
            $newName = $newNameTextBox.Text.Trim()

            # Disable button
            $renameButton.Enabled = $false

            # Clear status if standalone
            if (-not $IsChildWindow) { $statusTextBox.Clear() }

            # Validation
            if ([string]::IsNullOrWhiteSpace($newName)) {
                if ($StatusTextBox) { Add-Status "Error: Please enter a new device name!" $StatusTextBox ([System.Drawing.Color]::Red) }
                else { [System.Windows.Forms.MessageBox]::Show("Please enter a new device name!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) }
                $renameButton.Enabled = $true
                return
            }

            $currentName = $env:COMPUTERNAME

            if ($newName -eq $currentName) {
                [System.Windows.Forms.MessageBox]::Show("New name is the same as the current name. No action taken.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                $renameButton.Enabled = $true
                return
            }

            # Confirm
            $confirmResult = [System.Windows.Forms.MessageBox]::Show(
                "Are you sure you want to rename this device from '$currentName' to '$newName'?`n`nThis operation requires a restart.",
                "Confirm Rename",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($confirmResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                try {
                    Rename-Computer -NewName $newName -Force -ErrorAction Stop
                    
                    if ($StatusTextBox) { Add-Status "Device renamed to '$newName'. Restart required." $StatusTextBox ([System.Drawing.Color]::Green) }

                    # Ask for restart
                    $restartResult = [System.Windows.Forms.MessageBox]::Show(
                        "Do you want to restart your device now?",
                        "Restart Confirmation",
                        [System.Windows.Forms.MessageBoxButtons]::YesNo,
                        [System.Windows.Forms.MessageBoxIcon]::Question
                    )

                    if ($restartResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                        Start-Sleep -Seconds 2
                        Restart-Computer -Force
                    }
                    $renameForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
                    $renameForm.Close()
                }
                catch {
                    if ($StatusTextBox) { Add-Status "Error renaming device: $($_.Exception.Message)" $StatusTextBox ([System.Drawing.Color]::Red) }
                    else { [System.Windows.Forms.MessageBox]::Show("Error renaming device: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) }
                }
            }
            else {
                if ($StatusTextBox) { Add-Status "Rename operation cancelled by user." $StatusTextBox ([System.Drawing.Color]::Yellow) }
            }
            $renameButton.Enabled = $true
        })
    $renameForm.Controls.Add($renameButton)

    # Cancel button
    $cancelButton = New-DynamicButton  -text "Cancel" -x 250 -y 240 -width 200 -height 40 -clickAction { $renameForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $renameForm.Close() } -normalColor ([System.Drawing.Color]::FromArgb(200, 0, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(255, 50, 50)) -pressColor ([System.Drawing.Color]::FromArgb(150, 0, 0))
    $renameForm.Controls.Add($cancelButton)

    $renameForm.AcceptButton = $renameButton
    $renameForm.CancelButton = $cancelButton

    if (-not $IsChildWindow) {
        $renameForm.Add_FormClosed({ Show-MainMenu })
    }

    $renameForm.ShowDialog()
}

# [8] Password Functions
function Show-SetPasswordForm {
    param ([string]$currentUser, [System.Windows.Forms.RichTextBox]$statusTextBox)
    Hide-MainMenu

    # Set Password Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Password"
    $form.Size = New-Object System.Drawing.Size(400, 320)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::Black
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    Add-GradientBackground -form $form

    # Title
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "PASSWORD"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 0)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $titleLabel.Size = New-Object System.Drawing.Size(400, 40)
    $titleLabel.Location = New-Object System.Drawing.Point(0, 20)
    $form.Controls.Add($titleLabel)

    Add-TitleAnimation -titleLabel $titleLabel

    # User label
    $userLabel = New-Object System.Windows.Forms.Label
    $userLabel.Text = "Current User:"
    $userLabel.Font = New-Object System.Drawing.Font("Arial", 12)
    $userLabel.ForeColor = [System.Drawing.Color]::White
    $userLabel.BackColor = [System.Drawing.Color]::Transparent
    $userLabel.Size = New-Object System.Drawing.Size(130, 30)
    $userLabel.Location = New-Object System.Drawing.Point(10, 70)
    $form.Controls.Add($userLabel)

    # Use parameter or fallback to env
    if ([string]::IsNullOrEmpty($currentUser)) {
        $currentUser = $env:USERNAME
    }

    # Current user label
    $currentUserLabel = New-Object System.Windows.Forms.Label
    $currentUserLabel.Text = $currentUser
    $currentUserLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $currentUserLabel.ForeColor = [System.Drawing.Color]::WhiteSmoke
    $currentUserLabel.BackColor = [System.Drawing.Color]::Transparent
    $currentUserLabel.AutoSize = $true
    $currentUserLabel.Location = New-Object System.Drawing.Point(150, 70)
    $form.Controls.Add($currentUserLabel)

    # Preset passwords label
    $presetLabel = New-Object System.Windows.Forms.Label
    $presetLabel.Text = "Quick Select:"
    $presetLabel.Font = New-Object System.Drawing.Font("Arial", 12)
    $presetLabel.ForeColor = [System.Drawing.Color]::White
    $presetLabel.BackColor = [System.Drawing.Color]::Transparent
    $presetLabel.Size = New-Object System.Drawing.Size(130, 30)
    $presetLabel.Location = New-Object System.Drawing.Point(10, 105)
    $form.Controls.Add($presetLabel)

    # Preset passwords dropdown
    $presetComboBox = New-Object System.Windows.Forms.ComboBox
    $presetComboBox.Font = New-Object System.Drawing.Font("Arial", 11)
    $presetComboBox.Size = New-Object System.Drawing.Size(200, 30)
    $presetComboBox.Location = New-Object System.Drawing.Point(150, 105)
    $presetComboBox.BackColor = [System.Drawing.Color]::White
    $presetComboBox.ForeColor = [System.Drawing.Color]::Black
    $presetComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

    # Add preset password options
    $presetComboBox.Items.Add("Custom (enter below)")
    if ($Global:config.userManagement.presetPasswords) {
        $Global:config.userManagement.presetPasswords | ForEach-Object { $presetComboBox.Items.Add($_) }
    }

    $presetComboBox.SelectedIndex = 0
    $form.Controls.Add($presetComboBox)

    # Password label
    $passwordLabel = New-Object System.Windows.Forms.Label
    $passwordLabel.Text = "New Password:"
    $passwordLabel.Font = New-Object System.Drawing.Font("Arial", 12)
    $passwordLabel.ForeColor = [System.Drawing.Color]::White
    $passwordLabel.BackColor = [System.Drawing.Color]::Transparent
    $passwordLabel.Size = New-Object System.Drawing.Size(130, 30)
    $passwordLabel.Location = New-Object System.Drawing.Point(10, 145)
    $form.Controls.Add($passwordLabel)

    # Password textbox
    $passwordTextBox = New-Object System.Windows.Forms.TextBox
    $passwordTextBox.Font = New-Object System.Drawing.Font("Arial", 12)
    $passwordTextBox.Size = New-Object System.Drawing.Size(160, 30)
    $passwordTextBox.Location = New-Object System.Drawing.Point(150, 140)
    $passwordTextBox.BackColor = [System.Drawing.Color]::Black
    $passwordTextBox.ForeColor = [System.Drawing.Color]::Lime
    $passwordTextBox.UseSystemPasswordChar = $false
    $form.Controls.Add($passwordTextBox)

    # Show Password checkbox (default checked)
    $showPasswordCheckBox = New-Object System.Windows.Forms.CheckBox
    $showPasswordCheckBox.Text = "Show"
    $showPasswordCheckBox.Location = New-Object System.Drawing.Point (320, 145)
    $showPasswordCheckBox.Size = New-Object System.Drawing.Size(80, 20)
    $showPasswordCheckBox.ForeColor = [System.Drawing.Color]::White
    $showPasswordCheckBox.Font = New-Object System.Drawing.Font("Arial", 9)
    $showPasswordCheckBox.BackColor = [System.Drawing.Color]::Transparent
    $showPasswordCheckBox.Checked = $true
    $showPasswordCheckBox.Add_CheckedChanged({
            $passwordTextBox.UseSystemPasswordChar = -not $showPasswordCheckBox.Checked
        })
    $form.Controls.Add($showPasswordCheckBox)

    # Event handler for preset selection
    $presetComboBox.Add_SelectedIndexChanged({
            $selectedItem = $presetComboBox.SelectedItem.ToString()
            switch ($selectedItem) {
                "Custom (enter below)" {
                    $passwordTextBox.Text = ""
                    $passwordTextBox.Enabled = $true
                    $passwordTextBox.Focus()
                }
                default {
                    $passwordTextBox.Text = $selectedItem
                    $passwordTextBox.Enabled = $false  # Disable textbox for preset passwords
                }
            }
        })

    # Info label for empty password
    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Text = "Select a preset password or enter your own."
    $infoLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $infoLabel.ForeColor = [System.Drawing.Color]::Red
    $infoLabel.BackColor = [System.Drawing.Color]::Transparent
    $infoLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $infoLabel.Size = New-Object System.Drawing.Size(390, 30)
    $infoLabel.Location = New-Object System.Drawing.Point(0, 175)
    $form.Controls.Add($infoLabel)

    # Set Password button
    $setButton = New-Object System.Windows.Forms.Button
    $setButton.Text = "Set"
    $setButton.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $setButton.ForeColor = [System.Drawing.Color]::White
    $setButton.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 0)
    $setButton.Size = New-Object System.Drawing.Size(180, 40)
    $setButton.Location = New-Object System.Drawing.Point(10, 220)
    $setButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $form.Controls.Add($setButton)

    # Cancel button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $cancelButton.ForeColor = [System.Drawing.Color]::White
    $cancelButton.BackColor = [System.Drawing.Color]::FromArgb(180, 0, 0)
    $cancelButton.Size = New-Object System.Drawing.Size(180, 40)
    $cancelButton.Location = New-Object System.Drawing.Point(200, 220)
    $cancelButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $form.Controls.Add($cancelButton)

    # Set Accept/Cancel button for Enter/Esc
    $form.AcceptButton = $setButton
    $form.CancelButton = $cancelButton

    # Focus on password textbox when form shows
    $form.Add_Shown({
            $passwordTextBox.Focus()
        })

    # Add result variable
    $dialogResult = @{ Action = ""; Password = "" }

    # Set button event
    $setButton.Add_Click({
            $dialogResult.Action = "set"

            # Get password from textbox or handle special cases
            $selectedPreset = $presetComboBox.SelectedItem.ToString()
            if ($selectedPreset -eq "Custom (enter below)") {
                $dialogResult.Password = $passwordTextBox.Text
            }
            else {
                $dialogResult.Password = $selectedPreset
            }

            # Actually set the password here
            # $success = Set-UserPassword -user $currentUser -password $dialogResult.Password
            $securePwd = if ([string]::IsNullOrEmpty($dialogResult.Password)) { $null } else { ConvertTo-SecureString -String $dialogResult.Password -AsPlainText -Force }
            $success = Set-UserPassword -user $currentUser -password $securePwd
            if ($success) {
                if ([string]::IsNullOrEmpty($dialogResult.Password)) {
                    [System.Windows.Forms.MessageBox]::Show("Password has been removed. User '$currentUser' can now log in without a password.", "Password Removed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show("Password has been changed successfully.", "Password Changed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }
            }
            else {
                [System.Windows.Forms.MessageBox]::Show("Error setting password. This operation may require administrative privileges.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }

            $form.Close()
        })

    # Cancel button event
    $cancelButton.Add_Click({
            $dialogResult.Action = "cancel"
            $form.Close()
        })

    $form.Add_FormClosed({
            Show-MainMenu
        })

    # Show the form
    $form.ShowDialog()
    return $dialogResult
}

function Set-UserPassword {
    param ([string]$user, [SecureString]$password)
    try {
        # Ki?m tra xem ng?i dng c ang dng Windows Hello PIN khng
        $pinEnabled = $false
        try {
            $pinProviders = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "SessionData" -ErrorAction Stop
            if ($null -ne $pinProviders) {
                $pinEnabled = $true
                Write-Host "Detected Windows Hello PIN"
            }
        }
        catch { }

        # N?u ang dng PIN, v hi?u ha t?m th?i
        if ($pinEnabled) {
            try {
                # Lu tr?ng thi PIN hi?n t?i
                $pinBackup = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "SessionData" -ErrorAction Stop

                # V hi?u ha t?m th?i PIN
                Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "SessionData" -Value $null -Force
                Write-Host "Temporarily disabled Windows Hello PIN"

                # ?t l?i m?t kh?u
                $result = $false
                if ($null -eq $password) {
                    # Xa m?t kh?u
                    $result = (Start-Process -FilePath "net.exe" -ArgumentList "user `"$user`" `"`"" -WindowStyle Hidden -Wait -PassThru).ExitCode -eq 0
                }
                else {
                    # ?t m?t kh?u m?i
                    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
                    )
                    $result = (Start-Process -FilePath "net.exe" -ArgumentList "user `"$user`" `"$plainPassword`"" -WindowStyle Hidden -Wait -PassThru).ExitCode -eq 0
                    $plainPassword = $null
                    [System.GC]::Collect()
                }

                # Khi ph?c l?i tr?ng thi PIN
                Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "SessionData" -Value $pinBackup.SessionData -Type Binary -Force
                Write-Host "Restored Windows Hello PIN settings"

                if ($result) {
                    Write-Host "Password updated successfully for PIN user"
                    return $true
                }
            }
            catch {
                Write-Error "Error processing PIN user: $_"
                return $false
            }
        }

        # N?u khng dng PIN ho?c x? l? PIN th?t b?i, dng phng php thng th?ng
        $methods = @(
            {
                # Phng php 1: S? d?ng LocalAccount module
                try {
                    Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction Stop
                    $localUser = Get-LocalUser -Name $user -ErrorAction Stop
                    if ($null -eq $password) {
                        $localUser | Set-LocalUser -NoPassword
                    }
                    else {
                        $localUser | Set-LocalUser -Password $password
                    }
                    Write-Host "Password updated successfully for LocalAccount module"
                    return $true
                }
                catch { throw "LocalAccount module failed: $_" }
            },
            {
                # Phng php 2: S? d?ng ADSI
                try {
                    $userAccount = [ADSI]"WinNT://$env:COMPUTERNAME/$user,User"
                    if ($null -eq $password) {
                        $userAccount.SetPassword("")
                    }
                    else {
                        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
                        )
                        $userAccount.SetPassword($plainPassword)
                        $plainPassword = $null
                        [System.GC]::Collect()
                    }
                    $userAccount.CommitChanges()
                    Write-Host "Password updated successfully for ADSI"
                    return $true
                }
                catch { throw "ADSI method failed: $_" }
            },
            {
                # Phng php 3: S? d?ng net user
                try {
                    if ($null -eq $password) {
                        $process = Start-Process -FilePath "net.exe" -ArgumentList "user `"$user`" `"`"" -WindowStyle Hidden -Wait -PassThru
                    }
                    else {
                        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
                        )
                        $process = Start-Process -FilePath "net.exe" -ArgumentList "user `"$user`" `"$plainPassword`"" -WindowStyle Hidden -Wait -PassThru
                        $plainPassword = $null
                        [System.GC]::Collect()
                    }

                    if ($process.ExitCode -ne 0) { throw "net.exe exited with code $($process.ExitCode)" }
                    Write-Host "Password updated successfully for net user"
                    return $true
                }
                catch { throw "net user method failed: $_" }
            }
        )

        # Th? l?n l?t t?ng phng php
        foreach ($method in $methods) {
            try {
                $result = & $method
                if ($result -eq $true) {
                    return $true
                }
            }
            catch {
                Write-Warning "Method failed: $_"
            }
        }

        throw "All methods failed"

    }
    catch {
        Write-Error "Error: $_"
        return $false
    }
}

function Remove-UserPassword {
    param([string]$user)
    try {
        return (Set-UserPassword -user $user -password $null)
    }
    catch {
        Write-Error "Error: $_"
        return $false
    }
}

function Invoke-SetPasswordDialog {
    param([string]$currentUser, [System.Windows.Forms.RichTextBox]$statusTextBox, [bool]$showMenuAfter = $false)$result = Show-SetPasswordForm -currentUser $currentUser -statusTextBox $statusTextBox
    if ($result.Action -eq "set") {
        $securePwd = if ([string]::IsNullOrEmpty($result.Password)) { $null } else { ConvertTo-SecureString -String $result.Password -AsPlainText -Force }
        $success = Set-UserPassword -user $currentUser -password $securePwd
        if ($success) {
            if ([string]::IsNullOrEmpty($result.Password)) {
                [System.Windows.Forms.MessageBox]::Show("Password has been removed. User '$currentUser' can now log in without a password.", "Password Removed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
            else {
                [System.Windows.Forms.MessageBox]::Show("Password has been changed.", "Password Change", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Error setting password. This operation may require administrative privileges.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    elseif ($result.Action -eq "remove") {
        $success = Remove-UserPassword -user $currentUser
        if ($success) {
            [System.Windows.Forms.MessageBox]::Show("Password has been removed. User '$currentUser' can now log in without a password.", "Password Removed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Error removing password. This operation may require administrative privileges.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    if ($showMenuAfter -and -not $script:form.Visible) {
        Show-MainMenu
    }
}


# [9] Domain Management Functions
$script:DomainConfig = @{FormWidth = 500; FormHeight = 450; FormHeightMinimal = 380; ButtonY = 350; ButtonYMinimal = 280; ControlSpacing = 40; DefaultWorkgroup = "WORKGROUP" }


function Get-ComputerDomainInfo {
    try {
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
        return @{
            ComputerName   = $env:COMPUTERNAME
            Domain         = $computerSystem.Domain
            IsPartOfDomain = $computerSystem.PartOfDomain
            Success        = $true
        }
    }
    catch {
        Write-Warning "Failed to retrieve computer domain information: $_"
        return @{
            ComputerName   = $env:COMPUTERNAME
            Domain         = "Unknown"
            IsPartOfDomain = $false
            Success        = $false
        }
    }
}

function New-DomainManagementLabel {
    param([string]$Text, [int]$X, [int]$Y, [int]$Width, [int]$Height, [int]$FontSize = 12, [System.Drawing.FontStyle]$FontStyle = [System.Drawing.FontStyle]::Regular)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Font = New-Object System.Drawing.Font("Arial", $FontSize, $FontStyle)
    $label.ForeColor = [System.Drawing.Color]::White
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.Location = New-Object System.Drawing.Point($X, $Y)

    return $label
}

function New-DomainManagementTextBox {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height, [bool]$IsPassword = $false, [string]$DefaultText = "")
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Font = New-Object System.Drawing.Font("Arial", 12)
    $textBox.Size = New-Object System.Drawing.Size($Width, $Height)
    $textBox.Location = New-Object System.Drawing.Point($X, $Y)
    $textBox.BackColor = [System.Drawing.Color]::White
    $textBox.ForeColor = [System.Drawing.Color]::Black
    $textBox.Text = $DefaultText
    if ($IsPassword) { $textBox.UseSystemPasswordChar = $true }
    return $textBox
}

function New-DomainManagementRadioButton {
    param([string]$Text, [int]$X, [int]$Y, [int]$Width, [int]$Height, [bool]$IsChecked = $false, [bool]$IsEnabled = $true)
    $radioButton = New-Object System.Windows.Forms.RadioButton
    $radioButton.Text = $Text
    $radioButton.Font = New-Object System.Drawing.Font("Arial", 12)
    $radioButton.ForeColor = [System.Drawing.Color]::White
    $radioButton.Location = New-Object System.Drawing.Point($X, $Y)
    $radioButton.Size = New-Object System.Drawing.Size($Width, $Height)
    $radioButton.BackColor = [System.Drawing.Color]::Black
    $radioButton.Checked = $IsChecked
    $radioButton.Enabled = $IsEnabled
    return $radioButton
}

function Set-DomainFormLayout {
    param([hashtable]$FormControls, [string]$OperationType)
    switch ($OperationType) {
        'Domain' {
            $FormControls.NameLabel.Text = "Domain Name:"
            $FormControls.NameLabel.BackColor = [System.Drawing.Color]::Transparent
            # Set domain name - reset to default if it's workgroup name or empty
            $currentText = $FormControls.NameTextBox.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($currentText) -or $currentText -eq "WORKGROUP") {
                $FormControls.NameTextBox.Text = $Global:config.domain.name
            }
            $FormControls.UsernameLabel.Visible = $true
            $FormControls.UsernameTextBox.Visible = $true
            # Set username - reset to default if empty
            if ([string]::IsNullOrWhiteSpace($FormControls.UsernameTextBox.Text)) {
                $FormControls.UsernameTextBox.Text = $Global:config.domain.defaultUser
            }
            $FormControls.PasswordLabel.Visible = $true
            $FormControls.PasswordTextBox.Visible = $true
            $FormControls.JoinButton.Text = "Join"
            $FormControls.JoinButton.Location = New-Object System.Drawing.Point(35, $script:DomainConfig.ButtonY)
            $FormControls.CancelButton.Location = New-Object System.Drawing.Point(250, $script:DomainConfig.ButtonY)
            $FormControls.Form.Size = New-Object System.Drawing.Size($script:DomainConfig.FormWidth, $script:DomainConfig.FormHeight)
        }
        'Workgroup' {
            $FormControls.NameLabel.Text = "Workgroup Name:"
            $FormControls.NameLabel.BackColor = [System.Drawing.Color]::Transparent
            $FormControls.NameTextBox.Text = $script:DomainConfig.DefaultWorkgroup
            $FormControls.UsernameLabel.Visible = $false
            $FormControls.UsernameTextBox.Visible = $false
            $FormControls.PasswordLabel.Visible = $false
            $FormControls.PasswordTextBox.Visible = $false
            $FormControls.JoinButton.Text = "Join"
            $FormControls.JoinButton.Location = New-Object System.Drawing.Point(35, $script:DomainConfig.ButtonYMinimal)
            $FormControls.CancelButton.Location = New-Object System.Drawing.Point(250, $script:DomainConfig.ButtonYMinimal)
            $FormControls.Form.Size = New-Object System.Drawing.Size($script:DomainConfig.FormWidth, $script:DomainConfig.FormHeightMinimal)
        }

    }
}

function Test-DomainJoinInputs {
    param([string]$DomainName, [string]$Username, [SecureString]$Password)

    if ([string]::IsNullOrWhiteSpace($DomainName)) {
        return @{
            IsValid      = $false
            ErrorMessage = "Domain name cannot be empty."
        }
    }

    if ([string]::IsNullOrWhiteSpace($Username)) {
        return @{
            IsValid      = $false
            ErrorMessage = "Username is required for domain join."
        }
    }

    if (-not $Password -or $Password.Length -eq 0) {
        return @{
            IsValid      = $false
            ErrorMessage = "Password is required for domain join."
        }
    }

    if ($DomainName -notmatch '^[a-zA-Z0-9.-]+$') {
        return @{
            IsValid      = $false
            ErrorMessage = "Domain name contains invalid characters. Use only letters, numbers, dots, and hyphens."
        }
    }

    return @{
        IsValid      = $true
        ErrorMessage = ""
    }
}

function Test-WorkgroupInputs {
    param([string]$WorkgroupName)
    if ([string]::IsNullOrWhiteSpace($WorkgroupName)) {
        return @{
            IsValid      = $false
            ErrorMessage = "Workgroup name cannot be empty."
        }
    }

    # Workgroup name validation (NetBIOS naming rules)
    if ($WorkgroupName.Length -gt 15) {
        return @{
            IsValid      = $false
            ErrorMessage = "Workgroup name cannot exceed 15 characters."
        }
    }

    if ($WorkgroupName -match '[\\/:*?"<>|]') {
        return @{
            IsValid      = $false
            ErrorMessage = "Workgroup name contains invalid characters."
        }
    }

    return @{
        IsValid      = $true
        ErrorMessage = ""
    }
}

function Invoke-ElevatedDomainCommand {
    param([string]$Command, [string]$OperationType)
    try {
        # Create a temporary PowerShell script file
        $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"

        # Write the command to the script file with proper error handling (NO PASSWORD DISPLAY)
        $scriptContent = @"
try {
    Write-Host "Starting $OperationType operation..." -ForegroundColor Green
    Write-Host "Executing domain join command..." -ForegroundColor Yellow

    # Execute the command (password is hidden in the command itself)
    Invoke-Expression $Command

    Write-Host "$OperationType completed successfully!" -ForegroundColor Green
    Write-Host "Press any key to continue..."
    `$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}
catch {
    Write-Host "Error during $OperationType operation:" -ForegroundColor Red
    Write-Host `$_.Exception.Message -ForegroundColor Red
    Write-Host "Press any key to continue..."
    `$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
"@

        Set-Content -Path $tempScript -Value $scriptContent -Encoding UTF8

        # Create process start info for elevated execution
        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName = "powershell.exe"
        $processStartInfo.Arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$tempScript`""
        $processStartInfo.UseShellExecute = $true
        $processStartInfo.Verb = "runas"
        $processStartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal

        # Start the elevated process and wait for completion
        $process = [System.Diagnostics.Process]::Start($processStartInfo)

        if ($null -eq $process) { throw "Failed to start elevated process - User may have cancelled UAC prompt" }

        # Wait for the process to complete (with timeout)
        $timeout = 120000 # 2 minutes
        $completed = $process.WaitForExit($timeout)

        # Clean up temp file
        if (Test-Path $tempScript) { Remove-Item $tempScript -Force -ErrorAction SilentlyContinue }

        if (-not $completed) {
            # Process timed out
            try { $process.Kill() } catch { }
            [System.Windows.Forms.MessageBox]::Show(
                "$OperationType operation timed out after 2 minutes.`n`nThis may indicate:`n- Network connectivity issues`n- Invalid credentials`n- Domain controller unavailable",
                "Timeout - $OperationType",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return $false
        }

        $exitCode = $process.ExitCode

        if ($exitCode -eq 0) {
            # Success - show restart confirmation
            $restartResult = [System.Windows.Forms.MessageBox]::Show(
                "$OperationType completed successfully!`n`nYour computer needs to restart to apply the changes.`n`nRestart now?",
                "Success - $OperationType",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($restartResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                # Force restart
                Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t 10 /c `"Restarting to complete $OperationType`"" -WindowStyle Hidden
            }
            return $true
        }
        else {
            # Failed
            [System.Windows.Forms.MessageBox]::Show(
                "$OperationType operation failed (Exit Code: $exitCode).`n`nCommon causes:`n- Invalid username or password`n- Domain not reachable`n- Insufficient permissions`n- Computer already joined to domain",
                "Failed - $OperationType",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            return $false
        }
    }
    catch {
        Write-Error "Failed to execute elevated domain command: $_"
        [System.Windows.Forms.MessageBox]::Show(
            "Error starting $OperationType operation: $_`n`nPossible causes:`n- UAC prompt was cancelled`n- Insufficient privileges`n- System error",
            "Error - $OperationType",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
}

function Invoke-DomainJoinOperation {
    param([string]$DomainName, [string]$Username, [SecureString]$Password)
    # Validate inputs
    $validation = Test-DomainJoinInputs -DomainName $DomainName -Username $Username -Password $Password
    if (-not $validation.IsValid) {
        [System.Windows.Forms.MessageBox]::Show(
            $validation.ErrorMessage,
            "Validation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }

    # SecureString length check (no plaintext exposure)
    $pwdPtr = [IntPtr]::Zero
    try {
        $pwdPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        if ([Runtime.InteropServices.Marshal]::PtrToStringUni($pwdPtr).Length -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "Password cannot be empty.",
                "Validation Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            return $false
        }
    }
    finally { if ($pwdPtr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pwdPtr) } }

    # Test domain connectivity first (like sysdm.cpl does)
    try {
        Write-Host "Testing domain connectivity to $DomainName..."
        $testConnection = Test-NetConnection -ComputerName $DomainName -Port 389 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if (-not $testConnection) {
            $confirmResult = [System.Windows.Forms.MessageBox]::Show(
                "Cannot reach domain '$DomainName' on port 389 (LDAP).`n`nThis may indicate:`n- Domain name is incorrect`n- Network connectivity issues`n- DNS resolution problems`n`nDo you want to continue anyway?",
                "Domain Connectivity Warning",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )

            if ($confirmResult -eq [System.Windows.Forms.DialogResult]::No) { return $false }
        }
    }
    catch { Write-Warning "Could not test domain connectivity: $_" }

    # Convert SecureString to plain in-memory just to compose the elevated command, then scrub
    $pwdBstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    try {
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringUni($pwdBstr)

        # Escape special characters for safe embedding
        $escapedPassword = $plain -replace "'", "''" -replace '"', '""' -replace '`', '``' -replace '\$', '`$'

        # Build domain join command inside the elevated process: it reconstructs a SecureString there
        $command = "`$securePassword = ConvertTo-SecureString '$escapedPassword' -AsPlainText -Force; " +
        "`$credential = New-Object System.Management.Automation.PSCredential('$Username', `$securePassword); " +
        "Add-Computer -DomainName '$DomainName' -Credential `$credential -Force -Verbose"
    }
    finally { if ($pwdBstr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pwdBstr) } }
    return Invoke-ElevatedDomainCommand -Command $command -OperationType "DomainJoin"
}

function Invoke-WorkgroupJoinOperation {
    param ([string]$WorkgroupName)
    # Validate inputs
    $validation = Test-WorkgroupInputs -WorkgroupName $WorkgroupName
    if (-not $validation.IsValid) {
        [System.Windows.Forms.MessageBox]::Show(
            $validation.ErrorMessage,
            "Validation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }

    # Build workgroup join command
    $command = "Add-Computer -WorkgroupName '$WorkgroupName' -Restart -Force"

    return Invoke-ElevatedDomainCommand -Command $command -OperationType "WorkgroupJoin"
}

function Show-DomainManagementForm {
    param ([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox)
    Hide-MainMenu

    $computerInfo = Get-ComputerDomainInfo

    # Create main form
    $joinForm = New-Object System.Windows.Forms.Form
    $joinForm.Text = "Domain Management"
    $joinForm.Size = New-Object System.Drawing.Size($script:DomainConfig.FormWidth, $script:DomainConfig.FormHeight)
    $joinForm.StartPosition = "CenterScreen"
    $joinForm.BackColor = [System.Drawing.Color]::Black
    $joinForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

    Add-GradientBackground -form $joinForm

    # Create title label
    $titleLabel = New-DomainManagementLabel -Text "DOMAIN MANAGEMENT" -X 10 -Y 20 -Width 480 -Height 40 -FontSize 16 -FontStyle ([System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 0)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $joinForm.Controls.Add($titleLabel)

    Add-TitleAnimation -titleLabel $titleLabel

    # Current computer name label
    $boldFont = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $currentNameBoldLabel = New-DomainManagementLabel -Text $computerInfo.ComputerName -X 170 -Y 70 -Width 320 -Height 30 -FontSize 12 -FontStyle ([System.Drawing.FontStyle]::Bold)
    $currentNameBoldLabel.Font = $boldFont
    $currentNameBoldLabel.ForeColor = [System.Drawing.Color]::WhiteSmoke
    $currentNameBoldLabel.BackColor = [System.Drawing.Color]::Transparent
    $currentNameBoldLabel.AutoSize = $true
    $currentNameBoldLabel.Location = New-Object System.Drawing.Point(180, 68)
    $joinForm.Controls.Add($currentNameBoldLabel)

    # Current domain/workgroup name label
    if (-not $computerInfo.IsPartOfDomain -or $computerInfo.Domain -eq $computerInfo.ComputerName) { $domainDisplay = "$($computerInfo.Domain)" }
    else { $domainDisplay = $computerInfo.Domain }

    $domainBoldLabel = New-DomainManagementLabel -Text $domainDisplay -X 170 -Y 100 -Width 320 -Height 30 -FontSize 12 -FontStyle ([System.Drawing.FontStyle]::Bold)
    $domainBoldLabel.Font = $boldFont
    $domainBoldLabel.ForeColor = [System.Drawing.Color]::WhiteSmoke
    $domainBoldLabel.BackColor = [System.Drawing.Color]::Transparent
    $joinForm.Controls.Add($domainBoldLabel)

    # Current computer info labels
    $currentLabel = New-DomainManagementLabel -Text "Current Name:" -X 10 -Y 70 -Width 480 -Height 30 -FontSize 12
    $currentLabel.BackColor = [System.Drawing.Color]::Transparent
    $joinForm.Controls.Add($currentLabel)

    $domainLabel = New-DomainManagementLabel -Text "Currently Joined:" -X 10 -Y 100 -Width 480 -Height 30 -FontSize 12
    $domainLabel.BackColor = [System.Drawing.Color]::Transparent
    $joinForm.Controls.Add($domainLabel)

    # Create radio buttons group
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Text = "Select Option"
    $groupBox.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $groupBox.ForeColor = [System.Drawing.Color]::Lime
    $groupBox.BackColor = [System.Drawing.Color]::Transparent
    $groupBox.Size = New-Object System.Drawing.Size(460, 80)
    $groupBox.Location = New-Object System.Drawing.Point(10, 140)

    $radioDomain = New-DomainManagementRadioButton -Text "Join Domain" -X 55 -Y 30 -Width 120 -Height 30 -IsChecked $true
    $radioDomain.BackColor = [System.Drawing.Color]::Transparent
    $radioWorkgroup = New-DomainManagementRadioButton -Text "Join Workgroup" -X 275 -Y 30 -Width 140 -Height 30
    $radioWorkgroup.BackColor = [System.Drawing.Color]::Transparent

    $groupBox.Controls.Add($radioDomain)
    $groupBox.Controls.Add($radioWorkgroup)
    $joinForm.Controls.Add($groupBox)

    # Create input controls
    $nameLabel = New-DomainManagementLabel -Text "Domain Name:" -X 10 -Y 230 -Width 150 -Height 30
    $nameLabel.BackColor = [System.Drawing.Color]::Transparent
    $nameTextBox = New-DomainManagementTextBox -X 170 -Y 230 -Width 300 -Height 30
    $nameTextBox.Text = $Global:config.domain.name  # Default domain name

    $usernameLabel = New-DomainManagementLabel -Text "Username:" -X 10 -Y 270 -Width 150 -Height 30
    $usernameLabel.BackColor = [System.Drawing.Color]::Transparent
    $usernameTextBox = New-DomainManagementTextBox -X 170 -Y 270 -Width 300 -Height 30
    $usernameTextBox.Text = $Global:config.domain.defaultUser  # Default username

    $passwordLabel = New-DomainManagementLabel -Text "Password:" -X 10 -Y 310 -Width 150 -Height 30
    $passwordLabel.BackColor = [System.Drawing.Color]::Transparent
    $passwordTextBox = New-DomainManagementTextBox -X 170 -Y 310 -Width 300 -Height 30 -IsPassword $true

    $joinForm.Controls.AddRange(@($nameLabel, $nameTextBox, $usernameLabel, $usernameTextBox, $passwordLabel, $passwordTextBox))

    # Create buttons
    $joinButton = New-DynamicButton -text "Join" -x 35 -y $script:DomainConfig.ButtonY -width 200 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 180, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 220, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 140, 0)) -textColor ([System.Drawing.Color]::White) -fontSize 12 -fontStyle ([System.Drawing.FontStyle]::Bold)

    $cancelButton = New-DynamicButton -text "Cancel" -x 250 -y $script:DomainConfig.ButtonY -width 200 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(180, 0, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(220, 0, 0)) -pressColor ([System.Drawing.Color]::FromArgb(120, 0, 0)) -clickAction {
        Add-Status "Domain join was cancelled by user." $statusTextBox
        $joinForm.Close()
    }

    $joinForm.Controls.AddRange(@($joinButton, $cancelButton))

    # Store form controls for easy access
    $formControls = @{
        Form            = $joinForm
        NameLabel       = $nameLabel
        NameTextBox     = $nameTextBox
        UsernameLabel   = $usernameLabel
        UsernameTextBox = $usernameTextBox
        PasswordLabel   = $passwordLabel
        PasswordTextBox = $passwordTextBox
        JoinButton      = $joinButton
        CancelButton    = $cancelButton
    }

    # Event handlers for radio buttons
    $radioDomain.Add_CheckedChanged({ if ($radioDomain.Checked) { Set-DomainFormLayout -FormControls $formControls -OperationType 'Domain' } })

    $radioWorkgroup.Add_CheckedChanged({ if ($radioWorkgroup.Checked) { Set-DomainFormLayout -FormControls $formControls -OperationType 'Workgroup' } })

    # Join button click handler
    $joinButton.Add_Click({
            $name = $nameTextBox.Text.Trim()
            $success = $false

            try {
                if ($radioDomain.Checked) {
                    $sec = ConvertTo-SecureString $passwordTextBox.Text -AsPlainText -Force
                    $success = Invoke-DomainJoinOperation -DomainName $name -Username $usernameTextBox.Text.Trim() -Password $sec
                }
                elseif ($radioWorkgroup.Checked) {
                    $success = Invoke-WorkgroupJoinOperation -WorkgroupName $name
                }

                if ($success) {
                    $joinForm.Close()
                }
            }
            catch {
                Write-Error "Unexpected error in domain management operation: $_"
                [System.Windows.Forms.MessageBox]::Show(
                    "An unexpected error occurred: $_",
                    "Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
        })

    # Set form behavior
    $joinForm.AcceptButton = $joinButton
    $joinForm.CancelButton = $cancelButton
    $joinForm.Add_FormClosed({ Show-MainMenu })

    # Show the form
    $joinForm.ShowDialog()
}

function Invoke-RenamebyDevice {
    param($deviceType, $statusTextBox)
    Add-Status "Starting Rename Device dialog..." $statusTextBox
    Invoke-RenameDialog -DeviceType $deviceType -StatusTextBox $statusTextBox -IsChildWindow $true
    return $true
}

function Invoke-UserPasswordManagement {
    param($deviceType, $statusTextBox)
    Add-Status "Managing user password..." $statusTextBox
    Invoke-SetPasswordDialog -currentUser $env:USERNAME -statusTextBox $statusTextBox
    return $true
}

function Select-DeviceType {
    param($Owner)
    
    # 1. Auto-detect
    $detectedType = "Desktop"
    try {
        $chassis = Get-WmiObject Win32_SystemEnclosure -ErrorAction SilentlyContinue
        if ($chassis.ChassisTypes -contains 9 -or $chassis.ChassisTypes -contains 10) {
            $detectedType = "Laptop"
        }
    }
    catch {}

    # 2. Show Confirmation Dialog
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Device Type Selection"
    $dialog.Size = New-Object System.Drawing.Size(400, 220)
    $dialog.StartPosition = "CenterScreen"
    $dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = [System.Drawing.Color]::Black
    
    # Gradient background
    Add-GradientBackground -form $dialog

    # Label
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Detected System Type: $detectedType`n`nPlease confirm or select the correct device type:"
    $label.Font = New-Object System.Drawing.Font("Arial", 11)
    $label.ForeColor = [System.Drawing.Color]::White
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(350, 60)
    $label.BackColor = [System.Drawing.Color]::Transparent
    $dialog.Controls.Add($label)

    # Radio Buttons
    $radioDesktop = New-Object System.Windows.Forms.RadioButton
    $radioDesktop.Text = "Desktop"
    $radioDesktop.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $radioDesktop.ForeColor = [System.Drawing.Color]::Lime
    $radioDesktop.Location = New-Object System.Drawing.Point(50, 90)
    $radioDesktop.Size = New-Object System.Drawing.Size(120, 30)
    $radioDesktop.BackColor = [System.Drawing.Color]::Transparent
    
    $radioLaptop = New-Object System.Windows.Forms.RadioButton
    $radioLaptop.Text = "Laptop"
    $radioLaptop.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $radioLaptop.ForeColor = [System.Drawing.Color]::Lime
    $radioLaptop.Location = New-Object System.Drawing.Point(200, 90)
    $radioLaptop.Size = New-Object System.Drawing.Size(120, 30)
    $radioLaptop.BackColor = [System.Drawing.Color]::Transparent

    if ($detectedType -eq "Laptop") { $radioLaptop.Checked = $true } else { $radioDesktop.Checked = $true }

    $dialog.Controls.Add($radioDesktop)
    $dialog.Controls.Add($radioLaptop)

    # Buttons
    $btnOK = New-DynamicButton -text "OK" -x 80 -y 130 -width 100 -height 35 -normalColor ([System.Drawing.Color]::FromArgb(0, 128, 0)) -clickAction { $dialog.DialogResult = [System.Windows.Forms.DialogResult]::OK; $dialog.Close() }
    $btnCancel = New-DynamicButton -text "Cancel" -x 200 -y 130 -width 100 -height 35 -normalColor ([System.Drawing.Color]::FromArgb(128, 0, 0)) -clickAction { $dialog.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $dialog.Close() }
    
    $dialog.Controls.Add($btnOK)
    $dialog.Controls.Add($btnCancel)
    $dialog.AcceptButton = $btnOK
    $dialog.CancelButton = $btnCancel

    if ($Owner) { $result = $dialog.ShowDialog($Owner) } else { $result = $dialog.ShowDialog() }

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($radioLaptop.Checked) { return "Laptop" }
        return "Desktop"
    }
    return $null
}

Export-ModuleMember -Function Invoke-RenameDialog, Show-SetPasswordForm, Set-UserPassword, Remove-UserPassword, Invoke-SetPasswordDialog, Get-ComputerDomainInfo, New-DomainManagementLabel, New-DomainManagementTextBox, New-DomainManagementRadioButton, Set-DomainFormLayout, Test-DomainJoinInputs, Test-WorkgroupInputs, Invoke-ElevatedDomainCommand, Invoke-DomainJoinOperation, Invoke-WorkgroupJoinOperation, Show-DomainManagementForm, Invoke-RenamebyDevice, Invoke-UserPasswordManagement, Select-DeviceType
