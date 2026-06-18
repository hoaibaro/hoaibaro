function Invoke-SetTimezonePower {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        Add-Status "Setting time zone to SE Asia Standard Time..." $statusTextBox ([System.Drawing.Color]::Gray)

        # Set timezone to SE Asia Standard Time
        Start-Process -FilePath "tzutil.exe" -ArgumentList "/s `"SE Asia Standard Time`"" -Wait -NoNewWindow

        # Configure Windows Time service
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\w32time\Parameters" -Name "Type" -Value "NTP" -Type String -ErrorAction SilentlyContinue

        try {
            # Resync time
            Start-Process -FilePath "w32tm.exe" -ArgumentList "/resync" -Wait -NoNewWindow
        }
        catch {
            Add-Status "Warning: Could not sync time. $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # Enable automatic time zone updates
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name "Start" -Value 2 -Type DWord -ErrorAction SilentlyContinue

        Add-Status "Configuring Power Options..." $statusTextBox
        
        # Create power commands
        $powerCommands = @(
            "/SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS LIDACTION 0",
            "/SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS LIDACTION 0",
            "/SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0",
            "/SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0",
            "/SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 0",
            "/SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 0",
            "/SETACVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0",
            "/SETDCVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0",
            "/SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0",
            "/SETDCVALUEINDEX SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0",
            "/SETACTIVE SCHEME_CURRENT"
        )

        foreach ($cmdArgs in $powerCommands) {
            try {
                $p = Start-Process -FilePath "powercfg.exe" -ArgumentList $cmdArgs -Wait -NoNewWindow -PassThru
                if ($p.ExitCode -ne 0) {
                    Add-Status "PowerCfg Error ($cmdArgs): Exit Code $($p.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            catch {
                Add-Status "Failed to run powercfg $cmdArgs : $_" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }

        Add-Status "Time zone, power options completed successfully!!!" $statusTextBox
    }
    catch {
        Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-FirewallOn {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        Add-Status "Turning on the firewall..." $statusTextBox

        $p = Start-Process -FilePath "netsh.exe" -ArgumentList "advfirewall set allprofiles state on" -Wait -NoNewWindow -PassThru
        
        if ($p.ExitCode -eq 0) {
            Add-Status "Firewall has been turned on successfully!!!" $statusTextBox
        }
        else {
            Add-Status "Failed to turn on firewall. Exit Code: $($p.ExitCode)" $statusTextBox ([System.Drawing.Color]::Red)
        }
    }
    catch {
        Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-FirewallOff {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        Add-Status "Turning off the firewall..." $statusTextBox

        $p = Start-Process -FilePath "netsh.exe" -ArgumentList "advfirewall set allprofiles state off" -Wait -NoNewWindow -PassThru

        if ($p.ExitCode -eq 0) {
            Add-Status "Firewall has been turned off successfully!" $statusTextBox
        }
        else {
            Add-Status "Failed to turn off firewall. Exit Code: $($p.ExitCode)" $statusTextBox ([System.Drawing.Color]::Red)
        }
    }
    catch {
        Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-PowerOptionsDialog {
    Hide-MainMenu
    # Create Power Options form
    $powerForm = New-Object System.Windows.Forms.Form
    $powerForm.Text = "Power Options"
    $powerForm.Size = New-Object System.Drawing.Size(500, 400)
    $powerForm.StartPosition = "CenterScreen"
    $powerForm.BackColor = [System.Drawing.Color]::Black
    $powerForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $powerForm.MaximizeBox = $false
    $powerForm.MinimizeBox = $false

    # Apply gradient background using global function
    Add-GradientBackground -form $powerForm

    # Title label with animation
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "POWER OPTIONS"
    $titleLabel.Location = New-Object System.Drawing.Point(145, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(200, 40)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $titleLabel.Padding = New-Object System.Windows.Forms.Padding(5)

    Add-TitleAnimation -titleLabel $titleLabel

    $powerForm.Controls.Add($titleLabel)

    # Status text box
    $statusTextBox = New-Object System.Windows.Forms.RichTextBox
    $statusTextBox.Multiline = $true
    $statusTextBox.ScrollBars = "Vertical"
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 150)
    $statusTextBox.Size = New-Object System.Drawing.Size(465, 200)
    $statusTextBox.BackColor = [System.Drawing.Color]::Black
    $statusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $statusTextBox.Text = "Status messages will appear here..."
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusTextBox.ReadOnly = $true
    $statusTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

    $powerForm.Controls.Add($statusTextBox)

    # Turn on Firewall button
    $btnFirewallOn = New-DynamicButton -text "Turn on Firewall" -x 10 -y 50 -width 230 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        Invoke-FirewallOn -statusTextBox $statusTextBox
    }
    $powerForm.Controls.Add($btnFirewallOn)

    # Turn off Firewall button
    $btnFirewallOff = New-DynamicButton -text "Turn off Firewall" -x 245 -y 50 -width 230 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        Invoke-FirewallOff -statusTextBox $statusTextBox
    }
    $powerForm.Controls.Add($btnFirewallOff)

    # Set Time/Timezone and Power Options button
    $btnTimeAndPower = New-DynamicButton -text "Time/Timezone and Power" -x 10 -y 100 -width 465 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
        Invoke-SetTimezonePower -statusTextBox $statusTextBox
    }
    $powerForm.Controls.Add($btnTimeAndPower)

    # Press ESC to close form
    $powerForm.Add_KeyDown({
            param($s, $e)
            if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                $powerForm.Close()
            }
        })

    # Enable key events
    $powerForm.KeyPreview = $true

    # Cleanup timer when form is closed
    $powerForm.Add_FormClosed({
            Show-MainMenu
        })

    # Show the form
    $powerForm.ShowDialog()
}

function Invoke-SystemCleanup {
    param([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox)
    Add-Status "Starting System Cleanup (Power & Timezone)..." $statusTextBox ([System.Drawing.Color]::Gray)
    Invoke-SetTimezonePower -statusTextBox $statusTextBox
    Invoke-FirewallOff -statusTextBox $statusTextBox
    return $true
}


Export-ModuleMember -Function Invoke-SetTimezonePower, Invoke-FirewallOn, Invoke-FirewallOff, Invoke-PowerOptionsDialog, Invoke-SystemCleanup

