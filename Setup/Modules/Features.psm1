# [6] Features Functions
function Invoke-WindowsFeaturesConfiguration {
    param ([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # --- 1. Check and Enable Required Features ---
        Invoke-EnableWindowsFeatures $statusTextBox
        # --- 2. Check and Disable Unnecessary Features ---
        Invoke-DisableWindowsFeatures $statusTextBox
        return $true
    }
    catch {
        Add-Status "ERROR: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

function Invoke-FeaturesDialog {
    param($mainForm)

    Hide-MainMenu -mainForm $mainForm
    # Create features configuration form
    $featuresForm = New-Object System.Windows.Forms.Form
    $featuresForm.Text = "Windows Features Configuration"
    $featuresForm.Size = New-Object System.Drawing.Size(485, 390)
    $featuresForm.StartPosition = "CenterScreen"
    $featuresForm.BackColor = [System.Drawing.Color]::Black
    $featuresForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $featuresForm.MaximizeBox = $false
    $featuresForm.MinimizeBox = $false

    Add-GradientBackground -form $featuresForm -topColor ([System.Drawing.Color]::FromArgb(0, 0, 0)) -bottomColor ([System.Drawing.Color]::FromArgb(0, 40, 0))

    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "WINDOWS FEATURES CONFIGURATION"
    $titleLabel.Location = New-Object System.Drawing.Point(0, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(470, 35)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 0)
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $featuresForm.Controls.Add($titleLabel)

    # Add animation to the title
    Add-TitleAnimation -titleLabel $titleLabel

    # Status textbox
    $statusTextBox = New-Object System.Windows.Forms.RichTextBox
    $statusTextBox.Multiline = $true
    $statusTextBox.ScrollBars = "Vertical"
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 70)
    $statusTextBox.Size = New-Object System.Drawing.Size(450, 220)
    $statusTextBox.BackColor = [System.Drawing.Color]::Black
    $statusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusTextBox.ReadOnly = $true
    $statusTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $statusTextBox.Text = "Ready to configure Windows Features..."
    $featuresForm.Controls.Add($statusTextBox)

    # Start Configuration button
    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Text = "Start"
    $startButton.Location = New-Object System.Drawing.Point(10, 300)
    $startButton.Size = New-Object System.Drawing.Size(220, 40)
    $startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 0)
    $startButton.ForeColor = [System.Drawing.Color]::White
    $startButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $startButton.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
    $startButton.FlatAppearance.BorderSize = 1
    $startButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 255, 0)
    $startButton.Add_Click({
            try {
                $startButton.Enabled = $false
                $startButton.Text = "Running..."

                # Clear status textbox
                $statusTextBox.Clear()
                Add-Status "Starting Windows Features Configuration..." $statusTextBox
                [System.Windows.Forms.Application]::DoEvents()

                # Run Windows Features Configuration
                $result = Invoke-WindowsFeaturesConfiguration -deviceType "General" -statusTextBox $statusTextBox

                if ($result) {
                    Add-Status "Windows Features configuration completed !!!" $statusTextBox
                    $startButton.Text = "Completed"
                    $startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 0)
                }
                else {
                    Add-Status "Windows Features configuration failed!" $statusTextBox ([System.Drawing.Color]::Red)
                    $startButton.Text = "Failed"
                    $startButton.BackColor = [System.Drawing.Color]::FromArgb(150, 0, 0)
                }

            }
            catch {
                Add-Status "ERROR: $_" $statusTextBox ([System.Drawing.Color]::Red)
                $startButton.Text = "Error Occurred"
                $startButton.BackColor = [System.Drawing.Color]::FromArgb(150, 0, 0)
            }
        })
    $featuresForm.Controls.Add($startButton)

    # Close button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close"
    $closeButton.Location = New-Object System.Drawing.Point(240, 300)
    $closeButton.Size = New-Object System.Drawing.Size(220, 40)
    $closeButton.BackColor = [System.Drawing.Color]::FromArgb(150, 0, 0)
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $closeButton.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
    $closeButton.FlatAppearance.BorderSize = 1
    $closeButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255, 0, 0)
    $closeButton.Add_Click({
            $featuresForm.Close()
        })
    $featuresForm.Controls.Add($closeButton)

    $featuresForm.AcceptButton = $startButton
    $featuresForm.CancelButton = $closeButton

    # When form closes, show main menu
    $featuresForm.Add_FormClosed({
            Show-MainMenu -mainForm $mainForm
        })

    # Show the dialog
    $featuresForm.ShowDialog()
}

function Invoke-EnableWindowsFeatures {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    
    $featuresToEnable = @(
        @{
            Name        = "NetFx3"
            DisplayName = ".NET 3.5    "
            Command     = "dism /online /enable-feature /featurename:NetFx3 /all /norestart"
        },
        @{
            Name        = "WCF-HTTP-Activation"
            DisplayName = "WCF HTTP    "
            Command     = "DISM /Online /Enable-Feature /FeatureName:WCF-HTTP-Activation /All /Quiet /NoRestart"
        },
        @{
            Name        = "WCF-NonHTTP-Activation"
            DisplayName = "WCF Non-HTTP"
            Command     = "DISM /Online /Enable-Feature /FeatureName:WCF-NonHTTP-Activation /All /Quiet /NoRestart"
        }
    )

    Set-WindowsFeatureState -Features $featuresToEnable -TargetState "Enabled" -statusTextBox $statusTextBox
}

function Invoke-DisableWindowsFeatures {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)

    $featuresToDisable = @(
        @{
            Name        = "Internet-Explorer-Optional-amd64"
            DisplayName = "IExplorer 11"
            Command     = "dism /online /disable-feature /featurename:Internet-Explorer-Optional-amd64 /norestart"
            SupportedOS = "Windows 10"
        }
    )

    Set-WindowsFeatureState -Features $featuresToDisable -TargetState "Disabled" -statusTextBox $statusTextBox
}

function Set-WindowsFeatureState {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Features,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Enabled", "Disabled")]
        [string]$TargetState,
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )

    $actionVerb = if ($TargetState -eq "Enabled") { "Enabling" } else { "Disabling" }
    $actionVerbPast = if ($TargetState -eq "Enabled") { "Enabled" } else { "Disabled" }
    $oppositeState = if ($TargetState -eq "Enabled") { "Disabled" } else { "Enabled" }

    foreach ($feature in $Features) {
        # Check if feature should be applied on current OS if specified
        if ($feature.SupportedOS) {
            $osVersion = (Get-CimInstance Win32_OperatingSystem).Caption
            if (-not ($osVersion -like "*$($feature.SupportedOS)*")) {
                Add-Status "$($feature.DisplayName): Not applicable on $osVersion. Skipping..." $statusTextBox ([System.Drawing.Color]::Gray)
                continue
            }
        }

        try {
            $currentFeature = Get-WindowsOptionalFeature -Online -FeatureName $feature.Name -ErrorAction SilentlyContinue
            if (-not $currentFeature) {
                Add-Status "WARNING: Could not find feature '$($feature.Name)'. Skipping..." $statusTextBox ([System.Drawing.Color]::Yellow)
                continue
            }

            if ($currentFeature.State -eq $TargetState) {
                Add-Status "$($feature.DisplayName): Already $actionVerbPast. Skipping..." $statusTextBox ([System.Drawing.Color]::Gray)
            }
            elseif ($currentFeature.State -eq $oppositeState) {
                Add-Status "$($feature.DisplayName): Currently $oppositeState. $($actionVerb)..." $statusTextBox ([System.Drawing.Color]::Gray)

                $dismArgs = $feature.Command.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Skip 1
                $dismResult = Start-Process -FilePath "dism" -ArgumentList $dismArgs -Wait -PassThru -WindowStyle Hidden

                if ($dismResult.ExitCode -in 0, 3010) {
                    $statusMsg = "$($feature.DisplayName): $actionVerbPast completed."
                    if ($dismResult.ExitCode -eq 3010) { $statusMsg += " (Restart required)" }
                    Add-Status $statusMsg $statusTextBox ([System.Drawing.Color]::Gray)
                }
                else {
                    Add-Status "WARNING: Failed to change state for $($feature.DisplayName) (Exit code: $($dismResult.ExitCode))" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            else {
                Add-Status "WARNING: $($feature.DisplayName) is in an unexpected state: $($currentFeature.State)" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        catch {
            Add-Status "ERROR: Failed to process $($feature.DisplayName): $_" $statusTextBox ([System.Drawing.Color]::Red)
        }
    }
}

Export-ModuleMember -Function Invoke-EnableWindowsFeatures, Invoke-DisableWindowsFeatures, Set-WindowsFeatureState, Invoke-FeaturesDialog
