# ADMIN PRIVILEGES CHECK & INITIALIZATION
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrative privileges. Attempting to restart with elevation..."

    # Restart script with admin privileges
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs

    # Exit the current non-elevated instance
    exit
}

# HIDE CONSOLE
try {
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    ' -ErrorAction SilentlyContinue

    $consolePtr = [Console.Window]::GetConsoleWindow()
    if ($consolePtr -ne [System.IntPtr]::Zero) {
        [Console.Window]::ShowWindow($consolePtr, 0)
    }
}
catch {Write-Warning "Failed to hide console window." -ForegroundColor Red}

# HIDE MAIN MENU
function Hide-MainMenu {$script:form.Hide()}

# SHOW MAIN MENU
function Show-MainMenu {$script:form.Show()}

# Dynamic Button
function New-DynamicButton {
    param ([string]$text,[int]$x,[int]$y,[int]$width,[int]$height,[scriptblock]$clickAction,[System.Drawing.Color]$normalColor = [System.Drawing.Color]::FromArgb(0, 128, 0),[System.Drawing.Color]$hoverColor = [System.Drawing.Color]::FromArgb(0, 180, 0),[System.Drawing.Color]$pressColor = [System.Drawing.Color]::FromArgb(0, 100, 0),[System.Drawing.Color]$textColor = [System.Drawing.Color]::White,[string]$fontName = "Arial",[int]$fontSize = 12,[System.Drawing.FontStyle]$fontStyle = [System.Drawing.FontStyle]::Bold)

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $text
    $button.Location = New-Object System.Drawing.Point($x, $y)
    $button.Size = New-Object System.Drawing.Size($width, $height)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.BackColor = $normalColor
    $button.ForeColor = $textColor
    $button.Font = New-Object System.Drawing.Font($fontName, $fontSize, $fontStyle)
    $button.FlatAppearance.BorderSize = 0
    $button.FlatAppearance.MouseOverBackColor = $hoverColor
    $button.FlatAppearance.MouseDownBackColor = $pressColor
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.Add_Click($clickAction)

    return $button
}

# Load Windows Forms Funtions
try {Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop;Add-Type -AssemblyName System.Drawing -ErrorAction Stop}
catch {Write-Host "Error loading Windows Forms and Drawing assemblies." -ForegroundColor Red;exit 1}

# Global function to add gradient background to any form
function Add-GradientBackground {
    param([System.Windows.Forms.Form]$form,[System.Drawing.Color]$topColor = [System.Drawing.Color]::FromArgb(0, 0, 0),[System.Drawing.Color]$bottomColor = [System.Drawing.Color]::FromArgb(0, 50, 0))

    # Extract ARGB values for reliable color recreation
    $topA = $topColor.A
    $topR = $topColor.R
    $topG = $topColor.G
    $topB = $topColor.B

    $bottomA = $bottomColor.A
    $bottomR = $bottomColor.R
    $bottomG = $bottomColor.G
    $bottomB = $bottomColor.B

    # Create scriptblock with embedded color values
    $paintScript = [ScriptBlock]::Create(@"
        param(`$formSender, `$paintArgs)
        `$graphics = `$paintArgs.Graphics
        `$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        # Use ClientRectangle for better rendering
        `$rect = `$formSender.ClientRectangle

        # Create gradient brush with embedded color values
        `$topColor = [System.Drawing.Color]::FromArgb($topA, $topR, $topG, $topB)
        `$bottomColor = [System.Drawing.Color]::FromArgb($bottomA, $bottomR, $bottomG, $bottomB)

        `$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            `$rect,
            `$topColor,
            `$bottomColor,
            [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
        )

        `$graphics.FillRectangle(`$brush, `$rect)
        `$brush.Dispose()
"@)

    # Add the paint event
    $form.Add_Paint($paintScript)

    if ($form.PSObject.Properties['DoubleBuffered']) {$form.DoubleBuffered = $true}
}

# Create main form
$script:form = New-Object System.Windows.Forms.Form
$script:form.Text = "BAOPROVIP - SYSTEM MANAGEMENT"
$script:form.Size = New-Object System.Drawing.Size(500, 400)
$script:form.MinimumSize = New-Object System.Drawing.Size(500, 400)  # Kích thước tối thiểu
$script:form.StartPosition = "CenterScreen"
$script:form.BackColor = [System.Drawing.Color]::Black
$script:form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$script:form.MaximizeBox = $true  # Cho phép maximize

# Apply gradient background using global function
Add-GradientBackground -form $script:form

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

# Global function to add title animation
function Add-TitleAnimation {param([System.Windows.Forms.Label]$titleLabel,[int]$interval = 500,[System.Drawing.Color]$color1,[System.Drawing.Color]$color2)
    # Validate input
    if (-not $titleLabel) {Write-Warning "TitleLabel is null, cannot add animation";return $null}

    # Set default colors if not provided
    if (-not $color1 -or $color1 -eq [System.Drawing.Color]::Empty) {$color1 = [System.Drawing.Color]::FromArgb(0, 255, 0)}
    if (-not $color2 -or $color2 -eq [System.Drawing.Color]::Empty) {$color2 = [System.Drawing.Color]::FromArgb(0, 200, 0)}

    # Create timer for animation
    $titleTimer = New-Object System.Windows.Forms.Timer
    $titleTimer.Interval = $interval

    # Store references in timer's Tag property for proper cleanup
    $titleTimer.Tag = @{Label = $titleLabel;Color1 = $color1;Color2 = $color2}

    $titleTimer.Add_Tick({
        try {
            $data = $this.Tag
            $label = $data.Label

            # Check if label still exists and is not disposed
            if ($label -and -not $label.IsDisposed) {
                # Toggle between colors using ARGB comparison for reliability
                if ($label.ForeColor.ToArgb() -eq $data.Color1.ToArgb()) {
                    $label.ForeColor = $data.Color2
                } else {
                    $label.ForeColor = $data.Color1
                }

                # Force UI update
                $label.Refresh()
                [System.Windows.Forms.Application]::DoEvents()
            } else {
                # Stop timer if label is disposed
                $this.Stop()
            }
        }
        catch {
            # Stop timer on any error to prevent crashes
            $this.Stop()
            Write-Host "Animation stopped due to error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    })

    $titleTimer.Start()
    return $titleTimer
}

# Add animation using global function
Add-TitleAnimation -titleLabel $titleLabel

# Add status with optional color parameter
function Add-Status {param([string]$message,[System.Windows.Forms.RichTextBox]$rtb,[System.Drawing.Color]$color = [System.Drawing.Color]::Lime)
    if ($rtb.Text -eq "Please select a device type..." -or $rtb.Text -eq "Status messages will appear here...") {$rtb.Clear()}
    $timestamp = Get-Date -Format "HH:mm:ss"
    $rtb.SelectionStart = $rtb.TextLength
    $rtb.SelectionLength = 0
    $rtb.SelectionColor = $rtb.ForeColor
    $rtb.AppendText("[$timestamp] ")
    $rtb.SelectionColor = $color
    $rtb.AppendText("$message`r`n")
    $rtb.SelectionColor = $rtb.ForeColor
    $rtb.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# [1] Run All Functions
function Select-DeviceType {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Select Device Type"
    $form.Size = New-Object System.Drawing.Size(300, 210)
    $form.StartPosition = "CenterParent"
    $form.BackColor = [System.Drawing.Color]::Black
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # Safe gradient instead of inline Paint
    Add-GradientBackground -form $form

    # Title
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "SELECT DEVICE TYPE"
    $lbl.Location = New-Object System.Drawing.Point(0, 20)
    $lbl.Size = New-Object System.Drawing.Size(290, 30)
    $lbl.ForeColor = [System.Drawing.Color]::Lime
    $lbl.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $lbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $form.Controls.Add($lbl)

    # Buttons
    $selection = $null
    $btnDesktop = New-DynamicButton -text "DESKTOP" -x 10 -y 70 -width 260 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0,150,0)) -hoverColor ([System.Drawing.Color]::FromArgb(0,200,0)) -pressColor ([System.Drawing.Color]::FromArgb(0,100,0)) -clickAction {$script:selection = "Desktop";$form.DialogResult = [System.Windows.Forms.DialogResult]::OK;$form.Close()}
    $form.Controls.Add($btnDesktop)

    $btnLaptop = New-DynamicButton -text "LAPTOP" -x 10 -y 120 -width 260 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0,150,0)) -hoverColor ([System.Drawing.Color]::FromArgb(0,200,0)) -pressColor ([System.Drawing.Color]::FromArgb(0,100,0)) -clickAction {$script:selection = "Laptop";$form.DialogResult = [System.Windows.Forms.DialogResult]::OK;$form.Close()}
    $form.Controls.Add($btnLaptop)

    # Esc support
    $form.KeyPreview = $true
    $form.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $form.Close() } })

    # Show dialog
    $result = $form.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {Add-Status "Selected device type: $script:selection" $statusTextBox}
    else {Add-Status "Device type selection cancelled. Exiting..." $statusTextBox ([System.Drawing.Color]::Red)}
    $form.Close()
    return $script:selection
}

function Invoke-RunAllOperations {param([System.Windows.Forms.Form]$mainForm)
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
        # STEP 0: WiFi Connection and Windows Update Check
        Add-Status "STEP 0: Connecting to WiFi network..." $statusTextBox
        $progressBar.Value = 5

        $wifiResult = Invoke-WiFiAutoConnection $statusTextBox
        if ($wifiResult) {
            Add-Status "WiFi connection completed!" $statusTextBox

            # STEP 0.5: Start Windows Updates in background
            Add-Status "STEP 0.5: Starting Windows Updates (Background)..." $statusTextBox
            $progressBar.Value = 8

            $updateResult = Invoke-WindowsUpdateCheck $statusTextBox
            if ($updateResult) {
                Add-Status "Windows Update process started successfully!" $statusTextBox ([System.Drawing.Color]::Green)
                Add-Status "Updates will continue in background..." $statusTextBox ([System.Drawing.Color]::Cyan)
            }
            else {
                Add-Status "Windows Update start failed, but continuing..." $statusTextBox ([System.Drawing.Color]::Yellow)
            }

            Add-Status "STEP 0 completed - continuing with other operations..." $statusTextBox ([System.Drawing.Color]::Cyan)
        }
        else {
            Add-Status "WiFi connection failed, but continuing..." $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        # STEP 1: Device Selection and Software Installation
        Add-Status "STEP 1: Selecting Device Type and Installing Software..." $statusTextBox
        $progressBar.Value = 14

        # Select device type (function-based)
        $deviceType = Select-DeviceType -Owner $statusForm
        if (-not $deviceType) {
            Add-Status "Device type selection cancelled. Exiting..." $statusTextBox ([System.Drawing.Color]::Red)
            $statusForm.Close()
            Show-MainMenu
            return
        }
        Add-Status "Selected device type: $deviceType" $statusTextBox

        # STEP 1: Software provisioning
        Add-Status "STEP 1: Software provisioning (Detect → Copy → Install)..." $statusTextBox

        $provisionOk = Invoke-InstallSoftware -DeviceType $deviceType -statusTextBox $statusTextBox
        if (-not $provisionOk) {
            Add-Status "STEP 1 finished with warnings/errors." $statusTextBox ([System.Drawing.Color]::Yellow)
        }

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
        # Close the status form after a delay
        # Start-Sleep -Seconds 2
        # $statusForm.Close()
    }
}

# STEP 0: WiFi AUTO-CONNECTION FUNCTION
function Invoke-WiFiAutoConnection {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # Check WLAN service
        Add-Status "Checking WiFi capability..." $statusTextBox
        try {
            $wlanService = Get-Service -Name "WlanSvc" -ErrorAction SilentlyContinue
            if (-not $wlanService) {
                Add-Status "No WiFi capability detected - skipping WiFi setup" $statusTextBox ([System.Drawing.Color]::Yellow)
                return $true
            }

            if ($wlanService.Status -ne "Running") {
                Add-Status "Starting WiFi service..." $statusTextBox
                Start-Service -Name "WlanSvc" -ErrorAction Stop
                Start-Sleep -Seconds 3
            }
        }
        catch {
            Add-Status "WiFi service error: $_" $statusTextBox ([System.Drawing.Color]::Red)
            return $false
        }

        # Quick WiFi adapter check
        Add-Status "Detecting WiFi adapters..." $statusTextBox
        try {
            $wifiAdapters = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*wireless*" -or $_.InterfaceDescription -like "*wifi*" -or $_.InterfaceDescription -like "*802.11*" }

            if (-not $wifiAdapters) {
                Add-Status "No WiFi adapters found - skipping WiFi setup" $statusTextBox ([System.Drawing.Color]::Yellow)
                return $true
            }

            Add-Status "Found $($wifiAdapters.Count) WiFi adapter(s)" $statusTextBox ([System.Drawing.Color]::Green)
        }
        catch {
            Add-Status "WiFi adapter detection failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
            return $false
        }

        # Check current WiFi connection
        $targetSSID = "VietUnion_5.0GHz"
        Add-Status "Checking current WiFi connection..." $statusTextBox

        try {
            $currentConnection = netsh wlan show interfaces

            # Parse current connection info
            $isConnected = $false
            $currentSSID = ""

            foreach ($line in $currentConnection) {
                if ($line -match "^\s*State\s*:\s*connected\s*$") {
                    $isConnected = $true
                }
                if ($line -match "^\s*SSID\s*:\s*(.+)$") {
                    $currentSSID = $matches[1].Trim()
                }
            }

            # Check if already connected to target network
            if ($isConnected -and $currentSSID -eq $targetSSID) {
                Add-Status "Already connected to $targetSSID - skipping WiFi setup" $statusTextBox ([System.Drawing.Color]::Green)
                return $true
            }
            elseif ($isConnected -and $currentSSID -ne "" -and $currentSSID -ne $targetSSID) {
                Add-Status "Currently connected to: $currentSSID" $statusTextBox ([System.Drawing.Color]::Yellow)
                Add-Status "Need to connect to: $targetSSID" $statusTextBox
            }
            else {
                Add-Status "No active WiFi connection detected" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        catch {
            Add-Status "Could not check current WiFi status - proceeding with setup" $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        # Create WiFi profile
        $SSID = "VietUnion_5.0GHz"
        $Password = "Pay00@17Years$"
        $profileFile = "$env:TEMP\VietUnion_5.0GHz_profile.xml"

        Add-Status "Creating WiFi profile for $SSID..." $statusTextBox

        try {
            $SSIDHEX = ($SSID.ToCharArray() | ForEach-Object { '{0:X2}' -f ([int]$_) }) -join ''

            $profileXML = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$SSID</name>
    <SSIDConfig>
        <SSID>
            <hex>$SSIDHEX</hex>
            <name>$SSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$Password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@

            [System.IO.File]::WriteAllText($profileFile, $profileXML, [System.Text.Encoding]::UTF8)
            Add-Status "WiFi profile created successfully" $statusTextBox ([System.Drawing.Color]::Green)
        }
        catch {
            Add-Status "Failed to create WiFi profile: $_" $statusTextBox ([System.Drawing.Color]::Red)
            return $false
        }

        # Add WiFi profile
        Add-Status "Adding WiFi profile to system..." $statusTextBox
        try {
            # Remove existing profile first (correct command)
            $null = netsh wlan delete profile name="$SSID" 2>$null

            # Add new profile
            $addResult = netsh wlan add profile filename="$profileFile"
            if ($LASTEXITCODE -eq 0) {
                Add-Status "WiFi profile added successfully" $statusTextBox ([System.Drawing.Color]::Green)
            }
            else {
                Add-Status "Failed to add WiFi profile" $statusTextBox ([System.Drawing.Color]::Red)
                return $false
            }
        }
        catch {
            Add-Status "WiFi profile addition failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
            return $false
        }

        # Connect to WiFi
        Add-Status "Connecting to WiFi network..." $statusTextBox
        try {
            $connectResult = netsh wlan connect name="$SSID"

            if ($LASTEXITCODE -eq 0) {
                Add-Status "WiFi connection initiated" $statusTextBox ([System.Drawing.Color]::Green)

                # Wait and verify connection
                Start-Sleep -Seconds 5

                $verifyResult = netsh wlan show interfaces
                if ($verifyResult -like "*$SSID*" -and $verifyResult -like "*connected*") {
                    Add-Status "WiFi connected successfully to $SSID!" $statusTextBox ([System.Drawing.Color]::Green)
                    return $true
                }
                else {
                    Add-Status "WiFi connection verification failed" $statusTextBox ([System.Drawing.Color]::Yellow)
                    return $false
                }
            }
            else {
                Add-Status "WiFi connection failed" $statusTextBox ([System.Drawing.Color]::Red)
                return $false
            }
        }
        catch {
            Add-Status "WiFi connection error: $_" $statusTextBox ([System.Drawing.Color]::Red)
            return $false
        }
        finally {
            # Clean up profile file
            if (Test-Path $profileFile) {
                Remove-Item $profileFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Add-Status "WiFi setup failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

function Invoke-WindowsUpdateCheck {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    Add-Status "Starting Windows Update process..." $statusTextBox

    try {
        # Quick service check
        $wuService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        if ($wuService -and $wuService.Status -ne "Running") {
            Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        }

        # Test internet connectivity
        $testConnection = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if (-not $testConnection) {
            Add-Status "No internet connection - skipping Windows Update" $statusTextBox ([System.Drawing.Color]::Yellow)
            return $false
        }

        # Trigger updates in background
        Add-Status "Triggering Windows Update check..." $statusTextBox
        try {
            # Use USOClient for immediate trigger
            Start-Process -FilePath "USOClient.exe" -ArgumentList "ScanInstallWait" -WindowStyle Hidden -ErrorAction Stop
            Start-Process -FilePath "USOClient.exe" -ArgumentList "StartDownload" -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "USOClient.exe" -ArgumentList "StartInstall" -WindowStyle Hidden -ErrorAction SilentlyContinue

            Add-Status "Windows Update triggered successfully" $statusTextBox ([System.Drawing.Color]::Green)
            return $true
        }
        catch {
            # Fallback to wuauclt
            try {
                Start-Process -FilePath "wuauclt.exe" -ArgumentList "/detectnow" -WindowStyle Hidden -ErrorAction Stop
                Start-Process -FilePath "wuauclt.exe" -ArgumentList "/updatenow" -WindowStyle Hidden -ErrorAction SilentlyContinue

                Add-Status "Windows Update triggered via wuauclt" $statusTextBox ([System.Drawing.Color]::Green)
                return $true
            }
            catch {
                Add-Status "Windows Update trigger failed" $statusTextBox ([System.Drawing.Color]::Yellow)
                return $false
            }
        }
    }
    catch {
        Add-Status "Windows Update setup failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

function Start-WindowsUpdateBackground {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    Add-Status "Starting Windows Updates in background..." $statusTextBox ([System.Drawing.Color]::Cyan)

    try {
        # Create a background runspace for updates
        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()

        # Create PowerShell instance
        $powershell = [powershell]::Create()
        $powershell.Runspace = $runspace

        # Add script block for background update
        $scriptBlock = {
            try {
                # Enable TLS 1.2
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                # Try multiple update methods
                # Method 1: USOClient
                try {
                    $null = Start-Process -FilePath "USOClient.exe" -ArgumentList "ScanInstallWait" -Wait -WindowStyle Hidden -ErrorAction Stop
                    $null = Start-Process -FilePath "USOClient.exe" -ArgumentList "StartDownload" -WindowStyle Hidden -ErrorAction SilentlyContinue
                    $null = Start-Process -FilePath "USOClient.exe" -ArgumentList "StartInstall" -WindowStyle Hidden -ErrorAction SilentlyContinue
                    return "USOClient method completed"
                }
                catch {
                    # Continue to next method
                }

                # Method 2: PSWindowsUpdate
                try {
                    Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -ErrorAction Stop
                    Import-Module PSWindowsUpdate -ErrorAction Stop
                    $updates = Get-WUList -ErrorAction Stop
                    if ($updates) {
                        Install-WindowsUpdate -AcceptAll -AutoReboot -ErrorAction Stop
                        return "PSWindowsUpdate method completed with $($updates.Count) updates"
                    }
                    else {
                        return "No updates available"
                    }
                }
                catch {
                    # Continue to next method
                }

                # Method 3: wuauclt
                try {
                    $null = Start-Process -FilePath "wuauclt.exe" -ArgumentList "/detectnow" -Wait -WindowStyle Hidden -ErrorAction Stop
                    $null = Start-Process -FilePath "wuauclt.exe" -ArgumentList "/updatenow" -WindowStyle Hidden -ErrorAction SilentlyContinue
                    return "wuauclt method completed"
                }
                catch {
                    return "All update methods failed"
                }
            }
            catch {
                return "Background update error: $($_.Exception.Message)"
            }
        }

        $powershell.AddScript($scriptBlock)

        # Start async execution
        $powershell.BeginInvoke()

        Add-Status "Background Windows Update process started" $statusTextBox ([System.Drawing.Color]::Green)
        Add-Status "Updates will continue in background while other operations proceed" $statusTextBox ([System.Drawing.Color]::Green)

        return $true
    }
    catch {
        Add-Status "Failed to start background update process: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

# STEP 2: Choose Device Type and Rename
function Invoke-RenamebyDevice {param ([string]$deviceType,[System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # Get current computer name
        $currentName = $env:COMPUTERNAME
        Add-Status "Current computer name: $currentName" $statusTextBox

        # Create rename form
        $renameForm = New-Object System.Windows.Forms.Form
        $renameForm.Text = "Computer Name Configuration"
        $renameForm.Size = New-Object System.Drawing.Size(450, 250)
        $renameForm.StartPosition = "CenterScreen"
        $renameForm.BackColor = [System.Drawing.Color]::Black
        $renameForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $renameForm.MaximizeBox = $false
        $renameForm.MinimizeBox = $false

        # Key Preview
        $renameForm.KeyPreview = $true
        $renameForm.Add_KeyDown({param($sender, $e)if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {$renameForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel;$renameForm.Close()}
                elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {$okButton.PerformClick()}})

        # Current Name Label
        $currentNameLabel = New-Object System.Windows.Forms.Label
        $currentNameLabel.Text = "Current Computer Name: $currentName"
        $currentNameLabel.Location = New-Object System.Drawing.Point(20, 20)
        $currentNameLabel.Size = New-Object System.Drawing.Size(400, 25)
        $currentNameLabel.ForeColor = [System.Drawing.Color]::White
        $currentNameLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
        $currentNameLabel.BackColor = [System.Drawing.Color]::Transparent
        $renameForm.Controls.Add($currentNameLabel)

        # Prefix
        $prefix = ""
        if ($deviceType -eq "Desktop") {$prefix = "HOD"}
        elseif ($deviceType -eq "Laptop") {$prefix = "HOL"}

        # Instruction Label
        $instructionLabel = New-Object System.Windows.Forms.Label
        $instructionLabel.Text = "Enter new name (will be prefixed with $prefix):"
        $instructionLabel.Location = New-Object System.Drawing.Point(20, 60)
        $instructionLabel.Size = New-Object System.Drawing.Size(400, 25)
        $instructionLabel.ForeColor = [System.Drawing.Color]::Lime
        $instructionLabel.Font = New-Object System.Drawing.Font("Arial", 10)
        $instructionLabel.BackColor = [System.Drawing.Color]::Transparent
        $renameForm.Controls.Add($instructionLabel)

        # Name Textbox
        $nameTextBox = New-Object System.Windows.Forms.RichTextBox
        $nameTextBox.Location = New-Object System.Drawing.Point(20, 90)
        $nameTextBox.Size = New-Object System.Drawing.Size(300, 25)
        $nameTextBox.Font = New-Object System.Drawing.Font("Arial", 10)
        $renameForm.Controls.Add($nameTextBox)

        # Key Preview
        $nameTextBox.Add_KeyDown({param($sender, $e)if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {$okButton.PerformClick()}})

        # Preview Label
        $previewLabel = New-Object System.Windows.Forms.Label
        $previewLabel.Text = "New name will be: $prefix"
        $previewLabel.Location = New-Object System.Drawing.Point(20, 125)
        $previewLabel.Size = New-Object System.Drawing.Size(400, 25)
        $previewLabel.ForeColor = [System.Drawing.Color]::Yellow
        $previewLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Italic)
        $previewLabel.BackColor = [System.Drawing.Color]::Transparent
        $renameForm.Controls.Add($previewLabel)

        # Text Changed
        $nameTextBox.Add_TextChanged({$newPreview = $prefix + $nameTextBox.Text.Trim();$previewLabel.Text = "New name will be: $newPreview"})

        # OK Button
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK (Enter)"
        $okButton.Location = New-Object System.Drawing.Point(220, 160)
        $okButton.Size = New-Object System.Drawing.Size(100, 30)
        $okButton.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 0)
        $okButton.ForeColor = [System.Drawing.Color]::White
        $okButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $okButton.Add_Click({$renameForm.DialogResult = [System.Windows.Forms.DialogResult]::OK;$renameForm.Close()})
        $renameForm.Controls.Add($okButton)

        # Cancel Button
        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Text = "Cancel (ESC)"
        $cancelButton.Location = New-Object System.Drawing.Point(330, 160)
        $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
        $cancelButton.BackColor = [System.Drawing.Color]::FromArgb(150, 0, 0)
        $cancelButton.ForeColor = [System.Drawing.Color]::White
        $cancelButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $cancelButton.Add_Click({$renameForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel;$renameForm.Close()})
        $renameForm.Controls.Add($cancelButton)

        # Set focus to TextBox when form is shown
        $renameForm.Add_Shown({$nameTextBox.Focus();$nameTextBox.Select()})

        # Show form and handle result
        $result = $renameForm.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $inputName = $nameTextBox.Text.Trim()

            if ($inputName -and $inputName -ne "") {
                $newName = $prefix + $inputName

                if ($newName -ne $currentName) {
                    Add-Status "Renaming computer from '$currentName' to '$newName'..." $statusTextBox
                    try {
                        Rename-Computer -NewName $newName -Force -ErrorAction Stop
                        Add-Status "Computer will be renamed to '$newName' after restart." $statusTextBox
                    }
                    catch {
                        Add-Status "ERROR: Failed to rename computer: $_" $statusTextBox ([System.Drawing.Color]::Red)
                    }
                }
                else {
                    Add-Status "New name is same as current name. Skipping..." $statusTextBox
                }
            }
            else {
                Add-Status "No computer name entered. Skipping rename..." $statusTextBox
            }
        }
        else {
            Add-Status "Computer rename cancelled by user." $statusTextBox
        }
        return $true
    }
    catch {
        Add-Status "ERROR during System Configuration: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

# STEP 3: SYSTEM CLEANUP FUNCTIONS
function Invoke-SystemCleanup {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # --- 1. System File Cleanup ---
        Invoke-FileCleanup $statusTextBox

        # --- 2. Startup Program Management ---
        Invoke-StartupOptimization $statusTextBox

        # --- 3. Timezone Configuration ---
        Invoke-TimezoneConfiguration $statusTextBox

        # --- 4. Power Options Configuration ---
        Invoke-PowerOptionsConfiguration $statusTextBox
        return $true
    }
    catch {
        Add-Status "ERROR during System Cleanup: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

function Invoke-FileCleanup {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    Add-Status "Cleaning temporary files..." $statusTextBox

    # Temporary files
    $tempPaths = @("$env:TEMP\*","$env:WINDIR\Temp\*","$env:USERPROFILE\AppData\Local\Temp\*")

    # Remove temporary files
    $tempPaths | ForEach-Object {
        try {Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue}
        catch {Add-Status "Warning: Could not clean $_" $statusTextBox ([System.Drawing.Color]::Yellow)}
    }

    # Clean Recycle Bin and Windows Update cache
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Add-Status "Recycle Bin cleaned." $statusTextBox

        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        Add-Status "Windows Update cache cleaned." $statusTextBox
    }
    catch {
        Add-Status "Warning: Could not complete advanced cleanup" $statusTextBox ([System.Drawing.Color]::Yellow)
    }
}

function Invoke-StartupOptimization {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    $startupPrograms = @("Microsoft Teams", "Microsoft Co-Pilot", "Microsoft Edge")
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

    $startupPrograms | ForEach-Object {
        try {
            $property = Get-ItemProperty -Path $regPath -Name $_ -ErrorAction SilentlyContinue
            if ($property) {
                Remove-ItemProperty -Path $regPath -Name $_ -ErrorAction SilentlyContinue
            }
        }
        catch {
            Add-Status "Warning: Could not disable startup program $_" $statusTextBox ([System.Drawing.Color]::Yellow)
        }
    }
}

function Invoke-TimezoneConfiguration {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        $tzResult = Start-Process -FilePath "tzutil" -ArgumentList "/s `"SE Asia Standard Time`"" -Wait -PassThru -WindowStyle Hidden
        if ($tzResult.ExitCode -eq 0) {
            Add-Status "Time zone set to SE Asia Standard Time successfully!" $statusTextBox
        }

        $regCommands = @(
            @{Path = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\w32time\Parameters"; Name = "Type"; Value = "NTP" },
            @{Path = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\tzautoupdate"; Name = "Start"; Value = 2 }
        )

        $regCommands | ForEach-Object {
            reg add $_.Path /v $_.Name /t REG_SZ /d $_.Value /f | Out-Null
        }
        w32tm /resync | Out-Null
    }
    catch {
        Add-Status "Warning: Could not configure timezone settings: $_" $statusTextBox ([System.Drawing.Color]::Yellow)
    }
}

function Invoke-PowerOptionsConfiguration {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        $powerConfigs = @(
            @{Setting = "LIDACTION"; Description = "Lid close action" },
            @{Setting = "SBUTTONACTION"; Description = "Sleep button action" },
            @{Setting = "PBUTTONACTION"; Description = "Power button action" }
        )

        $powerConfigs | ForEach-Object {
            powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS $_.Setting 0 | Out-Null
            powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS $_.Setting 0 | Out-Null
        }

        powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0 | Out-Null
        powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0 | Out-Null
        powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0 | Out-Null
        powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0 | Out-Null

        powercfg /SETACTIVE SCHEME_CURRENT | Out-Null
        Add-Status "Power options configured to 'Do Nothing' completed successfully!" $statusTextBox
    }
    catch {
        Add-Status "Warning: Could not configure power options: $_" $statusTextBox ([System.Drawing.Color]::Yellow)
    }
}

function Invoke-AdvancedTaskbarCustomization {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # Unpin Microsoft Store using PowerShell
        $unpinScript = @'
$shell = New-Object -ComObject Shell.Application
$folder = $shell.Namespace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}")
$items = $folder.Items()
foreach ($item in $items) {
    if ($item.Name -eq "Microsoft Store") {
        $verbs = $item.Verbs()
        foreach ($verb in $verbs) {
            if ($verb.Name -like "*Unpin*taskbar*" -or $verb.Name -like "*Unpin*tas&kbar*") {
                $verb.DoIt()
                break
            }
        }
        break
    }
}
'@
        try {
            Invoke-Expression $unpinScript
        }
        catch {
            Add-Status "PowerShell unpin method failed: $_"  $statusTextBox ([System.Drawing.Color]::Red)
        }
        # Create comprehensive registry script
        $regScript = @"
Windows Registry Editor Version 5.00

; Hide Task View Button
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
"ShowTaskViewButton"=dword:00000000

; Hide Widgets (Windows 11) / News and Interests (Windows 10)
"TaskbarDa"=dword:00000000
"TaskbarWidgets"=dword:00000000

; Hide Copilot Button (Windows 11)
"ShowCopilotButton"=dword:00000000

; Hide Chat Button (Windows 11)
"TaskbarMn"=dword:00000000

; Hide People Button (Windows 10)
"PeopleBand"=dword:00000000

; Disable News and Interests (Windows 10)
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Feeds]
"ShellFeedsTaskbarViewMode"=dword:00000002

; Hide Meet Now (Windows 10)
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer]
"HideSCAMeetNow"=dword:00000001

; Disable Copilot Policy (Windows 11)
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot]
"TurnOffWindowsCopilot"=dword:00000001
"@

        # Write and apply registry file
        $regFile = "$env:TEMP\taskbar_customization.reg"
        $regScript | Out-File -FilePath $regFile -Encoding ASCII

        try {
            Start-Process -FilePath "reg" -ArgumentList "import `"$regFile`"" -Wait -WindowStyle Hidden

            # Clean up
            Remove-Item -Path $regFile -Force -ErrorAction SilentlyContinue
        }
        catch {
            Add-Status "Could not apply registry changes: $_"  $statusTextBox ([System.Drawing.Color]::Red)
        }
    }
    catch {
        Add-Status "ERROR in advanced taskbar customization: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

# STEP 4: Windows and Office Activation
function Invoke-ActivateConfiguration {param ([string]$deviceType,[System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # --- 1. Windows 10 Pro Activation ---
        Invoke-ActivateWindows10Pro $statusTextBox
        # --- 2. Office 2019 Pro Plus Activation ---
        Invoke-ActivateOffice2019 $statusTextBox
        return $true
    }
    catch {
        Add-Status "ERROR during Activation Configuration: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

# STEP 7: User Password Management Functions
function Invoke-UserPasswordManagement {param ([string]$deviceType,[System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # --- 1. Get Current User Information ---
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
        Add-Status "Current user: $currentUser" $statusTextBox

        # --- 2. Show Password Management Dialog ---
        $passwordResult = Invoke-SetPasswordDialog -currentUser $currentUser -statusTextBox $statusTextBox -showMenuAfter $false

        if ($passwordResult) {
            Add-Status "User password management completed." $statusTextBox
        }
        else {
            Add-Status "User password management was cancelled or failed." $statusTextBox ([System.Drawing.Color]::Yellow)
        }
        return $true
    }
    catch {
        Add-Status "ERROR during User Password Management: $_"  $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

# [2] Install Software Functions
function Copy-SoftwareFiles {param ([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        $tempDir = "$env:USERPROFILE\Downloads\SETUP"

        if (-not (Test-Path $tempDir)) {
            Add-Status "Creating temporary folder..." $statusTextBox
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
            Add-Status "Temporary folder created successfully!" $statusTextBox
        }
        else {
            Add-Status "Temporary folder already exists. Skipping..." $statusTextBox
        }

        # Check D: drive exists
        if (-not (Test-Path "D:\")) {
            Add-Status "WARNING: D drive not found. Creating mock installation..." $statusTextBox ([System.Drawing.Color]::Yellow)

            if (-not (Test-Path "$tempDir\Software")) {
                New-Item -Path "$tempDir\Software" -ItemType Directory -Force | Out-Null
                Add-Status "Created mock Software directory" $statusTextBox
            }

            if (-not (Test-Path "$tempDir\Office2019")) {
                New-Item -Path "$tempDir\Office2019" -ItemType Directory -Force | Out-Null
                Add-Status "Created mock Office2019 directory" $statusTextBox
            }

            Add-Status "Copy-SoftwareFiles completed (mock mode)" $statusTextBox
            return $true
        }

        # Copy SETUP folder from D:\SOFTWARE\PAYOO\SETUP
        if (-not (Test-Path "$tempDir\Software")) {
            $setupSource = "D:\SOFTWARE\PAYOO\SETUP"
            if (Test-Path $setupSource) {
                Add-Status "Copying setup files from $setupSource..." $statusTextBox
                try {
                    Copy-Item -Path $setupSource -Destination "$tempDir\Software" -Recurse -Force -ErrorAction Stop
                    Add-Status "SetupFiles    has been copied successfully!" $statusTextBox
                }
                catch {
                    Add-Status "Error copying setup files: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "Warning: Setup source folder not found at $setupSource" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        else {
            Add-Status "SetupFiles    is already copied. Skipping..." $statusTextBox
        }

        # Copy Office 2019 folders
        if (-not (Test-Path "$tempDir\Office2019")) {
            $officeSource = "D:\SOFTWARE\OFFICE\Office 2019"
            if (Test-Path $officeSource) {
                Add-Status "Copying Office 2019 files from $officeSource..." $statusTextBox
                try {
                    New-Item -Path "$tempDir\Office2019" -ItemType Directory -Force | Out-Null
                    Copy-Item -Path "$officeSource\*" -Destination "$tempDir\Office2019" -Recurse -Force -ErrorAction Stop
                    Add-Status "Office 2019   has been copied successfully!" $statusTextBox
                }
                catch {
                    Add-Status "Error copying Office 2019: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "Warning: Office source folder not found at $officeSource" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        else {
            Add-Status "Office 2019   is already copied. Skipping..." $statusTextBox
        }

        # Copy Unikey to C:\ drive
        if (-not (Test-Path "C:\unikey46RC2-230919-win64")) {
            $unikeySource = "D:\SOFTWARE\PAYOO\unikey46RC2-230919-win64"
            if (Test-Path $unikeySource) {
                Add-Status "Copying Unikey files to C:\ drive..." $statusTextBox
                try {
                    Copy-Item -Path $unikeySource -Destination "C:\unikey46RC2-230919-win64" -Recurse -Force -ErrorAction Stop
                    Add-Status "Unikey        has been copied successfully!" $statusTextBox
                }
                catch {
                    Add-Status "Error copying Unikey: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "Warning: Unikey source folder not found at $unikeySource" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        else {
            Add-Status "Unikey        is already copied. Skipping..." $statusTextBox
        }

        # Copy MSTeamsSetup to C:\ drive
        if (-not (Test-Path "C:\MSTeamsSetup.exe")) {
            $teamsSource = "D:\SOFTWARE\PAYOO\MSTeamsSetup.exe"
            if (Test-Path $teamsSource) {
                Add-Status "Copying MSTeamsSetup file to C:\ drive..." $statusTextBox
                try {
                    Copy-Item -Path $teamsSource -Destination "C:\MSTeamsSetup.exe" -Force -ErrorAction Stop
                    Add-Status "MSTeamsSetup  has been copied successfully!" $statusTextBox
                }
                catch {
                    Add-Status "Error copying MSTeamsSetup: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "Warning: MSTeamsSetup source file not found at $teamsSource" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        else {
            Add-Status "MSTeamsSetup  is already copied. Skipping..." $statusTextBox
        }

        # Copy ForceScout
        $forceScoutDest = "$env:USERPROFILE\Downloads\SC-wKgXWicTb0XhUSNethaFN0vkhji53AY5mektJ7O_RSOdc8bEUVIEAAH_OewU.exe"
        if (-not (Test-Path $forceScoutDest)) {
            $forceScoutSource = "D:\SOFTWARE\PAYOO\SC-wKgXWicTb0XhUSNethaFN0vkhji53AY5mektJ7O_RSOdc8bEUVIEAAH_OewU.exe"
            if (Test-Path $forceScoutSource) {
                Add-Status "Copying ForceScout file..." $statusTextBox
                try {
                    Copy-Item -Path $forceScoutSource -Destination $forceScoutDest -Force -ErrorAction Stop
                    Add-Status "ForceScout    has been copied successfully!" $statusTextBox
                }
                catch {
                    Add-Status "Error copying ForceScout: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "Warning: ForceScout source file not found at $forceScoutSource" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        else {
            Add-Status "ForceScout    is already copied. Skipping..." $statusTextBox
        }

        # Copy FalconSensor folder
        $falconDest = "$env:USERPROFILE\Downloads\FalconSensor_Windows_installer (All AV)"
        if (-not (Test-Path $falconDest)) {
            $falconSource = "D:\SOFTWARE\PAYOO\FalconSensor_Windows_installer (All AV)"
            if (Test-Path $falconSource) {
                Add-Status "Copying FalconSensor folder..." $statusTextBox
                try {
                    Copy-Item -Path $falconSource -Destination $falconDest -Recurse -Force -ErrorAction Stop
                    Add-Status "FalconSensor  has been copied successfully!" $statusTextBox
                }
                catch {
                    Add-Status "Error copying FalconSensor: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "Warning: FalconSensor source folder not found at $falconSource" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        else {
            Add-Status "FalconSensor  is already copied. Skipping..." $statusTextBox
        }

        # Copy device-specific agent
        if ($deviceType -eq "Desktop") {
            $agentDest = "$env:USERPROFILE\Downloads\Desktop Agent.exe"
            if (-not (Test-Path $agentDest)) {
                $agentSource = "D:\SOFTWARE\PAYOO\Desktop Agent.exe"
                if (Test-Path $agentSource) {
                    Add-Status "Copying Desktop Agent file..." $statusTextBox
                    try {
                        Copy-Item -Path $agentSource -Destination $agentDest -Force -ErrorAction Stop
                        Add-Status "Desktop Agent has been copied successfully!" $statusTextBox
                    }
                    catch {
                        Add-Status "Error copying Desktop Agent: $_" $statusTextBox ([System.Drawing.Color]::Red)
                    }
                }
                else {
                    Add-Status "Warning: Desktop Agent source file not found at $agentSource" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            else {
                Add-Status "Desktop Agent is already copied. Skipping..." $statusTextBox
            }
        }
        elseif ($deviceType -eq "Laptop") {
            # Copy Laptop Agent
            $agentDest = "$env:USERPROFILE\Downloads\Laptop Agent.exe"
            if (-not (Test-Path $agentDest)) {
                $agentSource = "D:\SOFTWARE\PAYOO\Laptop Agent.exe"
                if (Test-Path $agentSource) {
                    Add-Status "Copying Laptop Agent file..." $statusTextBox
                    try {
                        Copy-Item -Path $agentSource -Destination $agentDest -Force -ErrorAction Stop
                        Add-Status "Laptop Agent  has been copied successfully!" $statusTextBox
                    }
                    catch {
                        Add-Status "Error copying Laptop Agent: $_" $statusTextBox ([System.Drawing.Color]::Red)
                    }
                }
                else {
                    Add-Status "Warning: Laptop Agent source file not found at $agentSource" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            else {
                Add-Status "Laptop Agent  is already copied. Skipping..." $statusTextBox
            }

            # Copy MDM for laptops
            $mdmDest = "$env:USERPROFILE\Downloads\ManageEngine_MDMLaptopEnrollment"
            if (-not (Test-Path $mdmDest)) {
                $mdmSource = "D:\SOFTWARE\PAYOO\ManageEngine_MDMLaptopEnrollment"
                if (Test-Path $mdmSource) {
                    Add-Status "Copying MDM files..." $statusTextBox
                    try {
                        Copy-Item -Path $mdmSource -Destination $mdmDest -Recurse -Force -ErrorAction Stop
                        Add-Status "MDM           has been copied successfully!" $statusTextBox
                    }
                    catch {
                        Add-Status "Error copying MDM: $_" $statusTextBox ([System.Drawing.Color]::Red)
                    }
                }
                else {
                    Add-Status "Warning: MDM source folder not found at $mdmSource" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            else {
                Add-Status "MDM           is already copied. Skipping..." $statusTextBox
            }
        }

        Add-Status "All files have been copied successfully!!!" $statusTextBox
        return $true
    }
    catch {
        Add-Status "CRITICAL ERROR in Copy-SoftwareFiles: $_" $statusTextBox ([System.Drawing.Color]::Red)
        Add-Status "Error details: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}
# CHỈ copy theo danh sách Pending, không thay thế Copy-SoftwareFiles cũ
function Copy-SoftwareFilesSelective {
    param(
        [ValidateSet('Desktop','Laptop')]
        [string]$DeviceType,
        [array]$Apps,  # mảng meta trả về từ Plan-SoftwareInstall().Pending
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )

    $tempDir = "$env:USERPROFILE\Downloads\SETUP"
    $setupDir = Join-Path $tempDir "Software"
    $office2019Dir = Join-Path $tempDir "Office2019"

    # Chuẩn bị thư mục
    if (-not (Test-Path $tempDir)) { New-Item -Path $tempDir -ItemType Directory -Force | Out-Null }
    if (-not (Test-Path $setupDir)) { New-Item -Path $setupDir -ItemType Directory -Force | Out-Null }

    # Nguồn chuẩn theo code cũ
    $srcSETUP = "D:\SOFTWARE\PAYOO\SETUP"
    $srcOffice = "D:\SOFTWARE\OFFICE\Office 2019"

    foreach ($app in $Apps) {
        switch ($app.Id) {
            '7zip' {
                if (Test-Path $srcSETUP) {
                    $file = Get-ChildItem -Path $srcSETUP -Name "7z*.exe","7-Zip*.exe","7zip*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($file) {
                        Copy-Item -Path (Join-Path $srcSETUP $file) -Destination (Join-Path $setupDir $file) -Force
                        Add-Status "Copy: 7-Zip -> $setupDir\$file" $statusTextBox
                    } else {
                        Add-Status "Missing 7-Zip installer in $srcSETUP" $statusTextBox ([System.Drawing.Color]::Yellow)
                    }
                }
            }
            'chrome' {
                $src = Join-Path $srcSETUP "ChromeSetup.exe"
                if (Test-Path $src) {
                    Copy-Item -Path $src -Destination (Join-Path $setupDir "ChromeSetup.exe") -Force
                    Add-Status "Copy: Chrome -> $setupDir\ChromeSetup.exe" $statusTextBox
                } else {
                    Add-Status "Missing ChromeSetup.exe in $srcSETUP" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            'laps' {
                $src = Join-Path $srcSETUP "LAPS_x64.msi"
                if (Test-Path $src) {
                    Copy-Item -Path $src -Destination (Join-Path $setupDir "LAPS_x64.msi") -Force
                    Add-Status "Copy: LAPS -> $setupDir\LAPS_x64.msi" $statusTextBox
                } else {
                    Add-Status "Missing LAPS_x64.msi in $srcSETUP" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            'foxit' {
                if (Test-Path $srcSETUP) {
                    $file = Get-ChildItem -Path $srcSETUP -Name "FoxitPDFReader*.exe","FoxitReader*.exe","Foxit*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($file) {
                        Copy-Item -Path (Join-Path $srcSETUP $file) -Destination (Join-Path $setupDir $file) -Force
                        Add-Status "Copy: Foxit -> $setupDir\$file" $statusTextBox
                    } else {
                        Add-Status "Missing Foxit installer in $srcSETUP" $statusTextBox ([System.Drawing.Color]::Yellow)
                    }
                }
            }
            'office2019' {
                if (Test-Path $srcOffice) {
                    if (-not (Test-Path $office2019Dir)) { New-Item -Path $office2019Dir -ItemType Directory -Force | Out-Null }
                    Copy-Item -Path (Join-Path $srcOffice "*") -Destination $office2019Dir -Recurse -Force
                    Add-Status "Copy: Office2019 -> $office2019Dir" $statusTextBox
                } else {
                    Add-Status "Missing Office 2019 source in $srcOffice" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            'zoom' {
                $src = Join-Path $srcSETUP "ZoomInstallerFull.exe"
                if (Test-Path $src) {
                    Copy-Item -Path $src -Destination (Join-Path $setupDir "ZoomInstallerFull.exe") -Force
                    Add-Status "Copy: Zoom -> $setupDir\ZoomInstallerFull.exe" $statusTextBox
                } else {
                    Add-Status "Missing ZoomInstallerFull.exe in $srcSETUP" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            'checkpointvpn' {
                $src = Join-Path $srcSETUP "CheckPointVPN.msi"
                if (Test-Path $src) {
                    Copy-Item -Path $src -Destination (Join-Path $setupDir "CheckPointVPN.msi") -Force
                    Add-Status "Copy: CheckPointVPN -> $setupDir\CheckPointVPN.msi" $statusTextBox
                } else {
                    Add-Status "Missing CheckPointVPN.msi in $srcSETUP" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
        }
    }

    return $true
}
# Detect helpers
function Test-7ZipInstalled {
    $paths = @(
        "C:\Program Files\7-Zip\7z.exe",
        "C:\Program Files (x86)\7-Zip\7z.exe"
    )
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}
function Test-ChromeInstalled {
    $paths = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    )
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}
function Test-LAPSInstalledOrBuiltin {
    try {
        $osInfo = Get-ComputerInfo
        $isWindows11 = $osInfo.WindowsProductName -like "*Windows 11*"
        if ($isWindows11) { return @{ BuiltIn=$true; Installed=$true } }
    } catch {}
    $dll = "C:\Program Files\LAPS\CSE\AdmPwd.dll"
    return @{ BuiltIn=$false; Installed=(Test-Path $dll) }
}
function Test-FoxitInstalled {
    $paths = @(
        "C:\Program Files (x86)\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe",
        "C:\Program Files\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe",
        "C:\Program Files (x86)\Foxit Software\Foxit Reader\FoxitReader.exe",
        "C:\Program Files\Foxit Software\Foxit Reader\FoxitReader.exe"
    )
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}
function Test-Office2019Installed {
    return (Test-Path "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE")
}
function Test-ZoomInstalled {
    $paths = @(
        "$env:USERPROFILE\AppData\Roaming\Zoom\bin\Zoom.exe",
        "C:\Program Files\Zoom\bin\Zoom.exe",
        "C:\Program Files (x86)\Zoom\bin\Zoom.exe"
    )
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}
function Test-CheckPointVPNInstalled {
    return (Test-Path "C:\Program Files (x86)\CheckPoint\Endpoint Connect\trac.exe")
}
# Lập kế hoạch theo deviceType
function Plan_SoftwareInstall {
    param(
        [ValidateSet('Desktop','Laptop')]
        [string]$DeviceType,
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )

    $pending = @()
    $skipped = @()
    $appsMeta = @(
        # Id, DisplayName, Device constraint, loại copy cần
        @{ Id='onedrive'; Display='OneDrive (uninstall only)'; Device='All' },       # chỉ log state, không copy
        @{ Id='7zip'; Display='7-Zip'; Device='All' },
        @{ Id='chrome'; Display='Google Chrome'; Device='All' },
        @{ Id='laps'; Display='LAPS'; Device='All' },
        @{ Id='foxit'; Display='Foxit Reader'; Device='All' },
        @{ Id='office2019'; Display='Office 2019'; Device='All' },
        @{ Id='zoom'; Display='Zoom'; Device='Laptop' },
        @{ Id='checkpointvpn'; Display='CheckPoint VPN'; Device='Laptop' }
    )

    foreach ($app in $appsMeta) {
        if ($app.Device -ne 'All' -and $app.Device -ne $DeviceType) { continue }

        switch ($app.Id) {
            'onedrive' {
                if (Test-OneDriveInstalled) { $pending += $app } else { $skipped += $app }
            }
            '7zip' {
                if (Test-7ZipInstalled) { $skipped += $app } else { $pending += $app }
            }
            'chrome' {
                if (Test-ChromeInstalled) { $skipped += $app } else { $pending += $app }
            }
            'laps' {
                $laps = Test-LAPSInstalledOrBuiltin
                if ($laps.Installed) { $skipped += $app } else { $pending += $app }
            }
            'foxit' {
                if (Test-FoxitInstalled) { $skipped += $app } else { $pending += $app }
            }
            'office2019' {
                if (Test-Office2019Installed) { $skipped += $app } else { $pending += $app }
            }
            'zoom' {
                if (Test-ZoomInstalled) { $skipped += $app } else { $pending += $app }
            }
            'checkpointvpn' {
                if (Test-CheckPointVPNInstalled) { $skipped += $app } else { $pending += $app }
            }
        }
    }

    # Log nhanh
    if ($statusTextBox) {
        if ($skipped.Count -gt 0) {
            $skippedDisplays = $skipped | ForEach-Object { $_.Display }
            Add-Status ("Skipped: " + ($skippedDisplays -join ", ")) $statusTextBox ([System.Drawing.Color]::Gray)
        }
        if ($pending.Count -gt 0) {
            $pendingDisplays = $pending | ForEach-Object { $_.Display }
            Add-Status ("Pending: " + ($pendingDisplays -join ", ")) $statusTextBox ([System.Drawing.Color]::Yellow)
        } else {
            Add-Status "No pending apps. Everything is already installed." $statusTextBox ([System.Drawing.Color]::Green)
        }
    }

    return @{
        Pending = $pending
        Skipped = $skipped
        Meta    = $appsMeta
    }
}
# Orchestrator chính cho nút Install
function Invoke-InstallSoftware {
    param(
        [ValidateSet('Desktop','Laptop')]
        [string]$DeviceType,
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )

    Add-Status "STEP 1: Detecting installed software..." $statusTextBox
    $plan = Plan_SoftwareInstall -DeviceType $DeviceType -statusTextBox $statusTextBox

    if (-not $plan.Pending -or $plan.Pending.Count -eq 0) {
        Add-Status "Nothing to install. Skipping copy and install steps." $statusTextBox ([System.Drawing.Color]::Green)
        return $true
    }

    Add-Status "STEP 2: Copying installers for pending apps..." $statusTextBox
    $okCopy = Copy-SoftwareFilesSelective -DeviceType $DeviceType -Apps $plan.Pending -statusTextBox $statusTextBox
    if (-not $okCopy) {
        Add-Status "Error: Failed to copy required installers. Aborting." $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }

    Add-Status "STEP 3: Installing pending software..." $statusTextBox
    $okInstall = Install-Software -deviceType $DeviceType $statusTextBox
    if ($okInstall) {
        Add-Status "All pending software installation completed successfully!" $statusTextBox
        return $true
    } else {
        Add-Status "Warning: Some installations may have failed." $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

function Install-Software {param ([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        $tempDir = "$env:USERPROFILE\Downloads\SETUP"
        $setupDir = "$tempDir\Software"
        $office2019Dir = "$tempDir\Office2019"

        # 1. Check and uninstall OneDrive if present
        if (Test-OneDriveInstalled) {
            $result = Uninstall-OneDriveComplete -statusTextBox $statusTextBox

            if ($result) {
                Add-Status "OneDrive: Has been uninstalled!" $statusTextBox
            } else {
                Add-Status "OneDrive: Removal incomplete. Check Control Panel." $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        } else {
            Add-Status "OneDrive:     Has not installed. Skipping..." $statusTextBox
        }

        # 2. Install 7-Zip - FIXED VERSION
        $sevenZipPaths = @(
            "C:\Program Files\7-Zip\7z.exe",
            "C:\Program Files (x86)\7-Zip\7z.exe"
        )

        $sevenZipInstalled = $false
        foreach ($path in $sevenZipPaths) {
            if (Test-Path $path) {
                $sevenZipInstalled = $true
                break
            }
        }

        if (-not $sevenZipInstalled) {
            # TÃ¬m file installer vá»›i nhiá»u pattern

            $sevenZipFiles = @()
            $searchPatterns = @("7z*.exe", "7-Zip*.exe", "7zip*.exe")

            foreach ($pattern in $searchPatterns) {
                $foundFiles = Get-ChildItem -Path $setupDir -Name $pattern -ErrorAction SilentlyContinue
                if ($foundFiles) {
                    $sevenZipFiles += $foundFiles
                    break
                }
            }

            if ($sevenZipFiles.Count -gt 0) {
                $sevenZipInstaller = "$setupDir\$($sevenZipFiles[0])"
                Add-Status "Installing 7-Zip..." $statusTextBox

                try {
                    # CÃà i Ä‘áº·t vá»›i kiá»ƒm tra exit code
                    $result = Start-Process -FilePath $sevenZipInstaller -ArgumentList "/S" -Wait -PassThru -WindowStyle Hidden

                    if ($result.ExitCode -eq 0) {
                        Add-Status "7-Zip installed successfully!" $statusTextBox
                    }
                    else {
                        Add-Status "WARNING: 7-Zip EXE installation returned exit code: $($result.ExitCode)" $statusTextBox ([System.Drawing.Color]::Red)
                    }
                }
                catch {
                    Add-Status "ERROR: 7-Zip installation failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
        }
        else {
            Add-Status "7-Zip:        Already installed. Skipping..." $statusTextBox
        }


        # 3. Install Chrome
        $chromeCheck = @(
            "C:\Program Files\Google\Chrome\Application\chrome.exe",
            "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        )
        $chromeInstalled = $false
        foreach ($path in $chromeCheck) {
            if (Test-Path $path) {
                $chromeInstalled = $true
                break
            }
        }

        if (-not $chromeInstalled) {
            $chromeInstaller = "$setupDir\ChromeSetup.exe"
            if (Test-Path $chromeInstaller) {
                Add-Status "Installing Chrome..." $statusTextBox
                try {
                    Start-Process -FilePath $chromeInstaller -ArgumentList "/silent /install" -Wait
                    Add-Status "Chrome installed successfully!" $statusTextBox
                }
                catch {
                    Add-Status "ERROR: Chrome installation failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "ERROR: Chrome installer not found at $chromeInstaller" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "Chrome:       Already installed. Skipping..." $statusTextBox
        }

        # 4. Install LAPS - Skip on Windows 11 as it's built-in
        $osInfo = Get-ComputerInfo
        $isWindows11 = $osInfo.WindowsProductName -like "*Windows 11*"

        if ($isWindows11) {
            Add-Status "LAPS:         Skipping on Windows 11 (built-in feature)" $statusTextBox
        }
        elseif (-not (Test-Path "C:\Program Files\LAPS\CSE\AdmPwd.dll")) {
            $lapsInstaller = "$setupDir\LAPS_x64.msi"
            if (Test-Path $lapsInstaller) {
                Add-Status "Installing LAPS..." $statusTextBox
                try {
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$lapsInstaller`" /quiet" -Wait
                    Add-Status "LAPS installed successfully!" $statusTextBox
                }
                catch {
                    Add-Status "ERROR: LAPS installation failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "ERROR: LAPS installer not found at $lapsInstaller" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "LAPS:         Already installed. Skipping..." $statusTextBox
        }

        # 5. Install Foxit Reader - COMPLETELY SILENT VERSION
        $foxitCheck = @(
            "C:\Program Files (x86)\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe",
            "C:\Program Files\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe",
            "C:\Program Files (x86)\Foxit Software\Foxit Reader\FoxitReader.exe",
            "C:\Program Files\Foxit Software\Foxit Reader\FoxitReader.exe"
        )

        $foxitInstalled = $false
        foreach ($path in $foxitCheck) {
            if (Test-Path $path) {
                $foxitInstalled = $true
                break
            }
        }

        if (-not $foxitInstalled) {
            # TÃ¬m file installer vá»›i nhiá»u pattern
            $foxitFiles = @()
            $searchPatterns = @("FoxitPDFReader*.exe", "FoxitReader*.exe", "Foxit*.exe")

            foreach ($pattern in $searchPatterns) {
                $foundFiles = Get-ChildItem -Path $setupDir -Name $pattern -ErrorAction SilentlyContinue
                if ($foundFiles) {
                    $foxitFiles += $foundFiles
                    break
                }
            }

            if ($foxitFiles.Count -gt 0) {
                $foxitPath = "$setupDir\$($foxitFiles[0])"
                Add-Status "Installing Foxit Reader..." $statusTextBox

                try {
                    # Sá»¬ Dá»¤NG /VERYSILENT Äá»‚ áº¨N HOÃ€N TOÃ€N Báº¢NG SETUP
                    $result = Start-Process -FilePath $foxitPath -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait -PassThru -WindowStyle Hidden

                    if ($result.ExitCode -eq 0) {
                        Add-Status "Foxit Reader installed successfully!" $statusTextBox
                    }
                    else {
                        Add-Status "ERROR: Foxit Reader installation failed (Exit code: $($result.ExitCode))" $statusTextBox ([System.Drawing.Color]::Red)
                    }
                }
                catch {
                    Add-Status "ERROR: Foxit Reader installation failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "ERROR: Foxit Reader installer not found in $setupDir" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "Foxit Reader: Already installed. Skipping..." $statusTextBox
        }

        # 6. Install Office 2019
        if (-not (Test-Path "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE")) {
            $officeSetup = "$office2019Dir\setup.exe"
            if (Test-Path $officeSetup) {
                Add-Status "Installing Office 2019..." $statusTextBox
                try {
                    Start-Process -FilePath $officeSetup -ArgumentList "/configure `"$office2019Dir\configuration.xml`"" -Wait
                    Add-Status "Office 2019 installed successfully!" $statusTextBox
                }
                catch {
                    Add-Status "ERROR: Office 2019 installation failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "ERROR: Office 2019 setup not found at $officeSetup" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "Office 2019:  Already installed. Skipping..." $statusTextBox
        }

        # 7. Install Zoom
        if ($deviceType -eq "Laptop") {
            $zoomCheck = @(
                "$env:USERPROFILE\AppData\Roaming\Zoom\bin\Zoom.exe",
                "C:\Program Files\Zoom\bin\Zoom.exe",
                "C:\Program Files (x86)\Zoom\bin\Zoom.exe"
            )
            $zoomInstalled = $false
            foreach ($path in $zoomCheck) {
                if (Test-Path $path) {
                    $zoomInstalled = $true
                    break
                }
            }
            if (-not $zoomInstalled) {
                $zoomInstaller = "$setupDir\ZoomInstallerFull.exe"
                if (Test-Path $zoomInstaller) {
                    Add-Status "Installing Zoom..." $statusTextBox
                    try {
                        Start-Process -FilePath $zoomInstaller -ArgumentList "/silent" -Wait
                        Add-Status "Zoom installed successfully!" $statusTextBox
                    }
                    catch {
                        Add-Status "ERROR: Zoom installation failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
                    }
                }
                else {
                    Add-Status "ERROR: Zoom installer not found at $zoomInstaller" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "Zoom:         Already installed. Skipping..." $statusTextBox
            }

            # 8. Install CheckPointVPN
            if (-not (Test-Path "C:\Program Files (x86)\CheckPoint\Endpoint Connect\trac.exe")) {
                $vpnInstaller = "$setupDir\CheckPointVPN.msi"
                if (Test-Path $vpnInstaller) {
                    Add-Status "Installing CheckPointVPN..." $statusTextBox
                    try {
                        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$vpnInstaller`" /quiet" -Wait
                        Add-Status "CheckPointVPN installed successfully!" $statusTextBox
                    }
                    catch {
                        Add-Status "ERROR: CheckPointVPN installation failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
                    }
                }
                else {
                    Add-Status "ERROR: CheckPointVPN installer not found at $vpnInstaller" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "CheckPointVPN:Already installed. Skipping..." $statusTextBox
            }
        }
        return $true
    }
    catch {
        Add-Status "CRITICAL ERROR in Install-Software: $_" $statusTextBox ([System.Drawing.Color]::Red)
        Add-Status "Error details: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

function Test-OneDriveInstalled {
    # Method 1: Check via registry (most accurate)
    $uninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($keyPath in $uninstallKeys) {
        try {
            $programs = Get-ItemProperty $keyPath -ErrorAction SilentlyContinue | Where-Object {
                $_.DisplayName -like "*OneDrive*" -or $_.DisplayName -like "*Microsoft OneDrive*"
            }
            if ($programs) {
                return $true
            }
        }
        catch {
            Add-Status "ERROR: OneDrive installation check failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }
    }

    # Method 2: Check via file system
    $oneDrivePaths = @(
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
        "$env:PROGRAMFILES\Microsoft OneDrive\OneDrive.exe",
        "$env:PROGRAMFILES(x86)\Microsoft OneDrive\OneDrive.exe"
    )

    foreach ($path in $oneDrivePaths) {
        if (Test-Path $path) {
            return $true
        }
    }

    # Method 3: Check via Get-Package
    try {
        $package = Get-Package | Where-Object { $_.Name -like "*OneDrive*" }
        if ($package) {
            return $true
        }
    }
    catch {
        # Package method not available
    }

    return $false
}

function Uninstall-OneDriveComplete {param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # First, verify OneDrive is actually installed
        if (-not (Test-OneDriveInstalled)) {
            Add-Status "OneDrive:     Not found in system. Skipping..." $statusTextBox
            return $true
        }

        Add-Status "OneDrive detected. Starting uninstallation..." $statusTextBox

        # Step 1: Kill all OneDrive processes first
        $oneDriveProcesses = @("OneDrive", "OneDriveSetup", "FileCoAuth", "OneDriveStandaloneUpdater", "OneDriveUpdaterService")

        foreach ($processName in $oneDriveProcesses) {
            try {
                $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
                if ($processes) {
                    foreach ($proc in $processes) {
                        $proc.Kill()
                        Start-Sleep -Milliseconds 500
                    }
                }
            }
            catch {
                Add-Status "ERROR: OneDrive uninstallation failed: $_" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }

        # Step 2: Try registry-based uninstall with verification
        $uninstallSuccess = $false
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        )

        foreach ($regPath in $registryPaths) {
            if ($uninstallSuccess) { break }

            try {
                $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue

                foreach ($key in $subKeys) {
                    $program = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue

                    if ($program.DisplayName -like "*OneDrive*" -and $program.UninstallString) {
                        $uninstallString = $program.UninstallString

                        # Try different uninstall approaches
                        $uninstallCommands = @()

                        # Add quiet uninstall if available
                        if ($program.QuietUninstallString) {
                            $uninstallCommands += $program.QuietUninstallString
                        }

                        # Parse regular uninstall string and add silent parameters
                        if ($uninstallString -match '"([^"]+)"(.*)') {
                            $exe = $matches[1]
                            $args = $matches[2].Trim()
                            $uninstallCommands += "`"$exe`" $args /quiet /norestart"
                            $uninstallCommands += "`"$exe`" $args /S"
                            $uninstallCommands += "`"$exe`" $args /silent"
                        }

                        # Try each uninstall command
                        foreach ($cmd in $uninstallCommands) {
                            try {
                                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$cmd`"" -Wait -PassThru -WindowStyle Hidden

                                if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                                    $uninstallSuccess = $true
                                    break
                                }
                                else {
                                    Add-Status "Exit code: $($process.ExitCode)" $statusTextBox ([System.Drawing.Color]::Red)
                                }
                            }
                            catch {
                                Add-Status "Command failed: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
                            }
                        }

                        if ($uninstallSuccess) { break }
                    }
                }
            }
            catch {
                Add-Status "Registry access error: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }

        # Step 3: Wait and verify uninstall
        if ($uninstallSuccess) {
            Start-Sleep -Seconds 5

            # Check if OneDrive is still installed
            $stillInstalled = Test-OneDriveInstalled

            if ($stillInstalled) {
                Add-Status "OneDrive still detected after uninstall attempt" $statusTextBox ([System.Drawing.Color]::Yellow)
                $uninstallSuccess = $false
            }
            else {
                return $true
            }
        }

        # Step 4: Try OneDriveSetup.exe method
        if (-not $uninstallSuccess) {
            $setupPaths = @(
                "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe",
                "$env:SYSTEMROOT\System32\OneDriveSetup.exe",
                "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveSetup.exe"
            )

            foreach ($setupPath in $setupPaths) {
                if (Test-Path $setupPath) {
                    try {
                        Add-Status "Using: $setupPath" $statusTextBox

                        # Try multiple uninstall parameters
                        $setupCommands = @(
                            "/uninstall /allusers",
                            "/uninstall",
                            "/uninstall /quiet"
                        )

                        foreach ($args in $setupCommands) {
                            $process = Start-Process -FilePath $setupPath -ArgumentList $args -Wait -PassThru -WindowStyle Hidden

                            if ($process.ExitCode -eq 0) {
                                Start-Sleep -Seconds 3

                                if (-not (Test-OneDriveInstalled)) {
                                    return $true
                                }
                            }
                        }
                    }
                    catch {
                        Add-Status "OneDriveSetup failed: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
                    }
                }
            }
        }

        # Step 5: Final verification and cleanup
        if (Test-OneDriveInstalled) {
            Add-Status "OneDrive still present. Manual intervention may be required." $statusTextBox ([System.Drawing.Color]::Yellow)

            # Try to open Control Panel for manual uninstall
            try {
                Start-Process -FilePath "appwiz.cpl" -WindowStyle Normal
                [System.Windows.Forms.MessageBox]::Show(
                    "Automatic uninstall failed.`n`nControl Panel has been opened.`nPlease manually uninstall 'Microsoft OneDrive'.",
                    "Manual Uninstall Required",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
            }
            catch {
                Add-Status "Could not open Control Panel" $statusTextBox ([System.Drawing.Color]::Red)
            }

            return $false
        }
        else {
            Add-Status "OneDrive has been uninstalled." $statusTextBox

            # Clean up remaining registry entries
            try {
                Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
            }
            catch {
                # Silent cleanup
            }

            return $true
        }

    }
    catch {
        Add-Status "Critical error in OneDrive removal: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

function Show-InstallSoftwareDialog {Hide-MainMenu
    # Create device type selection form
    $deviceTypeForm = New-Object System.Windows.Forms.Form
    $deviceTypeForm.Text = "Select Device Type"
    $deviceTypeForm.Size = New-Object System.Drawing.Size(485, 490)
    $deviceTypeForm.StartPosition = "CenterScreen"
    $deviceTypeForm.BackColor = [System.Drawing.Color]::Black
    $deviceTypeForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $deviceTypeForm.MaximizeBox = $false
    $deviceTypeForm.MinimizeBox = $false

    # Apply gradient background using global function
    Add-GradientBackground -form $deviceTypeForm

    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "SELECT DEVICE TYPE"
    $titleLabel.Location = New-Object System.Drawing.Point(110, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(250, 40)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $deviceTypeForm.Controls.Add($titleLabel)

    Add-TitleAnimation -titleLabel $titleLabel

    # Status text box
    $statusTextBox = New-Object System.Windows.Forms.RichTextBox
    $statusTextBox.Multiline = $true
    $statusTextBox.ScrollBars = "Vertical"
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 110)
    $statusTextBox.Size = New-Object System.Drawing.Size(450, 330)
    $statusTextBox.BackColor = [System.Drawing.Color]::Black
    $statusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusTextBox.ReadOnly = $true
    $statusTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $statusTextBox.Text = "Please select a device type..."
    $deviceTypeForm.Controls.Add($statusTextBox)

    # Desktop button
    # $btnDesktop = New-DynamicButton -text "DESKTOP" -x 10 -y 50 -width 200 -height 50 -clickAction {
    #     Add-Status "STEP 1: Copying required files for Desktop..."
    #     $copyResult = Copy-SoftwareFiles -deviceType "Desktop" $statusTextBox

    #     if ($copyResult) {
    #         Add-Status "STEP 2: Installing software for Desktop..." $statusTextBox
    #         $installResult = Install-Software -deviceType "Desktop" $statusTextBox

    #         if ($installResult) {
    #             Add-Status "All software installation completed successfully!" $statusTextBox
    #         }
    #         else {
    #             Add-Status "Warning: Some installations may have failed." $statusTextBox ([System.Drawing.Color]::Red)
    #         }
    #     }
    #     else {
    #         Add-Status "Error: Failed to copy required files. Installation aborted." $statusTextBox ([System.Drawing.Color]::Red)
    #     }
    # }
    $btnDesktop = New-DynamicButton -text "DESKTOP" -x 10 -y 50 -width 200 -height 50 -clickAction {
        Add-Status "Starting Desktop setup workflow..." $statusTextBox
        $result = Invoke-InstallSoftware -DeviceType "Desktop" -statusTextBox $statusTextBox
        if ($result) {
            Add-Status "Desktop workflow finished." $statusTextBox
        } else {
            Add-Status "Desktop workflow finished with warnings/errors." $statusTextBox ([System.Drawing.Color]::Yellow)
        }
    }
    $deviceTypeForm.Controls.Add($btnDesktop)

    # Laptop button
    # $btnLaptop = New-DynamicButton -text "LAPTOP" -x 260 -y 50 -width 200 -height 50 -clickAction {
    #     Add-Status "STEP 1: Copying required files for Laptop..."
    #     $copyResult = Copy-SoftwareFiles -deviceType "Laptop" $statusTextBox

    #     if ($copyResult) {
    #         Add-Status "STEP 2: Installing software for Laptop..."
    #         $installResult = Install-Software -deviceType "Laptop" $statusTextBox

    #         if ($installResult) {
    #             Add-Status "All software installation completed successfully!" $statusTextBox
    #         }
    #         else {
    #             Add-Status "Warning: Some installations may have failed." $statusTextBox ([System.Drawing.Color]::Red)
    #         }
    #     }
    #     else {
    #         Add-Status "Error: Failed to copy required files. Installation aborted." $statusTextBox ([System.Drawing.Color]::Red)
    #     }
    # }
    $btnLaptop = New-DynamicButton -text "LAPTOP" -x 260 -y 50 -width 200 -height 50 -clickAction {
        Add-Status "Starting Laptop setup workflow..." $statusTextBox
        $result = Invoke-InstallSoftware -DeviceType "Laptop" -statusTextBox $statusTextBox
        if ($result) {
            Add-Status "Laptop workflow finished." $statusTextBox
        } else {
            Add-Status "Laptop workflow finished with warnings/errors." $statusTextBox ([System.Drawing.Color]::Yellow)
        }
    }
    $deviceTypeForm.Controls.Add($btnLaptop)

    # Add escape handler to close the form
    $deviceTypeForm.KeyPreview = $true
    $deviceTypeForm.Add_KeyDown({if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {$deviceTypeForm.Close()}})

    # When form closes, show main menu
    $deviceTypeForm.Add_FormClosed({Show-MainMenu})

    # Show the dialog
    $deviceTypeForm.ShowDialog()
}

# [3] Power Options Functions
function Invoke-SetTimezonePower {param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        Add-Status "Setting time zone to SE Asia Standard Time..." $statusTextBox

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

        # Create power commands
        $powerCommands = @(
            "powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS LIDACTION 0",
            "powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS LIDACTION 0",
            "powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0",
            "powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS SBUTTONACTION 0",
            "powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 0",
            "powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 0",
            "powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0",
            "powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0",
            "powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0",
            "powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0",
            "powercfg /SETACTIVE SCHEME_CURRENT"
        )

        $powerScript = $powerCommands -join "; "

        # Execute power commands with elevated privileges
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-Command Start-Process cmd.exe -ArgumentList '/c $powerScript' -Verb RunAs -WindowStyle Hidden"
        $psi.UseShellExecute = $true
        $psi.Verb = "runas"
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        [System.Diagnostics.Process]::Start($psi)

        Add-Status "Time zone, power options completed successfully!!!" $statusTextBox
    }
    catch {
        Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-FirewallOn {param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        Add-Status "Turning on the firewall..." $statusTextBox

        $command = "netsh advfirewall set allprofiles state on"

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-Command Start-Process cmd.exe -ArgumentList '/c $command' -Verb RunAs -WindowStyle Hidden"
        $psi.UseShellExecute = $true
        $psi.Verb = "runas"
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        [System.Diagnostics.Process]::Start($psi)

        Add-Status "Firewall has been turned on successfully!!!" $statusTextBox
    }
    catch {
        Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-FirewallOff {param([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        Add-Status "Turning off the firewall..." $statusTextBox

        $command = "netsh advfirewall set allprofiles state off"

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-Command Start-Process cmd.exe -ArgumentList '/c $command' -Verb RunAs -WindowStyle Hidden"
        $psi.UseShellExecute = $true
        $psi.Verb = "runas"
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        [System.Diagnostics.Process]::Start($psi)

        Add-Status "Firewall has been turned off successfully!" $statusTextBox
    }
    catch {
        Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-PowerOptionsDialog {Hide-MainMenu
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
            param($sender, $e)
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

# [4] Volume Management Functions
function Update-DriveList {$driveListBox.Items.Clear()
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

function Invoke-VolumeManagementDialog {Hide-MainMenu
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

    $driveCount = Update-DriveList

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

                            # Logic mới:
                            # 1. Nếu source trống -> fill source (trừ ổ C)
                            # 2. Nếu source có rồi và khác với drive được chọn -> fill target (cho phép C)
                            # 3. Nếu cả 2 đều có rồi -> thay đổi target

                            if ([string]::IsNullOrEmpty($currentSource)) {
                                # Case 1: Source trống -> fill source (KHÔNG cho phép C)
                                if ($driveLetter -eq "C" -or $driveLetter -eq "c") {
                                    return
                                }
                                $script:extendSourceDriveTextBox.Text = $driveLetter
                            }
                            elseif ($driveLetter -eq $currentSource) {
                                # Case 2: Click vào drive đang là source -> clear target để user có thể chọn lại
                                $script:extendTargetDriveTextBox.Text = ""
                            }
                            elseif ([string]::IsNullOrEmpty($currentTarget) -or $driveLetter -ne $currentTarget) {
                                # Case 3: Target trống hoặc chọn drive khác -> fill/update target (CHO PHÉP C)
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
                    $driveCount = Update-DriveList

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
function New-ShrinkVolumeTitle {param([System.Windows.Forms.Panel]$contentPanel)

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

function New-ShrinkVolumeDriveSelector {param([System.Windows.Forms.Panel]$contentPanel)

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

function New-ShrinkVolumePartitionSizeOptions {param ([System.Windows.Forms.Panel]$contentPanel, [System.Windows.Forms.TextBox]$selectedDriveTextBox)

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

function New-ShrinkVolumeNewLabelInput {param([System.Windows.Forms.Panel]$contentPanel, [System.Windows.Forms.TextBox]$selectedDriveTextBox)

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

function Get-ShrinkVolumePartitionSize {param([System.Windows.Forms.RichTextBox]$statusTextBox)
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

function Test-ShrinkVolumeSpace {param([string]$driveLetter, [int]$sizeMB)

    # Validate drive exists and get info
    try {
        $driveInfo = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "$($driveLetter):" }
        if (-not $driveInfo) {
            Add-Status "Error: Drive $driveLetter does not exist." $statusTextBox ([System.Drawing.Color]::Red)
            return $false
        }

        $freeSpaceMB = [math]::Floor($driveInfo.FreeSpace / 1MB)
        $totalSizeMB = [math]::Floor($driveInfo.Size / 1MB)

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

function Invoke-ShrinkVolumeOperation {param([string]$driveLetter, [int]$sizeMB, [string]$newLabel)

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

function New-ShrinkVolumeActionButton {param([System.Windows.Forms.Panel]$contentPanel)

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
function New-RenameVolumeTitle {param([System.Windows.Forms.Panel]$parentPanel)
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

function New-RenameVolumeGroupBox {param([System.Windows.Forms.Panel]$parentPanel, [System.Windows.Forms.ListBox]$driveListBox)
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

function New-RenameActionButton {param([System.Windows.Forms.GroupBox]$groupBox, [System.Windows.Forms.ListBox]$driveListBox)
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
function New-ExtendVolumeTitle {param([System.Windows.Forms.Panel]$parentPanel)

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

function New-ExtendVolumeGroupBox {param([System.Windows.Forms.Panel]$parentPanel)

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

            # Kiểm tra trùng với source
            if ($script:extendSourceDriveTextBox -and $currentText -eq $script:extendSourceDriveTextBox.Text.Trim()) {
                Add-Status "Target không thể trùng với Source Drive!" $statusTextBox ([System.Drawing.Color]::Yellow)
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

function New-ExtendActionButton {param([hashtable]$extendControls, [System.Windows.Forms.RichTextBox]$statusTextBox)
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

function Test-ExtendVolumeInput {param([string]$sourceDrive, [string]$targetDrive, [System.Windows.Forms.TextBox]$statusTextBox)

    # Check if source drive is C - CHỈ CẤM SOURCE, KHÔNG CẤM TARGET
    if ($sourceDrive -eq "C") {
        Add-Status "LỖI: Không thể sử dụng ổ C làm Source Drive! Ổ C là ổ hệ thống Windows." $statusTextBox ([System.Drawing.Color]::Red)
        Add-Status "Hãy chọn ổ đĩa khác làm Source Drive." $statusTextBox ([System.Drawing.Color]::Red)
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

function Invoke-ExtendVolumeOperation {param([string]$sourceDrive, [string]$targetDrive, [System.Windows.Forms.RichTextBox]$statusTextBox)

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
                    Add-Status "⚠️ Operation completed with warnings. Check merge_log.txt for details." $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            }
            else {
                Add-Status "❌ No log file found. Operation may have failed." $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "❌ Failed to start batch process." $statusTextBox ([System.Drawing.Color]::Red)
        }
    }
    catch {
        Add-Status "❌ Error running batch operation: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
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

# [5] Activate Functions
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

function Invoke-ActivateWindows10Pro {param([System.Windows.Forms.RichTextBox]$statusTextBox)
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

function Invoke-ActivateOffice2019 {param([System.Windows.Forms.RichTextBox]$statusTextBox)
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
            $keyResult = & cscript //nologo "$officePath" /inpkey:Q2NKY-J42YJ-X2KVK-9Q9PT-MKP63 2>&1
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
        Add-Status "CRITICAL ERROR in Office activation: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-UpgradeWindowsHomeToPro {param([System.Windows.Forms.RichTextBox]$statusTextBox)
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

function Invoke-ActivationDialog {Hide-MainMenu
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

# [6] Features Functions
function Invoke-WindowsFeaturesConfiguration {param ([string]$deviceType,[System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        # --- 1. Check and Enable Required Features ---
        Invoke-EnableWindowsFeatures $statusTextBox
        # --- 2. Check and Disable Unnecessary Features ---
        Invoke-DisableWindowsFeatures $statusTextBox
        return $true
    }
    catch {
        Add-Status "ERROR during Windows Features Configuration: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

function Invoke-FeaturesDialog {Hide-MainMenu
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
            Show-MainMenu
        })

    # Show the dialog
    $featuresForm.ShowDialog()
}

function Invoke-EnableWindowsFeatures {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    # Danh sách các features cần enable
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

    foreach ($feature in $featuresToEnable) {
        try {
            # Kiá»ƒm tra tráº¡ng thÃ¡i hiá»‡n táº¡i cá»§a feature báº±ng PowerShell cmdlet
            $currentFeature = Get-WindowsOptionalFeature -Online -FeatureName $feature.Name -ErrorAction SilentlyContinue
            if ($currentFeature) {
                $currentState = $currentFeature.State
                if ($currentState -eq "Enabled") {
                    Add-Status "$($feature.DisplayName): Already enabled. Skipping..." $statusTextBox
                }
                elseif ($currentState -eq "Disabled") {
                    Add-Status "$($feature.DisplayName): Currently disabled. Enabling..." $statusTextBox

                    # Enable feature using DISM command
                    $enableArgs = $feature.Command.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Skip 1
                    $enableResult = Start-Process -FilePath "dism" -ArgumentList $enableArgs -Wait -PassThru -WindowStyle Hidden

                    if ($enableResult.ExitCode -eq 0) {
                        Add-Status "$($feature.DisplayName): Enabled successfully!" $statusTextBox
                    }
                    elseif ($enableResult.ExitCode -eq 3010) {
                        Add-Status "$($feature.DisplayName): Enabled successfully! (Restart required)" $statusTextBox
                    }
                    else {
                        Add-Status "WARNING: Failed to enable $($feature.DisplayName) (Exit code: $($enableResult.ExitCode))" $statusTextBox([System.Drawing.Color]::Yellow)
                    }
                }
                else {
                    Add-Status "WARNING: $($feature.DisplayName) is in unexpected state: $currentState" $statusTextBox([System.Drawing.Color]::Yellow)
                }
            }
            else {
                Add-Status "WARNING: Could not find feature $($feature.Name)" $statusTextBox([System.Drawing.Color]::Yellow)
            }

        }
        catch {
            Add-Status "ERROR: Failed to process $($feature.DisplayName): $_" $statusTextBox([System.Drawing.Color]::Red)
        }
    }
}

function Invoke-DisableWindowsFeatures {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    # Take OS version
    $osVersion = (Get-CimInstance Win32_OperatingSystem).Caption

    # List features to disable
    $featuresToDisable = @(
        @{
            Name        = "Internet-Explorer-Optional-amd64"
            DisplayName = "IExplorer 11"
            Command     = "dism /online /disable-feature /featurename:Internet-Explorer-Optional-amd64 /norestart"
            SupportedOS = "Windows 10"
        }
    )

    foreach ($feature in $featuresToDisable) {
        # Check if feature should be applied on current OS
        if ($feature.SupportedOS -and -not ($osVersion -like "*$($feature.SupportedOS)*")) {
            Add-Status "$($feature.DisplayName): Not apply on $osVersion. Skipping..." $statusTextBox
            continue
        }
        try {
            # Check current feature state
            $currentFeature = Get-WindowsOptionalFeature -Online -FeatureName $feature.Name -ErrorAction SilentlyContinue

            if ($currentFeature) {
                $currentState = $currentFeature.State
                if ($currentState -eq "Disabled") {
                    Add-Status "$($feature.DisplayName): Already disabled.Skipping..." $statusTextBox
                }
                elseif ($currentState -eq "Enabled") {
                    Add-Status "$($feature.DisplayName): Currently enabled. Disabling..." $statusTextBox

                    # Disable feature using DISM command
                    $disableArgs = $feature.Command.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Skip 1
                    $disableResult = Start-Process -FilePath "dism" -ArgumentList $disableArgs -Wait -PassThru -WindowStyle Hidden

                    if ($disableResult.ExitCode -eq 0) {
                        Add-Status "$($feature.DisplayName): Disabled successfully!" $statusTextBox
                    }
                    elseif ($disableResult.ExitCode -eq 3010) {
                        Add-Status "$($feature.DisplayName): Disabled successfully! (Restart required)" $statusTextBox
                    }
                    else {
                        Add-Status "WARNING: Failed to disable $($feature.DisplayName) (Exit code: $($disableResult.ExitCode))" $statusTextBox([System.Drawing.Color]::Yellow)
                    }

                    # Verify new state
                    Start-Sleep -Seconds 2
                    $newFeature = Get-WindowsOptionalFeature -Online -FeatureName $feature.Name -ErrorAction SilentlyContinue
                    if ($newFeature) {
                        Add-Status "$($feature.DisplayName): Verified new state is $($newFeature.State)" $statusTextBox
                    }
                }
                else {
                    Add-Status "WARNING: $($feature.DisplayName) is in unexpected state: $currentState" $statusTextBox([System.Drawing.Color]::Yellow)
                }
            }
            else {
                Add-Status "WARNING: Could not find feature $($feature.Name)" $statusTextBox([System.Drawing.Color]::Yellow)
            }

        }
        catch {
            Add-Status "ERROR: Failed to process $($feature.DisplayName): $_" $statusTextBox([System.Drawing.Color]::Red)
        }
    }
}

# [7] Rename Device Functions
function Invoke-RenameDialog {Hide-MainMenu
    # Create device rename form
    $renameForm = New-Object System.Windows.Forms.Form
    $renameForm.Text = "Rename Device"
    $renameForm.Size = New-Object System.Drawing.Size(495, 470)
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

    # Create a colored label for the current name (not $currentLabel, but $currentName itself)
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
    $newNameTextBox.Text = "HOD" # Default to Desktop
    $renameForm.Controls.Add($newNameTextBox)

    # Event handlers for radio buttons to update the default name
    $radioDesktop.Add_CheckedChanged({
            if ($radioDesktop.Checked) {
                $newNameTextBox.Text = "HOD"
            }
        })

    $radioLaptop.Add_CheckedChanged({
            if ($radioLaptop.Checked) {
                $newNameTextBox.Text = "HOL"
            }
        })

    $radioCustom.Add_CheckedChanged({
            if ($radioCustom.Checked) {
                $newNameTextBox.Text = ""
            }
        })

    # Status text box
    $statusTextBox = New-Object System.Windows.Forms.RichTextBox
    $statusTextBox.Multiline = $true
    $statusTextBox.ScrollBars = "Vertical"
    $statusTextBox.Location = New-Object System.Drawing.Point(10, 300)
    $statusTextBox.Size = New-Object System.Drawing.Size(460, 120)
    $statusTextBox.BackColor = [System.Drawing.Color]::Black
    $statusTextBox.ForeColor = [System.Drawing.Color]::Lime
    $statusTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $statusTextBox.ReadOnly = $true
    $statusTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $statusTextBox.Text = "Ready to rename device..."
    $renameForm.Controls.Add($statusTextBox)

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

            # Disable button để tránh click nhiều lần
            $renameButton.Enabled = $false

            # Clear status trước khi bắt đầu
            $statusTextBox.Clear()

            # Validation cơ bản
            if ([string]::IsNullOrWhiteSpace($newName)) {
                Add-Status "Error: Please enter a new device name!" $statusTextBox ([System.Drawing.Color]::Red)
                $renameButton.Enabled = $true
                return
            }

            # Lấy tên máy hiện tại
            $currentName = $env:COMPUTERNAME

            if ($newName -eq $currentName) {
                Add-Status "Warning: New name is the same as the current name. No action taken." $statusTextBox ([System.Drawing.Color]::Yellow)
                $renameButton.Enabled = $true
                return
            }

            # Xác nhận với user
            $confirmResult = [System.Windows.Forms.MessageBox]::Show(
                "Are you sure you want to rename this device from '$currentName' to '$newName'?`n`nThis operation requires a restart.",
                "Confirm Rename",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($confirmResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                Add-Status "Renaming device from '$currentName' to '$newName'..." $statusTextBox

                try {
                    # Sử dụng Rename-Computer trực tiếp
                    Rename-Computer -NewName $newName -Force -ErrorAction Stop
                    Add-Status "Device rename completed successfully!" $statusTextBox
                    Add-Status "Please restart your device for changes to take effect." $statusTextBox

                    # Hỏi user có muốn restart ngay không
                    $restartResult = [System.Windows.Forms.MessageBox]::Show(
                        "Do you want to restart your device now?",
                        "Restart Confirmation",
                        [System.Windows.Forms.MessageBoxButtons]::YesNo,
                        [System.Windows.Forms.MessageBoxIcon]::Question
                    )

                    if ($restartResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                        Add-Status "Restarting device..." $statusTextBox
                        Start-Sleep -Seconds 2
                        Restart-Computer -Force
                    }
                }
                catch {
                    Add-Status "Error renaming device: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
            else {
                Add-Status "Rename operation cancelled by user." $statusTextBox ([System.Drawing.Color]::Yellow)
            }

            # Re-enable button
            $renameButton.Enabled = $true
        })
    $renameForm.Controls.Add($renameButton)

    # Cancel button
    $cancelButton = New-DynamicButton  -text "Cancel" -x 250 -y 240 -width 200 -height 40 -clickAction {
        $renameForm.Close()
    } -normalColor ([System.Drawing.Color]::FromArgb(200, 0, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(255, 50, 50)) -pressColor ([System.Drawing.Color]::FromArgb(150, 0, 0))
    $renameForm.Controls.Add($cancelButton)

    # Set the accept button (Enter key)
    $renameForm.AcceptButton = $renameButton
    # Set the cancel button (Escape key)
    $renameForm.CancelButton = $cancelButton

    # When the form is closed, show the main menu again
    $renameForm.Add_FormClosed({
            Show-MainMenu
        })

    # Show the form
    $renameForm.ShowDialog()
}

# [8] Password Functions
function Show-SetPasswordForm {param ([string]$currentUser,[System.Windows.Forms.RichTextBox]$statusTextBox)
    # Hide main menu
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
    $presetComboBox.Items.AddRange(@(
        "Custom (enter below)",
        "Pr0t3ct10c@1@VU",
        "Aa1234567890"
    ))
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
            $success = Set-UserPassword -user $currentUser -password $dialogResult.Password
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

function Set-UserPassword {param ([string]$user,[string]$password)
    try {
        if ([string]::IsNullOrEmpty($password)) {
            $command = "net user $user """""
        }
        else {
            $command = "net user $user $password"
        }
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -NoNewWindow -Wait -PassThru
        return $process.ExitCode -eq 0
    }
    catch {
        return $false
    }
}

function Remove-UserPassword {param ([string]$user)
    try {
        $command = "net user $user "
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -NoNewWindow -Wait -PassThru
        return $process.ExitCode -eq 0
    }
    catch {
        return $false
    }
}

function Invoke-SetPasswordDialog {param([string]$currentUser,[System.Windows.Forms.RichTextBox]$statusTextBox,[bool]$showMenuAfter = $false)$result = Show-SetPasswordForm -currentUser $currentUser -statusTextBox $statusTextBox
    if ($result.Action -eq "set") {
        $success = Set-UserPassword -user $currentUser -password $result.Password
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
$script:DomainConfig = @{FormWidth = 500;FormHeight = 450;FormHeightMinimal = 380;ButtonY = 350;ButtonYMinimal = 280;ControlSpacing = 40;DefaultWorkgroup = "WORKGROUP"}

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

function New-DomainManagementLabel {param([string]$Text,[int]$X,[int]$Y,[int]$Width,[int]$Height,[int]$FontSize = 12,[System.Drawing.FontStyle]$FontStyle = [System.Drawing.FontStyle]::Regular)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Font = New-Object System.Drawing.Font("Arial", $FontSize, $FontStyle)
    $label.ForeColor = [System.Drawing.Color]::White
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.Location = New-Object System.Drawing.Point($X, $Y)

    return $label
}

function New-DomainManagementTextBox {param([int]$X,[int]$Y,[int]$Width,[int]$Height,[bool]$IsPassword = $false,[string]$DefaultText = "")
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Font = New-Object System.Drawing.Font("Arial", 12)
    $textBox.Size = New-Object System.Drawing.Size($Width, $Height)
    $textBox.Location = New-Object System.Drawing.Point($X, $Y)
    $textBox.BackColor = [System.Drawing.Color]::White
    $textBox.ForeColor = [System.Drawing.Color]::Black
    $textBox.Text = $DefaultText
    if ($IsPassword) {$textBox.UseSystemPasswordChar = $true}
    return $textBox
}

function New-DomainManagementRadioButton {param([string]$Text,[int]$X,[int]$Y,[int]$Width,[int]$Height,[bool]$IsChecked = $false,[bool]$IsEnabled = $true)
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

function Set-DomainFormLayout {param([hashtable]$FormControls,[string]$OperationType)
    switch ($OperationType) {
        'Domain' {
            $FormControls.NameLabel.Text = "Domain Name:"
            $FormControls.NameLabel.BackColor = [System.Drawing.Color]::Transparent
            # Set domain name - reset to default if it's workgroup name or empty
            $currentText = $FormControls.NameTextBox.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($currentText) -or $currentText -eq "WORKGROUP") {
                $FormControls.NameTextBox.Text = "vietunion.local"
            }
            $FormControls.UsernameLabel.Visible = $true
            $FormControls.UsernameTextBox.Visible = $true
            # Set username - reset to default if empty
            if ([string]::IsNullOrWhiteSpace($FormControls.UsernameTextBox.Text)) {
                $FormControls.UsernameTextBox.Text = "-hdk-hieudang"
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

function Test-DomainJoinInputs {param([string]$DomainName,[string]$Username,[string]$Password)

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

    if ([string]::IsNullOrWhiteSpace($Password)) {
        return @{
            IsValid      = $false
            ErrorMessage = "Password is required for domain join."
        }
    }

    # Additional domain name format validation
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

function Test-WorkgroupInputs {param([string]$WorkgroupName)
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

function Invoke-ElevatedDomainCommand {param([string]$Command,[string]$OperationType)
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

        if ($null -eq $process) {
            throw "Failed to start elevated process - User may have cancelled UAC prompt"
        }

        # Wait for the process to complete (with timeout)
        $timeout = 120000 # 2 minutes
        $completed = $process.WaitForExit($timeout)

        # Clean up temp file
        if (Test-Path $tempScript) {
            Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
        }

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

function Invoke-DomainJoinOperation {param([string]$DomainName,[string]$Username,[SecureString]$Password)
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
    } finally {
        if ($pwdPtr -ne [IntPtr]::Zero) {[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pwdPtr)}
    }

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

            if ($confirmResult -eq [System.Windows.Forms.DialogResult]::No) {
                return $false
            }
        }
    }
    catch {
        Write-Warning "Could not test domain connectivity: $_"
    }

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
    finally {
        if ($pwdBstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pwdBstr)
        }
    }
    return Invoke-ElevatedDomainCommand -Command $command -OperationType "DomainJoin"
}

function Invoke-WorkgroupJoinOperation {param ([string]$WorkgroupName)
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

function Show-DomainManagementForm {param ([string]$deviceType,[System.Windows.Forms.RichTextBox]$statusTextBox)
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
    if (-not $computerInfo.IsPartOfDomain -or $computerInfo.Domain -eq $computerInfo.ComputerName) {$domainDisplay = "$($computerInfo.Domain)"}
    else {$domainDisplay = $computerInfo.Domain}

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
    $nameTextBox.Text = "vietunion.local"  # Default domain name

    $usernameLabel = New-DomainManagementLabel -Text "Username:" -X 10 -Y 270 -Width 150 -Height 30
    $usernameLabel.BackColor = [System.Drawing.Color]::Transparent
    $usernameTextBox = New-DomainManagementTextBox -X 170 -Y 270 -Width 300 -Height 30
    $usernameTextBox.Text = "-hdk-hieudang"  # Default username

    $passwordLabel = New-DomainManagementLabel -Text "Password:" -X 10 -Y 310 -Width 150 -Height 30
    $passwordLabel.BackColor = [System.Drawing.Color]::Transparent
    $passwordTextBox = New-DomainManagementTextBox -X 170 -Y 310 -Width 300 -Height 30 -IsPassword $true

    $joinForm.Controls.AddRange(@($nameLabel, $nameTextBox, $usernameLabel, $usernameTextBox, $passwordLabel, $passwordTextBox))

    # Create buttons
    $joinButton = New-DynamicButton -text "Join" -x 35 -y $script:DomainConfig.ButtonY -width 200 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 180, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 220, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 140, 0)) -textColor ([System.Drawing.Color]::White) -fontSize 12 -fontStyle ([System.Drawing.FontStyle]::Bold)

    $cancelButton = New-DynamicButton -text "Cancel" -x 250 -y $script:DomainConfig.ButtonY -width 200 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(180, 0, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(220, 0, 0)) -pressColor ([System.Drawing.Color]::FromArgb(120, 0, 0)) -clickAction {
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
    $radioDomain.Add_CheckedChanged({if ($radioDomain.Checked) {Set-DomainFormLayout -FormControls $formControls -OperationType 'Domain'}})

    $radioWorkgroup.Add_CheckedChanged({if ($radioWorkgroup.Checked) {Set-DomainFormLayout -FormControls $formControls -OperationType 'Workgroup'}})

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
    $joinForm.Add_FormClosed({Show-MainMenu})

    # Show the form
    $joinForm.ShowDialog()
}

# [10] CrowdStrike Functions
function Invoke-CrowdStrikeDialog {Hide-MainMenu
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
        if ($recommendation.Type -eq "EDR") {$radioEDR.Checked = $true} else {$radioAV.Checked = $true}

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
        if ($selectedDept -like "---*" -or $selectedDept -eq "" -or $selectedDept -eq $null) {
            [System.Windows.Forms.MessageBox]::Show(
                "Please select a valid department (not a section header).",
                "Invalid Selection",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        $installType = if ($radioEDR.Checked) { "EDR" } else { "AV" }

        try {
            Invoke-InstallCrowdStrike -statusTextBox $statusTextBox -Department $selectedDept -InstallType $installType
        }
        catch {
            Add-Status "Error: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }
    }
    $crowdStrikeForm.Controls.Add($btnInstall)

    # Status button
    $btnStatus = New-DynamicButton -text "Status" -x 170 -y 180 -width 150 -height 50 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0))  -clickAction {Invoke-CheckCrowdStrikeStatus -statusTextBox $statusTextBox}
    $crowdStrikeForm.Controls.Add($btnStatus)

    # Change GroupTag button
    $btnCrowdStrikeTag = New-DynamicButton -text "Change GroupTag" -x 330 -y 180 -width 150 -height 50 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {Invoke-CrowdStrikeGroupTagDialog -Departments (@($deptComboBox.Items | ForEach-Object { $_.ToString() }))}
    $crowdStrikeForm.Controls.Add($btnCrowdStrikeTag)

    # Uninstall button
    $btnUninstall = New-DynamicButton -text "Uninstall" -x 490 -y 180 -width 150 -height 50 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {Invoke-CrowdStrikeUninstallDialog -statusTextBox $statusTextBox}
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

                if ($recommendation.Type -eq "EDR") {
                    $radioEDR.Checked = $true
                } else {
                    $radioAV.Checked = $true
                }

                $statusTextBox.Text = "Department: $selectedDept`nRecommendation: $($recommendation.Type) - $($recommendation.Reason)`n`nInstallation will follow current policy automatically."
            }
        }
    })

    # Show the form
    $crowdStrikeForm.ShowDialog()
}

function Invoke-InstallCrowdStrike {param ([System.Windows.Forms.RichTextBox]$statusTextBox,[string]$Department,[string]$InstallType)
    try {
        $statusTextBox.Clear()
        Add-Status "=== CROWDSTRIKE INSTALLATION STARTED ===" $statusTextBox ([System.Drawing.Color]::Cyan)
        Add-Status "Department: $Department" $statusTextBox ([System.Drawing.Color]::White)
        Add-Status "Installation Type: $InstallType (Policy-based)" $statusTextBox ([System.Drawing.Color]::White)

        # Check if CrowdStrike is already installed
        Add-Status "1. Checking existing installation..." $statusTextBox ([System.Drawing.Color]::Yellow)
        $csagentService = Get-Service -Name "csagent" -ErrorAction SilentlyContinue

        if ($csagentService) {
            Add-Status "   ⚠ CrowdStrike is already installed!" $statusTextBox ([System.Drawing.Color]::Yellow)
            Add-Status "   Service Status: $($csagentService.Status)" $statusTextBox ([System.Drawing.Color]::Gray)

            $confirmResult = [System.Windows.Forms.MessageBox]::Show(
                "CrowdStrike is already installed. Do you want to reinstall?",
                "CrowdStrike Already Installed",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($confirmResult -eq [System.Windows.Forms.DialogResult]::No) {Add-Status "Installation cancelled by user." $statusTextBox ([System.Drawing.Color]::Yellow) ; return}

            Add-Status "   Proceeding with reinstallation..." $statusTextBox ([System.Drawing.Color]::Yellow)
        } else {
            Add-Status "   ✓ No existing installation found" $statusTextBox ([System.Drawing.Color]::Green)
        }

        # Check for installer script
        Add-Status "2. Locating CrowdStrike installer..." $statusTextBox ([System.Drawing.Color]::Yellow)
        $scriptPath = Join-Path $PSScriptRoot "..\CrowdStrike\core\auto_installer_integrated.ps1"

        if (-not (Test-Path $scriptPath)) {
            Add-Status "   ✗ CrowdStrike installer script not found!" $statusTextBox ([System.Drawing.Color]::Red)
            Add-Status "   Expected path: $scriptPath" $statusTextBox ([System.Drawing.Color]::Gray)
            Add-Status "   Please ensure CrowdStrike installer is properly installed." $statusTextBox ([System.Drawing.Color]::Red)
            return
        }

        Add-Status "   ✓ Installer script found" $statusTextBox ([System.Drawing.Color]::Green)
        Add-Status "   Path: $scriptPath" $statusTextBox ([System.Drawing.Color]::Gray)

        # Check for installer executable
        $installerDir = Join-Path $PSScriptRoot "..\CrowdStrike\core"
        $installerPath = Join-Path $installerDir "FalconSensor_Windows.exe"

        if (-not (Test-Path $installerPath)) {
            Add-Status "   ✗ CrowdStrike installer executable not found!" $statusTextBox ([System.Drawing.Color]::Red)
            Add-Status "   Expected path: $installerPath" $statusTextBox ([System.Drawing.Color]::Gray)
            Add-Status "   Please ensure FalconSensor_Windows.exe is in the core directory." $statusTextBox ([System.Drawing.Color]::Red)
            return
        }

        Add-Status "   ✓ Installer executable found" $statusTextBox ([System.Drawing.Color]::Green)

        # Prepare installation command
        Add-Status "3. Preparing installation..." $statusTextBox ([System.Drawing.Color]::Yellow)
        $arguments = @("-ExecutionPolicy", "Bypass","-File", "`"$scriptPath`"","-Department", "`"$Department`"","-ForceInstallType", "`"$InstallType`"","-Silent")

        Add-Status "   Command: powershell.exe $($arguments -join ' ')" $statusTextBox ([System.Drawing.Color]::Gray)

        # Start installation
        Add-Status "4. Starting CrowdStrike installation..." $statusTextBox ([System.Drawing.Color]::Yellow)
        Add-Status "   This may take several minutes. Please wait..." $statusTextBox ([System.Drawing.Color]::Cyan)

        $startTime = Get-Date
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMinutes

        Add-Status "5. Installation completed!" $statusTextBox ([System.Drawing.Color]::Yellow)
        Add-Status "   Duration: $([math]::Round($duration, 2)) minutes" $statusTextBox ([System.Drawing.Color]::Gray)
        Add-Status "   Exit Code: $($process.ExitCode)" $statusTextBox ([System.Drawing.Color]::Gray)

        if ($process.ExitCode -eq 0) {
            Add-Status "   ✓ Installation completed successfully!" $statusTextBox ([System.Drawing.Color]::Green)

            # Verify installation
            Add-Status "6. Verifying installation..." $statusTextBox ([System.Drawing.Color]::Yellow)
            Start-Sleep -Seconds 3

            $newService = Get-Service -Name "csagent" -ErrorAction SilentlyContinue
            if ($newService -and $newService.Status -eq "Running") {
                Add-Status "   ✓ CrowdStrike service is running!" $statusTextBox ([System.Drawing.Color]::Green)
                Add-Status "   Service Name: $($newService.DisplayName)" $statusTextBox ([System.Drawing.Color]::Gray)
                Add-Status "=== INSTALLATION SUCCESSFUL ===" $statusTextBox ([System.Drawing.Color]::Green)
            } else {
                Add-Status "   ⚠ Service verification failed" $statusTextBox ([System.Drawing.Color]::Yellow)
                Add-Status "   The installation may need time to complete" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        } else {
            Add-Status "   ✗ Installation failed!" $statusTextBox ([System.Drawing.Color]::Red)
            Add-Status "   Please check the log file: C:\Temp\FalconInstall.log" $statusTextBox ([System.Drawing.Color]::Yellow)
        }

    } catch {
        Add-Status "Error during CrowdStrike installation: $_" $statusTextBox ([System.Drawing.Color]::Red)
        Add-Status "Please check the log file: C:\Temp\FalconInstall.log" $statusTextBox ([System.Drawing.Color]::Yellow)
    }
}

function Invoke-CheckCrowdStrikeStatus {param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    try {
        $statusTextBox.Clear()
        Add-Status "CROWDSTRIKE STATUS CHECK" $statusTextBox ([System.Drawing.Color]::Cyan)

        # 1. Service Status (CRITICAL)
        Add-Status "1. Service Status:" $statusTextBox ([System.Drawing.Color]::White)
        $csagentService = Get-Service -Name "csagent" -ErrorAction SilentlyContinue

        if ($csagentService) {
            $statusColor = if ($csagentService.Status -eq "Running") { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
            Add-Status "   ✓ CrowdStrike Falcon: $($csagentService.Status)" $statusTextBox $statusColor
        } else {
            Add-Status "   ✗ CrowdStrike not installed!" $statusTextBox ([System.Drawing.Color]::Red)
            return
        }

        # 2. Department Assignment (IMPORTANT)
        Add-Status "2. Department Assignment:" $statusTextBox ([System.Drawing.Color]::White)

        try {
            if ($csagentService.Status -eq "Running") {
                $department = Get-DepartmentFromGroupTag -GroupTag $csagentService.Tag
                if ($department) {
                    Add-Status "   ✓ Department: $department" $statusTextBox ([System.Drawing.Color]::Green)

                    # Check policy compliance
                    $recommendation = Get-DepartmentRecommendation -Department $department
                    $policyColor = if ($recommendation.Type -eq "EDR") { [System.Drawing.Color]::Orange } else { [System.Drawing.Color]::Cyan }
                    Add-Status "   Policy: $($recommendation.Type) - $($recommendation.Reason)" $statusTextBox $policyColor
                } else {
                    Add-Status "   ⚠ Unknown department mapping" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            } else {
                Add-Status "   ⚠ No department assignment found" $statusTextBox ([System.Drawing.Color]::Yellow)
                Add-Status "   Device may not be properly deployed" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        } catch {
            Add-Status "   ✗ Error checking department: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # 3. Protection Status (CRITICAL)
        Add-Status "3. Protection Status:" $statusTextBox ([System.Drawing.Color]::White)

        # Check key processes
        $criticalProcesses = @("CSFalconService", "CSFalconContainer")
        $runningProcesses = Get-Process | Where-Object {
            $criticalProcesses -contains $_.ProcessName
        } -ErrorAction SilentlyContinue

        if ($runningProcesses) {
            Add-Status "   ✓ Protection active ($($runningProcesses.Count) processes)" $statusTextBox ([System.Drawing.Color]::Green)
        } else {
            Add-Status "   ⚠ Protection processes not detected" $statusTextBox ([System.Drawing.Color]::Yellow)
        }

        # Check installation integrity
        $installPath = "${env:ProgramFiles}\CrowdStrike"
        if (Test-Path $installPath) {
            $keyFiles = @("CSFalconService.exe", "SystemTray")
            $foundFiles = $keyFiles | Where-Object { Test-Path (Join-Path $installPath $_) }
            if ($foundFiles.Count -eq $keyFiles.Count) {
                Add-Status "   ✓ Installation integrity: OK" $statusTextBox ([System.Drawing.Color]::Green)
            } else {
                Add-Status "   ⚠ Installation may be incomplete" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        } else {
            Add-Status "   ✗ Installation directory not found" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # 4. Cloud Connectivity (IMPORTANT)
        Add-Status "4. Cloud Connectivity:" $statusTextBox ([System.Drawing.Color]::White)
        try {
            $testResult = Test-NetConnection -ComputerName "ts01-b.cloudsink.net" -Port 443 -InformationLevel Quiet -ErrorAction SilentlyContinue
            if ($testResult) {
                Add-Status "   ✓ CrowdStrike cloud: Connected" $statusTextBox ([System.Drawing.Color]::Green)
            } else {
                Add-Status "   ⚠ CrowdStrike cloud: Disconnected" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        } catch {
            Add-Status "   ⚠ Could not test connectivity" $statusTextBox ([System.Drawing.Color]::Yellow)
        }

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

        if (-not $runningProcesses) {
            $issues += "Protection processes missing"
            if ($overallStatus -ne "CRITICAL") {
                $overallStatus = "WARNING"
                $statusColor = [System.Drawing.Color]::Yellow
            }
        }

        if (-not $csagentService.Tag) {
            $issues += "No department assignment"
            if ($overallStatus -eq "HEALTHY") {
                $overallStatus = "WARNING"
                $statusColor = [System.Drawing.Color]::Yellow
            }
        }

        Add-Status "Status: $overallStatus" $statusTextBox $statusColor

        if ($overallStatus -eq "HEALTHY") {
            Add-Status "✓ CrowdStrike is properly installed and protected" $statusTextBox ([System.Drawing.Color]::Green)
        } else {
            Add-Status "Issues found: $issues" $statusTextBox ([System.Drawing.Color]::Yellow)
        }
    } catch {
        Add-Status "Error checking CrowdStrike status: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Set-CrowdStrikeGroupingTag {param([Parameter(Mandatory=$true)][string]$Tag,[Parameter(Mandatory=$true)][string]$Token,[System.Windows.Forms.RichTextBox]$StatusTextBox)
    try {
        # Ensure we’re elevated
        $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
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
        } else {
            if ($StatusTextBox) { Add-Status "ERROR: CSSensorSettings exited with code $exitCode." $StatusTextBox ([System.Drawing.Color]::Red) }
            return $false
        }
    }
    catch {
        if ($StatusTextBox) { Add-Status ("ERROR: " + $_.Exception.Message) $StatusTextBox ([System.Drawing.Color]::Red) }
        return $false
    }
}

function Invoke-CrowdStrikeGroupTagDialog {param([string[]]$Departments)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "CrowdStrike Grouping Tag"
    $form.Size = New-Object System.Drawing.Size(520, 360)
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
    $chkShow.Add_CheckedChanged({
        $txtToken.UseSystemPasswordChar = -not $chkShow.Checked
    })
    $form.Controls.Add($chkShow)

    # Status box
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

    # Buttons
    $btnApply = New-Object System.Windows.Forms.Button
    $btnApply.Text = "Apply"
    $btnApply.Location = New-Object System.Drawing.Point(150, 285)
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
            } else {
                Add-Status "Failed to update tag." $status ([System.Drawing.Color]::Red)
            }
        } catch {
            Add-Status ("ERROR: " + $_.Exception.Message) $status ([System.Drawing.Color]::Red)
        }
    })
    $form.Controls.Add($btnApply)

    $form.KeyPreview = $true
    $form.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $form.Close() } })

    $form.AcceptButton = $btnApply

    $form.ShowDialog() | Out-Null
}

function Get-DepartmentRecommendation {param ([string]$Department)

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
            Type = "EDR"
            Color = [System.Drawing.Color]::Orange
            Reason = "High security department"
        }
    }
    elseif ($devDepartments -contains $Department) {
        return @{
            Type = "AV"
            Color = [System.Drawing.Color]::Cyan
            Reason = "DEV department (EDR for senior positions)"
        }
    }
    else {
        return @{
            Type = "AV"
            Color = [System.Drawing.Color]::Lime
            Reason = "Standard department"
        }
    }
}

function Get-DepartmentFromGroupTag {param ([string]$GroupTag)
    # Map group tags to departments based on our department list
    $departmentMapping = @{
        "Board-of-Directors" = "Board-of-Directors"
        "HR-Admin" = "HR-Admin"
        "Legal-Compliance" = "Legal-Compliance"
        "Marketing" = "Marketing"
        "HN-Branch" = "HN-Branch"
        "Accounting" = "Accounting"
        "Fee-Control" = "Fee-Control"
        "Data-Exchange" = "Data-Exchange"
        "Service-Operation-Division" = "Service-Operation-Division"
        "Training" = "Training"
        "Customer-Service" = "Customer-Service"
        "Account-System-Management" = "Account-System-Management"
        "Quality-of-Service" = "Quality-of-Service"
        "Project-Strategy-Division" = "Project-Strategy-Division"
        "Financial-Service-Project" = "Financial-Service-Project"
        "Bill-Payment-Project" = "Bill-Payment-Project"
        "Business-Development" = "Business-Development"
        "Network-Development" = "Network-Development"
        "E-Commerce" = "E-Commerce"
        "Omni" = "Omni"
        "Paycode" = "Paycode"
        "Digi-Gift" = "Digi-Gift"
        "Product-Management" = "Product-Management"
        "Payoo-X-and-Biz-Solutions" = "Payoo-X-and-Biz-Solutions"
        "Web" = "Web"
        "System-Integration" = "System-Integration"
        "Core-System" = "Core-System"
        "Database-Management" = "Database-Management"
        "Quality-Control" = "Quality-Control"
        "Business-Analysis" = "Business-Analysis"
        "Payoo-Plus-Digital-Transformation" = "Payoo-Plus-Digital-Transformation"
        "Mobile-App" = "Mobile-App"
        "IT-Administration" = "IT-Administration"
        "Technical-Operation" = "Technical-Operation"
        "Cyber-Security" = "Cyber-Security"
        "NTT" = "NTT"
        "Collaborator" = "Collaborator"
    }

    # Direct match
    if ($departmentMapping.ContainsKey($GroupTag)) {
        return $departmentMapping[$GroupTag]
    }

    # Fuzzy match (in case of slight variations)
    foreach ($key in $departmentMapping.Keys) {
        if ($GroupTag -like "*$key*" -or $key -like "*$GroupTag*") {
            return $departmentMapping[$key]
        }
    }

    return $GroupTag  # Return original if no mapping found
}

function Get-CrowdStrikeProductCode {
    try {
        $uninstallRoots = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )

        foreach ($root in $uninstallRoots) {
            if (-not (Test-Path $root)) { continue }
            Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                    if (-not $p) { return }
                    $name = "$($p.DisplayName) $($p.DisplayVersion)"
                    if ($name -match '(?i)crowdstrike.*(windows|falcon).*sensor') {
                        # Ưu tiên lấy GUID từ UninstallString
                        $uninst = $p.UninstallString
                        if ($uninst -and ($uninst -match '\{[0-9A-Fa-f\-]{36}\}')) {
                            return $Matches[0]
                        }
                        # Nếu key name chính là GUID
                        if ($_.PSChildName -match '^\{[0-9A-Fa-f\-]{36}\}$') {
                            return $_.PSChildName
                        }
                    }
                } catch {}
            }
        }
    } catch {}
    return $null
}

function Get-CrowdStrikeUninstallString {
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
                        if ($p.UninstallString) { return $p.UninstallString }
                    }
                } catch {}
            }
        }
    } catch {}
    return $null
}

function Uninstall-CrowdStrikeSensor {param([Parameter(Mandatory=$true)][string]$Token,[Parameter(Mandatory=$true)][System.Windows.Forms.RichTextBox]$statusTextBox)
    if (-not $Token.Trim()) {Add-Status "Maintenance token is required." $statusTextBox ([System.Drawing.Color]::Red);return}

    # Chọn msiexec 64-bit
    $msi64 = Join-Path $env:WINDIR 'Sysnative\msiexec.exe'
    if (-not (Test-Path $msi64)) {$msi64 = Join-Path $env:WINDIR 'System32\msiexec.exe'}

    # Ghi log để debug (tự động vào %TEMP%)
    $logFile = Join-Path $env:TEMP ("cs_uninstall_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

    $args = "/x $productCode /qn /norestart MAINTENANCE_TOKEN=$Token /L*v `"$logFile`""
    Add-Status "Uninstalling via: $msi64 $args" $statusTextBox ([System.Drawing.Color]::Gray)

    $p = Start-Process -FilePath $msi64 -ArgumentList $args -Wait -PassThru -WindowStyle Hidden

    if ($p.ExitCode -eq 0) {
        Add-Status "Uninstall completed successfully." $statusTextBox ([System.Drawing.Color]::Green)
    } else {
        Add-Status "Uninstall finished with exit code $($p.ExitCode). Log: $logFile" $statusTextBox ([System.Drawing.Color]::Yellow)

        # Fallback nếu 1605: chạy đúng UninstallString từ registry
        if ($p.ExitCode -eq 1605) {
            $u = Get-CrowdStrikeUninstallString
            if ($u) {
                # Đảm bảo dùng /X (gỡ) và chèn token + log
                $u2 = $u -replace '(?i)\s+/I\s+', ' /X '  # đổi /I thành /X nếu có
                if ($u2 -notmatch '(?i)\s+/X\s+') { $u2 = "$u2 /X" }
                if ($u2 -notmatch '(?i)/L\*V') { $u2 = "$u2 /L*v `"$logFile`"" }
                if ($u2 -notmatch '(?i)MAINTENANCE_TOKEN=') { $u2 = "$u2 MAINTENANCE_TOKEN=$Token" }

                Add-Status "Retry via UninstallString: $u2" $statusTextBox ([System.Drawing.Color]::Gray)
                $p2 = Start-Process -FilePath $msi64 -ArgumentList $u2 -Wait -PassThru -WindowStyle Hidden

                if ($p2.ExitCode -eq 0) {
                    Add-Status "Uninstall completed successfully (fallback)." $statusTextBox ([System.Drawing.Color]::Green)
                } else {
                    Add-Status "Fallback exit code: $($p2.ExitCode). Log: $logFile" $statusTextBox ([System.Drawing.Color]::Yellow)
                }
            } else {
                Add-Status "No UninstallString found in registry for fallback." $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
    }

    # Try uninstall via msiexec
    try {
        Add-Status "Resolving CrowdStrike ProductCode..." $statusTextBox ([System.Drawing.Color]::Gray)
        $productCode = Get-CrowdStrikeProductCode
        if (-not $productCode) {Add-Status "Could not find CrowdStrike Windows Sensor in Uninstall registry." $statusTextBox ([System.Drawing.Color]::Red);return}
        Add-Status "ProductCode: $productCode" $statusTextBox ([System.Drawing.Color]::Gray)

        # Cố gắng dừng service trước khi gỡ
        try {$svc = Get-Service -Name csagent -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {Add-Status "Stopping service csagent..." $statusTextBox ([System.Drawing.Color]::Gray)
                Stop-Service -Name csagent -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }
        } catch {}

        $args = "/x $productCode /qn /norestart MAINTENANCE_TOKEN=$Token"
        Add-Status "Uninstalling via msiexec $args" $statusTextBox ([System.Drawing.Color]::Gray)
        $p = Start-Process -FilePath "msiexec.exe" -ArgumentList $args -Wait -PassThru -WindowStyle Hidden

        if ($p.ExitCode -eq 0) {
            Add-Status "Uninstall completed successfully." $statusTextBox ([System.Drawing.Color]::Green)
        } else {Add-Status "Uninstall finished with exit code $($p.ExitCode)." $statusTextBox ([System.Drawing.Color]::Yellow)}

        # Xác nhận
        $svc2 = Get-Service -Name csagent -ErrorAction SilentlyContinue
        if ($null -eq $svc2) {Add-Status "csagent service removed." $statusTextBox ([System.Drawing.Color]::Green)} else {Add-Status "csagent service still present (status: $($svc2.Status))." $statusTextBox ([System.Drawing.Color]::Yellow)}
    } catch {Add-Status ("Uninstall error: " + $_.Exception.Message) $statusTextBox ([System.Drawing.Color]::Red)}
}

function Invoke-CrowdStrikeUninstallDialog {param([Parameter(Mandatory=$true)][System.Windows.Forms.RichTextBox]$statusTextBox)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Uninstall CrowdStrike - Maintenance Token"
    $form.Size = New-Object System.Drawing.Size(420, 200)
    $form.StartPosition = 'CenterParent'
    $form.BackColor = [System.Drawing.Color]::Black
    $form.ForeColor = [System.Drawing.Color]::White
    $form.TopMost = $true

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Enter Maintenance Token:"
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point(15, 20)
    $form.Controls.Add($lbl)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(18, 45)
    $txt.Size = New-Object System.Drawing.Size(360, 24)
    $txt.UseSystemPasswordChar = $true
    $form.Controls.Add($txt)

    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = "Show"
    $chk.AutoSize = $true
    $chk.Location = New-Object System.Drawing.Point(18, 75)
    $chk.Add_CheckedChanged({ $txt.UseSystemPasswordChar = -not $chk.Checked })
    $form.Controls.Add($chk)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Uninstall"
    $btnOk.Location = New-Object System.Drawing.Point(200, 110)
    $btnOk.Size = New-Object System.Drawing.Size(85, 30)
    $btnOk.Add_Click({
        $token = $txt.Text
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
        Uninstall-CrowdStrikeSensor -Token $token -statusTextBox $statusTextBox
    })
    $form.Controls.Add($btnOk)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(293, 110)
    $btnCancel.Size = New-Object System.Drawing.Size(85, 30)
    $btnCancel.Add_Click({ $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $form.Close() })
    $form.Controls.Add($btnCancel)

    $form.KeyPreview = $true
    $form.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $form.Close() } })

    [void]$form.ShowDialog()
}

# Các nút menu
$menuButtons = @(
    @{text = '[1] Run All'; action = { Invoke-RunAllOperations -mainForm $script:form } },
    @{text = '[6] Features'; action = { Invoke-FeaturesDialog } },
    @{text = '[2] Software'; action = { Show-InstallSoftwareDialog } },
    @{text = '[7] Rename'; action = { Invoke-RenameDialog } },
    @{text = '[3] Power'; action = { Invoke-PowerOptionsDialog } },
    @{text = '[8] Password'; action = { Show-SetPasswordForm -currentUser $env:USERNAME } },
    @{text = '[4] Volume'; action = { Invoke-VolumeManagementDialog } },
    @{text = '[9] Domain'; action = { Show-DomainManagementForm } },
    @{text = '[5] Activate'; action = { Invoke-ActivationDialog } },
    @{text = '[10] CrowdStrike'; action = { Invoke-CrowdStrikeDialog } }
)

# Các tham số cho các nút menu
$buttonHeight = 60
$buttonSpacingY = 10
$buttonTop = 80
$buttonLeft = 30
$buttonControls = @()

# Tạo các nút menu
for ($i = 0; $i -lt $menuButtons.Count; $i += 2) {
    # Nút bên trái
    if ($menuButtons[$i].text -eq '[0] CrowStrike') {$btnL = New-DynamicButton -text $menuButtons[$i].text -x $buttonLeft -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i].action -normalColor ([System.Drawing.Color]::FromArgb(255, 140, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(255, 165, 0)) -pressColor ([System.Drawing.Color]::FromArgb(200, 100, 0))}
    else {$btnL = New-DynamicButton -text $menuButtons[$i].text -x $buttonLeft -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i].action}
    $btnL.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $script:form.Controls.Add($btnL)
    $buttonControls += $btnL
    # Nút bên phải
    if ($i + 1 -lt $menuButtons.Count) {
        if ($menuButtons[$i + 1].text -eq '[0] CrowStrike') {$btnR = New-DynamicButton -text $menuButtons[$i + 1].text -x 0 -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i + 1].action -normalColor ([System.Drawing.Color]::FromArgb(255, 140, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(255, 165, 0)) -pressColor ([System.Drawing.Color]::FromArgb(200, 100, 0))}
        else {$btnR = New-DynamicButton -text $menuButtons[$i + 1].text -x 0 -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i + 1].action}
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
$script:form.Add_Resize({ Update-MenuLayout })
Update-MenuLayout

# Add escape handler to close the form
$script:form.KeyPreview = $true
$script:form.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $script:form.Close() } })

# Show the form
$script:form.ShowDialog()