# ADMIN PRIVILEGES CHECK & INITIALIZATION
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrative privileges. Attempting to restart with elevation..."

    # Restart script with admin privileges
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

    try {
        Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    }
    catch [System.ComponentModel.Win32Exception] {
        # Check if the error was "The operation was canceled by the user" (Error code 1223)
        if ($_.Exception.NativeErrorCode -eq 1223) {
            exit 1223 # Specific exit code for UAC cancellation
        }
        # Re-throw other Win32 exceptions, which will cause exit code 1
        throw
    }
    catch {
        # Re-throw other exceptions, which will cause exit code 1
        throw
    }
    # Exit the current non-elevated instance
    exit 0 # Exit successfully since the new process was launched
}

# CONFIGURATION LOADING
try {
    $configPath = Join-Path $PSScriptRoot "config.json"
    if (-not (Test-Path $configPath)) {
        throw "FATAL: config.json not found at $configPath. Please create it."
    }
    $Global:config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
}
catch {
    # If GUI is not loaded yet, just write to host and exit.
    Write-Error "Configuration Error: $($_.Exception.Message)"
    # Attempt to show a message box if possible
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Configuration Error", "OK", "Error")
    }
    catch {}
    exit 1
}

# Define global path for downloads, used by other modules
$Global:destCopy = "$env:USERPROFILE\Downloads"

# Import Modules
Import-Module $PSScriptRoot\Modules\GUI.psm1 -Global
Import-Module $PSScriptRoot\Modules\WindowsFeatures.psm1 -Global
Import-Module $PSScriptRoot\Modules\Software.psm1 -Global
Import-Module $PSScriptRoot\Modules\System.psm1 -Global
Import-Module $PSScriptRoot\Modules\Disk.psm1 -Global
Import-Module $PSScriptRoot\Modules\CrowdStrike.psm1 -Global

# Load Windows Forms Funtions
try { Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop; Add-Type -AssemblyName System.Drawing -ErrorAction Stop }
catch { Write-Host "Error loading Windows Forms and Drawing assemblies." -ForegroundColor Red; exit 1 }

# Create main form
$script:form = New-Object System.Windows.Forms.Form
$script:form.Text = "BAOPROVIP - SYSTEM MANAGEMENT"
$script:form.Size = New-Object System.Drawing.Size(500, 400)
$script:form.MinimumSize = New-Object System.Drawing.Size(500, 400)  # Minimum 
$script:form.StartPosition = "CenterScreen"
$script:form.BackColor = [System.Drawing.Color]::Black
$script:form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$script:form.MaximizeBox = $true
# Apply gradient background using global function
Add-GradientBackground $script:form

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "WELCOME TO BAOPROVIP"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::Lime
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$titleLabel.Size = New-Object System.Drawing.Size($script:form.ClientSize.Width, 60)
$titleLabel.Location = New-Object System.Drawing.Point(0, 20)
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$titleLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$script:form.Controls.Add($titleLabel)

# Add animation using global function
Add-TitleAnimation -titleLabel $titleLabel

# Buttons List
$menuButtons = @(
    @{text = '[1] Run All'; action = { Invoke-RunAllOperations -mainForm $script:form } },
    @{text = '[6] Features'; action = { Invoke-FeaturesDialog -mainForm $script:form } },
    @{text = '[2] Software'; action = { Show-InstallSoftwareDialog -mainForm $script:form } },
    @{text = '[7] Rename'; action = { Invoke-RenameDialog } },
    @{text = '[3] Power'; action = { Invoke-PowerOptionsDialog } },
    @{text = '[8] Password'; action = { Show-SetPasswordForm -currentUser $env:USERNAME } },
    @{text = '[4] Volume'; action = { Invoke-VolumeManagementDialog } },
    @{text = '[9] Domain'; action = { Show-DomainManagementForm } },
    @{text = '[5] Activate'; action = { Invoke-ActivationDialog } },
    @{text = '[10] CrowdStrike'; action = { Invoke-CrowdStrikeDialog } }
)

try { $buttonHeight = 60; $buttonSpacingY = 10; $buttonTop = 80; $buttonLeft = 30; $buttonControls = @() }
catch { Write-Host "Error: $_" -ForegroundColor Red; Stop-Transcript -ErrorAction SilentlyContinue; exit 1 }

for ($i = 0; $i -lt $menuButtons.Count; $i += 2) {
    # Left buttons
    if ($menuButtons[$i].text -eq '[0] CrowStrike') { $btnL = New-DynamicButton -text $menuButtons[$i].text -x $buttonLeft -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i].action -normalColor ([System.Drawing.Color]::FromArgb(255, 140, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(255, 165, 0)) -pressColor ([System.Drawing.Color]::FromArgb(200, 100, 0)) }
    else { $btnL = New-DynamicButton -text $menuButtons[$i].text -x $buttonLeft -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i].action }
    $btnL.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $script:form.Controls.Add($btnL)
    $buttonControls += $btnL
    # Right buttons
    if ($i + 1 -lt $menuButtons.Count) {
        if ($menuButtons[$i + 1].text -eq '[0] CrowStrike') { $btnR = New-DynamicButton -text $menuButtons[$i + 1].text -x 0 -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i + 1].action -normalColor ([System.Drawing.Color]::FromArgb(255, 140, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(255, 165, 0)) -pressColor ([System.Drawing.Color]::FromArgb(200, 100, 0)) }
        else { $btnR = New-DynamicButton -text $menuButtons[$i + 1].text -x 0 -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i + 1].action }
        $btnR.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
        $script:form.Controls.Add($btnR)
        $buttonControls += $btnR
    }
}

# Update menu layout function
function Update-MenuLayout {
    $formWidth = $script:form.ClientSize.Width
    $formHeight = $script:form.ClientSize.Height
    $numRows = [math]::Ceiling($buttonControls.Count / 2)
    $minBtnWidth = 120
    $minBtnHeight = 40
    $colWidth = [math]::Max($minBtnWidth, [math]::Floor(($formWidth - 3 * $buttonLeft) / 2))
    $rowHeight = [math]::Max($minBtnHeight, [math]::Floor(($formHeight - $buttonTop - 30 - ($numRows - 1) * $buttonSpacingY) / $numRows))
    for ($i = 0; $i -lt $buttonControls.Count; $i += 2) {
        $rowIdx = [math]::Floor($i / 2)
        $y = $buttonTop + $rowIdx * ($rowHeight + $buttonSpacingY)
        $buttonControls[$i].Width = $colWidth
        $buttonControls[$i].Height = $rowHeight
        $buttonControls[$i].Left = $buttonLeft
        $buttonControls[$i].Top = $y
        if ($i + 1 -lt $buttonControls.Count) {
            $buttonControls[$i + 1].Width = $colWidth
            $buttonControls[$i + 1].Height = $rowHeight
            $buttonControls[$i + 1].Left = 2 * $buttonLeft + $colWidth
            $buttonControls[$i + 1].Top = $y
        }
    }
}

# Add resize event handler to update menu layout
$script:form.Add_Resize({ Update-MenuLayout }); Update-MenuLayout

# Add escape handler to close the form
$script:form.KeyPreview = $true; $script:form.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $script:form.Close() } })

# Show the form
$script:form.ShowDialog()