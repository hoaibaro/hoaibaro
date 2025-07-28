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
catch {
}

# HIDE MAIN MENU
function Hide-MainMenu {
    $script:form.Hide()
}

# SHOW MAIN MENU
function Show-MainMenu {
    $script:form.Show()
}

# 
function New-DynamicButton {
    param (
        [string]$text,
        [int]$x,
        [int]$y,
        [int]$width,
        [int]$height,
        [scriptblock]$clickAction,
        [System.Drawing.Color]$normalColor = [System.Drawing.Color]::FromArgb(0, 128, 0),
        [System.Drawing.Color]$hoverColor = [System.Drawing.Color]::FromArgb(0, 180, 0),
        [System.Drawing.Color]$pressColor = [System.Drawing.Color]::FromArgb(0, 100, 0),
        [System.Drawing.Color]$textColor = [System.Drawing.Color]::White,
        [string]$fontName = "Arial",
        [int]$fontSize = 12,
        [System.Drawing.FontStyle]$fontStyle = [System.Drawing.FontStyle]::Bold
    )

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
Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
Add-Type -AssemblyName System.Drawing -ErrorAction Stop

# Global function to add gradient background to any form
function Add-GradientBackground {
    param(
        [System.Windows.Forms.Form]$form,
        [System.Drawing.Color]$topColor = [System.Drawing.Color]::FromArgb(0, 0, 0),
        [System.Drawing.Color]$bottomColor = [System.Drawing.Color]::FromArgb(0, 50, 0)
    )

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

    # Enable double buffering for smoother rendering
    # $form.SetStyle([System.Windows.Forms.ControlStyles]::AllPaintingInWmPaint -bor
    #    [System.Windows.Forms.ControlStyles]::UserPaint -bor
    #    [System.Windows.Forms.ControlStyles]::DoubleBuffer, $true)
    if ($form.PSObject.Properties['DoubleBuffered']) {
        $form.DoubleBuffered = $true
    }
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

# Global function to add title animation - IMPROVED
function Add-TitleAnimation {
    param(
        [System.Windows.Forms.Label]$titleLabel,
        [int]$interval = 500, # Default interval is 500ms
        [System.Drawing.Color]$color1,
        [System.Drawing.Color]$color2
    )

    # Validate input
    if (-not $titleLabel) {
        Write-Warning "TitleLabel is null, cannot add animation"
        return $null
    }

    # Set default colors if not provided
    if (-not $color1 -or $color1 -eq [System.Drawing.Color]::Empty) {
        $color1 = [System.Drawing.Color]::Lime
    }
    if (-not $color2 -or $color2 -eq [System.Drawing.Color]::Empty) {
        $color2 = [System.Drawing.Color]::LimeGreen
    }

    # Create timer for animation
    $titleTimer = New-Object System.Windows.Forms.Timer
    $titleTimer.Interval = $interval

    # Store references in timer's Tag property for proper cleanup
    $titleTimer.Tag = @{
        Label = $titleLabel
        Color1 = $color1
        Color2 = $color2
    }

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
function Add-Status {
    param(
        [string]$message,
        [System.Windows.Forms.RichTextBox]$rtb,
        [System.Drawing.Color]$color = [System.Drawing.Color]::Lime
    )
    if ($rtb.Text -eq "Please select a device type..." -or $rtb.Text -eq "Status messages will appear here...") {
        $rtb.Clear()
    }
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
function Invoke-RunAllOperations {
    param (
        [System.Windows.Forms.Form]$mainForm
    )

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
        # STEP 0: WiFi AUTO-CONNECTION
        Add-Status "STEP 0: Connecting to WiFi network..." $statusTextBox

        $progressBar.Value = 5

        $wifiResult = Invoke-WiFiAutoConnection $statusTextBox
        if ($wifiResult) {
            Add-Status "WiFi connection completed!" $statusTextBox
        }
        else {
            Add-Status "WiFi connection failed, but continuing..." $statusTextBox
        }

        # STEP 1: Device Selection and Software Installation (DONE)
        Add-Status "STEP 1: Selecting Device Type and Installing Software..." $statusTextBox
        $progressBar.Value = 14

        # Create device selection form
        $deviceForm = New-Object System.Windows.Forms.Form
        $deviceForm.Text = "Select Device Type"
        $deviceForm.Size = New-Object System.Drawing.Size(300, 210)
        $deviceForm.StartPosition = "CenterScreen"
        $deviceForm.BackColor = [System.Drawing.Color]::Black
        $deviceForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $deviceForm.MaximizeBox = $false
        $deviceForm.MinimizeBox = $false
        $deviceForm.Add_Paint({
                $graphics = $_.Graphics
                $rect = New-Object System.Drawing.Rectangle(0, 0, $deviceForm.Width, $deviceForm.Height)
                $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                    $rect,
                    [System.Drawing.Color]::FromArgb(0, 0, 0),
                    [System.Drawing.Color]::FromArgb(0, 40, 0),
                    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
                )
                $graphics.FillRectangle($brush, $rect)
                $brush.Dispose()
            })

        # Title label
        $deviceTitleLabel = New-Object System.Windows.Forms.Label
        $deviceTitleLabel.Text = "SELECT DEVICE TYPE"
        $deviceTitleLabel.Location = New-Object System.Drawing.Point(0, 20)
        $deviceTitleLabel.Size = New-Object System.Drawing.Size(290, 30)
        $deviceTitleLabel.ForeColor = [System.Drawing.Color]::Lime
        $deviceTitleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
        $deviceTitleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $deviceTitleLabel.BackColor = [System.Drawing.Color]::Transparent
        $deviceForm.Controls.Add($deviceTitleLabel)

        # Desktop button
        $btnDesktop = New-DynamicButton -text "DESKTOP" -x 10 -y 70 -width 260 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
            $script:selectedDeviceType = "Desktop"
            $deviceForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $deviceForm.Close()
        }
        $deviceForm.Controls.Add($btnDesktop)

        # Laptop button
        $btnLaptop = New-DynamicButton -text "LAPTOP" -x 10 -y 120 -width 260 -height 40 -normalColor ([System.Drawing.Color]::FromArgb(0, 150, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(0, 200, 0)) -pressColor ([System.Drawing.Color]::FromArgb(0, 100, 0)) -clickAction {
            $script:selectedDeviceType = "Laptop"
            $deviceForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $deviceForm.Close()
        }
        $deviceForm.Controls.Add($btnLaptop)

        # Show device selection form and get result
        $result = $deviceForm.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $deviceType = $script:selectedDeviceType
            Add-Status "Selected device type: $deviceType" $statusTextBox
        }
        else {
            Add-Status "Device type selection cancelled. Exiting..." $statusTextBox ([System.Drawing.Color]::Red)
            return
        }

        # Copy software files
        Add-Status "Copying software files..." $statusTextBox
        $copyResult = Copy-SoftwareFiles -deviceType $deviceType $statusTextBox
        if (-not $copyResult) {
            Add-Status "Error copying software files. Exiting..." $statusTextBox ([System.Drawing.Color]::Red)
            return
        }

        # Install software
        Add-Status "Installing software..." $statusTextBox
        Install-Software -deviceType $deviceType $statusTextBox
        Add-Status "All installation completed successfully for $deviceType !!!" $statusTextBox

        # STEP 2: System Configuration and Shortcut Creation
        Add-Status "STEP 2: Configuring System..." $statusTextBox
        $progressBar.Value = 28

        $configResult = Invoke-RenamebyDevice -deviceType $deviceType $statusTextBox
        if ($configResult) {
            Add-Status "STEP 2 completed successfully !!!" $statusTextBox ([System.Drawing.Color]::Cyan)
        }
        else {
            Add-Status "STEP 2 encountered errors. Check logs." $statusTextBox ([System.Drawing.Color]::Red)
        }

        # STEP 3: System Cleanup and Optimization
        Add-Status "STEP 3: Cleaning up system and optimizing performance..." $statusTextBox
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

# STEP 0: WiFi AUTO-CONNECTION FUNCTION (DONE)
function Invoke-WiFiAutoConnection {    
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)

    Add-Status "Checking WiFi connection..." $statusTextBox

    try {
        # Phương pháp 1: Kiểm tra bằng InterfaceType (71 = Wireless80211)
        $wifiAdapter = Get-NetAdapter | Where-Object { $_.InterfaceType -eq 71 }

        if (-not $wifiAdapter) {
            # Phương pháp 2: Kiểm tra bằng PhysicalMediaType
            Add-Status "Method 1 failed, trying alternative detection..." $statusTextBox
            $wifiAdapter = Get-NetAdapter | Where-Object {
                $_.PhysicalMediaType -eq 'Native 802.11' -or
                $_.PhysicalMediaType -eq 'Wireless LAN' -or
                $_.PhysicalMediaType -eq 'Wireless WAN'
            }
        }

        if (-not $wifiAdapter) {
            # Phương pháp 3: Kiểm tra bằng InterfaceDescription
            Add-Status "Method 2 failed, trying description-based detection..." $statusTextBox
            $wifiAdapter = Get-NetAdapter | Where-Object {
                $_.InterfaceDescription -like "*wireless*" -or
                $_.InterfaceDescription -like "*wifi*" -or
                $_.InterfaceDescription -like "*802.11*" -or
                $_.InterfaceDescription -like "*Wi-Fi*" -or
                $_.InterfaceDescription -like "*WLAN*"
            }
        }

        if (-not $wifiAdapter) {
            # Phương pháp 4: Kiểm tra bằng WMI
            Add-Status "Method 3 failed, trying WMI detection..."
            try {
                $wmiWifiAdapters = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object {
                    $_.AdapterType -like "*802.11*" -or
                    $_.Name -like "*wireless*" -or
                    $_.Name -like "*wifi*" -or
                    $_.Name -like "*Wi-Fi*" -or
                    $_.Name -like "*WLAN*" -or
                    $_.Description -like "*wireless*"
                }

                if ($wmiWifiAdapters) {
                    Add-Status "WiFi adapter detected via WMI: $($wmiWifiAdapters[0].Name)" $statusTextBox
                    # Thử lấy lại bằng Get-NetAdapter với tên từ WMI
                    $wifiAdapter = Get-NetAdapter | Where-Object { $_.Name -eq $wmiWifiAdapters[0].NetConnectionID }
                }
            }
            catch {
                Add-Status "WMI detection failed: $_"
            }
        }

        if (-not $wifiAdapter) {
            # Phương pháp 5: Kiểm tra service WLAN AutoConfig
            Add-Status "Method 4 failed, checking WLAN service..." $statusTextBox
            try {
                $wlanService = Get-Service -Name "WlanSvc" -ErrorAction SilentlyContinue
                if ($wlanService -and $wlanService.Status -eq "Running") {
                    Add-Status "WLAN service is running, but no adapter detected through PowerShell" $statusTextBox
                    Add-Status "Attempting direct netsh approach..." $statusTextBox

                    # Thử sử dụng netsh để kiểm tra interfaces
                    $netshResult = netsh wlan show interfaces 2>$null
                    if ($netshResult -and $netshResult -notlike "*There is no wireless interface on the system*") {
                        Add-Status "WiFi interface detected via netsh, proceeding with connection..." $statusTextBox
                        # Tiếp tục với quá trình kết nối mà không cần PowerShell adapter object
                        $useNetshOnly = $true
                    }
                    else {
                        Add-Status "No WiFi interface found via netsh either" $statusTextBox
                        Add-Status "No WiFi adapter found. Skipping WiFi connection..." $statusTextBox
                        return $true
                    }
                }
                else {
                    Add-Status "WLAN service not running. No WiFi capability detected." $statusTextBox
                    Add-Status "Skipping WiFi connection..." $statusTextBox
                    return $true
                }
            }
            catch {
                Add-Status "Service check failed: $_" $statusTextBox
                Add-Status "No WiFi adapter found. Skipping WiFi connection..." $statusTextBox
                return $true
            }
        }

        if ($wifiAdapter -and -not $useNetshOnly) {
            Add-Status "WiFi adapter found: $($wifiAdapter.Name) - $($wifiAdapter.InterfaceDescription)" $statusTextBox
        }

        # Kiểm tra xem đã kết nối WiFi "VietUnion_5.0GHz" chưa
        try {
            $currentConnection = netsh wlan show interfaces | Select-String "SSID" | Select-String "VietUnion_5.0GHz"

            if ($currentConnection) {
                Add-Status "Already connected to 'VietUnion_5.0GHz' WiFi. Skipping..." $statusTextBox
                return $true
            }
        }
        catch {
            Add-Status "Could not check current connection, proceeding with connection attempt..." $statusTextBox
        }

        # Thông tin WiFi
        $SSID = "VietUnion_5.0GHz"
        $Password = "Pay00@17Years$"
        $profileFile = "$env:TEMP\VietUnion_5.0GHz_profile.xml"

        # Tạo hex cho SSID
        $SSIDHEX = ($SSID.ToCharArray() | ForEach-Object { '{0:X}' -f ([int]$_) }) -join ''

        # Tạo XML profile cho WiFi
        $xmlContent = @"
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

        # Ghi XML profile ra file
        try {
            $xmlContent | Out-File -FilePath $profileFile -Encoding UTF8
        }
        catch {
            Add-Status "ERROR: Could not create WiFi profile file: $_" $statusTextBox ([System.Drawing.Color]::Red)
            return $false
        }

        # Thêm profile WiFi
        try {
            $addResult = Start-Process -FilePath "netsh" -ArgumentList "wlan add profile filename=`"$profileFile`"" -Wait -PassThru -WindowStyle Hidden

            if ($addResult.ExitCode -eq 0) {
            }
            else {
                Add-Status "Warning: WiFi profile add returned exit code $($addResult.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        catch {
            Add-Status "ERROR adding WiFi profile: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # Kết nối WiFi
        Add-Status "Connecting to 'VietUnion_5.0GHz' WiFi..." $statusTextBox
        try {
            $connectResult = Start-Process -FilePath "netsh" -ArgumentList "wlan connect name=`"$SSID`"" -Wait -PassThru -WindowStyle Hidden

            if ($connectResult.ExitCode -eq 0) {
                # Đợi một chút để kết nối ổn định
                Add-Status "Waiting for connection to establish..." $statusTextBox
                Start-Sleep -Seconds 5

                # Xác minh kết nối
                try {
                    $verifyConnection = netsh wlan show interfaces | Select-String "SSID" | Select-String "VietUnion_5.0GHz"
                    if ($verifyConnection) {
                    }
                    else {
                        Add-Status "Warning: Could not verify WiFi connection to 'VietUnion_5.0GHz'" $statusTextBox ([System.Drawing.Color]::Yellow)
                        # Kiểm tra xem có kết nối WiFi nào không
                        $anyConnection = netsh wlan show interfaces | Select-String "State" | Select-String "connected"
                        if ($anyConnection) {
                            Add-Status "Device is connected to a different WiFi network" $statusTextBox
                        }
                        else {
                            Add-Status "Device is not connected to any WiFi network" $statusTextBox
                        }
                    }
                }
                catch {
                    Add-Status "Could not verify connection status" $statusTextBox
                }
            }
            else {
                Add-Status "Warning: WiFi connection command returned exit code $($connectResult.ExitCode)" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }
        catch {
            Add-Status "ERROR connecting to WiFi: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # Xóa file profile tạm
        try {
            if (Test-Path $profileFile) {
                Remove-Item -Path $profileFile -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # Ignore cleanup errors
        }

        return $true

    }
    catch {
        Add-Status "ERROR during WiFi connection: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

# STEP 1: Choose Device Type and Rename
function Invoke-RenamebyDevice {
    param (
        [string]$deviceType,
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )
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

        # 
        $renameForm.KeyPreview = $true
        $renameForm.Add_KeyDown({
                param($sender, $e)
                if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                    # ESC 
                    $renameForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
                    $renameForm.Close()
                }
                elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                    # Enter 
                    $okButton.PerformClick()
                }
            })

        # 
        $currentNameLabel = New-Object System.Windows.Forms.Label
        $currentNameLabel.Text = "Current Computer Name: $currentName"
        $currentNameLabel.Location = New-Object System.Drawing.Point(20, 20)
        $currentNameLabel.Size = New-Object System.Drawing.Size(400, 25)
        $currentNameLabel.ForeColor = [System.Drawing.Color]::White
        $currentNameLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
        $currentNameLabel.BackColor = [System.Drawing.Color]::Transparent
        $renameForm.Controls.Add($currentNameLabel)

        # XÃ¡c Ä‘á»‹nh prefix dá»±a trÃªn loáº¡i thiáº¿t bá»‹
        $prefix = ""
        if ($deviceType -eq "Desktop") {
            $prefix = "HOD"
        }
        elseif ($deviceType -eq "Laptop") {
            $prefix = "HOL"
        }

        # 
        $instructionLabel = New-Object System.Windows.Forms.Label
        $instructionLabel.Text = "Enter new name (will be prefixed with $prefix):"
        $instructionLabel.Location = New-Object System.Drawing.Point(20, 60)
        $instructionLabel.Size = New-Object System.Drawing.Size(400, 25)
        $instructionLabel.ForeColor = [System.Drawing.Color]::Lime
        $instructionLabel.Font = New-Object System.Drawing.Font("Arial", 10)
        $instructionLabel.BackColor = [System.Drawing.Color]::Transparent
        $renameForm.Controls.Add($instructionLabel)

        # 
        $nameTextBox = New-Object System.Windows.Forms.RichTextBox
        $nameTextBox.Location = New-Object System.Drawing.Point(20, 90)
        $nameTextBox.Size = New-Object System.Drawing.Size(300, 25)
        $nameTextBox.Font = New-Object System.Drawing.Font("Arial", 10)
        $renameForm.Controls.Add($nameTextBox)

        # 
        $nameTextBox.Add_KeyDown({
                param($sender, $e)
                if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                    $okButton.PerformClick()
                }
            })

        # 
        $previewLabel = New-Object System.Windows.Forms.Label
        $previewLabel.Text = "New name will be: $prefix"
        $previewLabel.Location = New-Object System.Drawing.Point(20, 125)
        $previewLabel.Size = New-Object System.Drawing.Size(400, 25)
        $previewLabel.ForeColor = [System.Drawing.Color]::Yellow
        $previewLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Italic)
        $previewLabel.BackColor = [System.Drawing.Color]::Transparent
        $renameForm.Controls.Add($previewLabel)

        # 
        $nameTextBox.Add_TextChanged({
                $newPreview = $prefix + $nameTextBox.Text.Trim()
                $previewLabel.Text = "New name will be: $newPreview"
            })

        # NÃºt OK
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK (Enter)"
        $okButton.Location = New-Object System.Drawing.Point(220, 160)
        $okButton.Size = New-Object System.Drawing.Size(100, 30)
        $okButton.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 0)
        $okButton.ForeColor = [System.Drawing.Color]::White
        $okButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $okButton.Add_Click({
                $renameForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $renameForm.Close()
            })
        $renameForm.Controls.Add($okButton)

        # NÃºt Cancel
        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Text = "Cancel (ESC)"
        $cancelButton.Location = New-Object System.Drawing.Point(330, 160)
        $cancelButton.Size = New-Object System.Drawing.Size(100, 30)
        $cancelButton.BackColor = [System.Drawing.Color]::FromArgb(150, 0, 0)
        $cancelButton.ForeColor = [System.Drawing.Color]::White
        $cancelButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $cancelButton.Add_Click({
                $renameForm.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
                $renameForm.Close()
            })
        $renameForm.Controls.Add($cancelButton)

        # Äáº·t focus vÃ o TextBox khi form hiá»ƒn thá»‹
        $renameForm.Add_Shown({
                $nameTextBox.Focus()
                $nameTextBox.Select()
            })

        # Hiá»ƒn thá»‹ form vÃ  xá»­ lÃ½ káº¿t quáº£
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

# STEP 3: POWER OPTIONS FUNCTIONS
function Invoke-SystemCleanup {
    param (
        [string]$deviceType,
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )

    try {
        Add-Status "Starting system cleanup and optimization..." $statusTextBox

        # --- 1. System File Cleanup ---
        Invoke-FileCleanup $statusTextBox

        # --- 2. Taskbar Customization ---
        Invoke-TaskbarCustomization $statusTextBox

        # --- 3. Startup Program Management ---
        Invoke-StartupOptimization $statusTextBox

        # --- 4. Timezone Configuration ---
        Invoke-TimezoneConfiguration $statusTextBox

        # --- 5. Power Options Configuration ---
        Invoke-PowerOptionsConfiguration $statusTextBox

        Add-Status "System cleanup and optimization completed." $statusTextBox
        return $true

    }
    catch {
        Add-Status "ERROR during System Cleanup: $_" $statusTextBox ([System.Drawing.Color]::Red)
        return $false
    }
}

function Invoke-FileCleanup {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)

    Add-Status "Cleaning temporary files..." $statusTextBox

    # Temporary files
    $tempPaths = @(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*",
        "$env:USERPROFILE\AppData\Local\Temp\*"
    )

    # 
    $tempPaths | ForEach-Object {
        try {
            Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            Add-Status "Warning: Could not clean $_" $statusTextBox ([System.Drawing.Color]::Yellow)
        }
    }

    # Dá»n dáº¹p Recycle Bin vÃ  Windows Update cache
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

function Invoke-TaskbarCustomization {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)

    Add-Status "Customizing taskbar settings..." $statusTextBox

    try {
        # Detect Windows version
        $osVersion = (Get-CimInstance Win32_OperatingSystem).Caption
        $isWindows11 = $osVersion -like "*Windows 11*"

        if ($isWindows11) {
            Add-Status "Detected Windows 11 - applying specific customizations..." $statusTextBox
        }
        else {
            Add-Status "Detected Windows 10 - applying specific customizations..." $statusTextBox
        }

        # 1. DISABLE/UNPIN MS COPILOT (Windows 11 specific)
        if ($isWindows11) {
            try {
                # Disable Copilot via registry
                $copilotRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                if (-not (Test-Path $copilotRegPath)) {
                    New-Item -Path $copilotRegPath -Force | Out-Null
                }

                # Disable Copilot button on taskbar
                Set-ItemProperty -Path $copilotRegPath -Name "ShowCopilotButton" -Value 0 -Type DWord -ErrorAction SilentlyContinue

                # Disable Copilot via Group Policy equivalent
                $copilotPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
                if (-not (Test-Path $copilotPolicyPath)) {
                    New-Item -Path $copilotPolicyPath -Force -ErrorAction SilentlyContinue | Out-Null
                }
                Set-ItemProperty -Path $copilotPolicyPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -ErrorAction SilentlyContinue

                Add-Status "MS Copilot was disabled." $statusTextBox
            }
            catch {
                Add-Status "Could not disable MS Copilot: $_" $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "MS Copilot not applicable for Windows 10" $statusTextBox
        }

        # 3. DISABLE WIDGETS (Windows 11) / NEWS AND INTERESTS (Windows 10)
        Add-Status "Disabling Widgets/News and Interests..." $statusTextBox
        try {
            $explorerRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

            if ($isWindows11) {
                # Windows 11 - Disable Widgets
                Set-ItemProperty -Path $explorerRegPath -Name "TaskbarDa" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $explorerRegPath -Name "TaskbarWidgets" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                Add-Status "Widgets disabled for Windows 11" $statusTextBox
            }
            else {
                # Windows 10 - Disable News and Interests
                Set-ItemProperty -Path $explorerRegPath -Name "TaskbarDa" -Value 0 -Type DWord -ErrorAction SilentlyContinue

                # Additional registry for News and Interests
                $feedsRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
                if (-not (Test-Path $feedsRegPath)) {
                    New-Item -Path $feedsRegPath -Force | Out-Null
                }
                Set-ItemProperty -Path $feedsRegPath -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -ErrorAction SilentlyContinue

                Add-Status "News and Interests disabled for Windows 10" $statusTextBox
            }
        }
        catch {
            Add-Status "Could not disable Widgets/News and Interests: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # 4. HIDE TASK VIEW BUTTON
        try {
            $explorerRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

            # Hide Task View button (works for both Windows 10 and 11)
            Set-ItemProperty -Path $explorerRegPath -Name "ShowTaskViewButton" -Value 0 -Type DWord -ErrorAction SilentlyContinue

            Add-Status "Task View button was hidden." $statusTextBox
        }
        catch {
            Add-Status "Could not hide Task View button: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # 5. ADDITIONAL TASKBAR CUSTOMIZATIONS
        try {
            $explorerRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

            # Hide People button (Windows 10)
            if (-not $isWindows11) {
                Set-ItemProperty -Path $explorerRegPath -Name "PeopleBand" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                Add-Status "People button was hidden. (Windows 10)" $statusTextBox
            }

            # Hide Meet Now button (Windows 10)
            if (-not $isWindows11) {
                $meetNowRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
                if (-not (Test-Path $meetNowRegPath)) {
                    New-Item -Path $meetNowRegPath -Force | Out-Null
                }
                Set-ItemProperty -Path $meetNowRegPath -Name "HideSCAMeetNow" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                Add-Status "Meet Now was hidden. (Windows 10)" $statusTextBox
            }

            # Windows 11 specific - Hide Chat button
            if ($isWindows11) {
                Set-ItemProperty -Path $explorerRegPath -Name "TaskbarMn" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                Add-Status "Chat button was hidden. (Windows 11)" $statusTextBox
            }

        }
        catch {
            Add-Status "Could not apply additional customizations: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # 6. RESTART EXPLORER TO APPLY CHANGES
        try {
            # Kill explorer process
            Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue

            # Wait a moment
            Start-Sleep -Seconds 2

            # Start explorer again
            Start-Process "explorer.exe"

            Add-Status "Windows Explorer was restarted." $statusTextBox
        }
        catch {
            Add-Status "Could not restart Explorer: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        Add-Status "Taskbar customization completed successfully !!!" $statusTextBox

    }
    catch {
        Add-Status "ERROR during taskbar customization: $_" $statusTextBox ([System.Drawing.Color]::Red)
    }
}

function Invoke-StartupOptimization {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)

    Add-Status "Disabling unnecessary startup programs..." $statusTextBox

    $startupPrograms = @("Skype for Desktop", "Microsoft Co-Pilot", "Microsoft Edge")
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

    $startupPrograms | ForEach-Object {
        try {
            $property = Get-ItemProperty -Path $regPath -Name $_ -ErrorAction SilentlyContinue
            if ($property) {
                Remove-ItemProperty -Path $regPath -Name $_ -ErrorAction SilentlyContinue
                Add-Status "Disabled startup program: $_" $statusTextBox
            }
        }
        catch {
            Add-Status "Warning: Could not disable startup program $_" $statusTextBox ([System.Drawing.Color]::Yellow)
        }
    }
}

function Invoke-TimezoneConfiguration {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)

    Add-Status "Setting time zone and automatically updating time..." $statusTextBox

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
        Add-Status "Set timezone and time automatically completed successfully!" $statusTextBox
    }
    catch {
        Add-Status "Warning: Could not configure timezone settings: $_" $statusTextBox
    }
}

function Invoke-PowerOptionsConfiguration {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)

    Add-Status "Configuring power options to 'Do Nothing'..." $statusTextBox

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
        Add-Status "Power options configured to  'Do Nothing' completed successfully!" $statusTextBox
    }
    catch {
        Add-Status "Warning: Could not configure power options: $_" $statusTextBox ([System.Drawing.Color]::Yellow)
    }
}

function Invoke-AdvancedTaskbarCustomization {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)

    Add-Status "Applying advanced taskbar customizations..."

    try {
        # Unpin Microsoft Store using PowerShell
        Add-Status "Unpinning Microsoft Store using PowerShell method..."

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
            Add-Status "Microsoft Store unpinned via PowerShell method"
        }
        catch {
            Add-Status "PowerShell unpin method failed: $_"
        }

        # Force registry changes
        Add-Status "Forcing registry changes..."

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
            Add-Status "Registry changes applied successfully"

            # Clean up
            Remove-Item -Path $regFile -Force -ErrorAction SilentlyContinue
        }
        catch {
            Add-Status "Could not apply registry changes: $_"
        }

    }
    catch {
        Add-Status "ERROR in advanced taskbar customization: $_"
    }
}

# STEP 4: Windows and Office Activation
function Invoke-ActivateConfiguration {
    param (
        [string]$deviceType,
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )

    try {
        # --- 1. Windows 10 Pro Activation ---
        Invoke-ActivateWindows10Pro $statusTextBox

        # --- 2. Office 2019 Pro Plus Activation ---
        Invoke-ActivateOffice2019 $statusTextBox

        Add-Status "Activations completed successfully!"
        return $true

    }
    catch {
        Add-Status "ERROR during Activation Configuration: $_"
        return $false
    }
}

# STEP 7: User Password Management Functions
function Invoke-UserPasswordManagement {
    param (
        [string]$deviceType,
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )

    try {
        Add-Status "Starting user password management..."

        # --- 1. Get Current User Information ---
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
        Add-Status "Current user: $currentUser"

        # --- 2. Show Password Management Dialog ---
        $passwordResult = Invoke-SetPasswordDialog -currentUser $currentUser -statusTextBox $statusTextBox -showMenuAfter $false

        if ($passwordResult) {
            Add-Status "User password management completed successfully!"
        }
        else {
            Add-Status "User password management was cancelled or failed."
        }
        return $true
    }
    catch {
        Add-Status "ERROR during User Password Management: $_"
        return $false
    }
}

# [2] Install Software Functions
function Copy-SoftwareFiles {
    param ([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox)

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
            $forceScoutSource = "D:\SOFTWARE\PAYOO\SC--wKgXWicTb0XhUSNethaFN0vkhji53AY5mektJ7O_RSOdc8bEUVIEAAH_OewU.exe"
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

function Install-Software {
    param ([string]$deviceType, [System.Windows.Forms.RichTextBox]$statusTextBox)

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
            Add-Status "OneDrive: Not installed. Skipping..." $statusTextBox
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
            # Continue checking other paths
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

function Uninstall-OneDriveComplete {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)
    
    try {
        # First, verify OneDrive is actually installed
        if (-not (Test-OneDriveInstalled)) {
            Add-Status "OneDrive: Not found in system. Skipping..." $statusTextBox
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
                # Silent process termination
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
                Add-Status "OneDrive has been uninstalled." $statusTextBox
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
                                    Add-Status "OneDrive has been uninstalled." $statusTextBox
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

function Show-InstallSoftwareDialog {
    Hide-MainMenu
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
    $btnDesktop = New-DynamicButton -text "DESKTOP" -x 10 -y 50 -width 200 -height 50 -clickAction {
        Add-Status "STEP 1: Copying required files for Desktop..."
        $copyResult = Copy-SoftwareFiles -deviceType "Desktop" $statusTextBox

        if ($copyResult) {
            Add-Status "STEP 2: Installing software for Desktop..." $statusTextBox
            $installResult = Install-Software -deviceType "Desktop" $statusTextBox

            if ($installResult) {
                Add-Status "All software installation completed successfully!" $statusTextBox
            }
            else {
                Add-Status "Warning: Some installations may have failed." $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "Error: Failed to copy required files. Installation aborted." $statusTextBox ([System.Drawing.Color]::Red)
        }
    }
    $deviceTypeForm.Controls.Add($btnDesktop)

    # Laptop button
    $btnLaptop = New-DynamicButton -text "LAPTOP" -x 260 -y 50 -width 200 -height 50 -clickAction {
        Add-Status "STEP 1: Copying required files for Laptop..."
        $copyResult = Copy-SoftwareFiles -deviceType "Laptop" $statusTextBox

        if ($copyResult) {
            Add-Status "STEP 2: Installing software for Laptop..."
            $installResult = Install-Software -deviceType "Laptop" $statusTextBox

            if ($installResult) {
                Add-Status "All software installation completed successfully!" $statusTextBox
            }
            else {
                Add-Status "Warning: Some installations may have failed." $statusTextBox ([System.Drawing.Color]::Red)
            }
        }
        else {
            Add-Status "Error: Failed to copy required files. Installation aborted." $statusTextBox ([System.Drawing.Color]::Red)
        }
    }
    $deviceTypeForm.Controls.Add($btnLaptop)

    # Add KeyDown event handler for Esc key
    $deviceTypeForm.Add_KeyDown({
            param($sender, $e)
            if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                $deviceTypeForm.Close()
            }
        })

    # Enable key events
    $deviceTypeForm.KeyPreview = $true

    # When form closes, show main menu
    $deviceTypeForm.Add_FormClosed({
            Show-MainMenu
        })

    # Show the dialog
    $deviceTypeForm.ShowDialog()
}

# [3] Power Options Functions
function Invoke-SetTimezonePower {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)

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

function Invoke-FirewallOn {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)

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

function Invoke-FirewallOff {
    param([System.Windows.Forms.RichTextBox]$statusTextBox)

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

    Add-TitleAnimation -label $titleLabel

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

    # Cleanup timer when form is closed
    $powerForm.Add_FormClosed({
            Show-MainMenu
        })

    # Show the form
    $powerForm.ShowDialog()
}

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
    $script:customSizeTextBox.Text = "112640"  # Default to 100GB in MB
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
    # Determine partition size based on selected radio button
    $sizeMB = 0

    if ($script:radio100GB.Checked) {
        $sizeMB = 112640
    }
    elseif ($script:radio200GB.Checked) {
        $sizeMB = 214748
    }
    elseif ($script:radio500GB.Checked) {
        $sizeMB = 524288
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
            
            # Kiểm tra trùng với source
            if ($script:extendSourceDriveTextBox -and $currentText -eq $script:extendSourceDriveTextBox.Text.Trim()) {
                Add-Status "⚠️ Target không thể trùng với Source Drive!" $statusTextBox ([System.Drawing.Color]::Yellow)
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
            $keyResult = & cscript //nologo "$officePath" /inpkey:Q2NKY-J42YJ-X2KVK-9Q9PT-MKP63 2>&1
        }
        catch {
            Add-Status "Error installing product key: $_" $statusTextBox ([System.Drawing.Color]::Red)
        }

        # Wait a moment for key installation to complete
        Start-Sleep -Seconds 2

        # Activate Office with license key
        Add-Status "Activating Office 2019 Pro Plus with license key..." $statusTextBox
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
        Add-Status "Checking final activation status..." $statusTextBox
        try {
            Start-Sleep -Seconds 3
            $finalStatus = & cscript //nologo "$officePath" /dstatus 2>&1
            $isFinallyActivated = ($finalStatus -match "LICENSE STATUS:.*LICENSED") -or
            ($finalStatus -match "---LICENSED---") -or
            ($finalStatus -match "LICENSED")

            if ($isFinallyActivated) {
                Add-Status "SUCCESS: Office 2019 Pro Plus has been activated!" $statusTextBox
            }
            else {
                Add-Status "Activation may not have completed successfully. Please check manually." $statusTextBox
            }
        }
        catch {
            Add-Status "Could not verify final activation status: $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
        }
    }
    catch {
        Add-Status "CRITICAL ERROR in Office activation: $_" $statusTextBox ([System.Drawing.Color]::Red)
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

    # When the form is closed, show the main menu again
    $activateForm.Add_FormClosed({
            Show-MainMenu
        })

    # Show the form
    $activateForm.ShowDialog()
}

# [6] Features Functions
function Invoke-WindowsFeaturesConfiguration {
    param (
        [string]$deviceType,
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )

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

function Invoke-FeaturesDialog {
    Hide-MainMenu

    # Create features configuration form
    $featuresForm = New-Object System.Windows.Forms.Form
    $featuresForm.Text = "Windows Features Configuration"
    $featuresForm.Size = New-Object System.Drawing.Size(485, 390)
    $featuresForm.StartPosition = "CenterScreen"
    $featuresForm.BackColor = [System.Drawing.Color]::Black
    $featuresForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $featuresForm.MaximizeBox = $false
    $featuresForm.MinimizeBox = $false

    Add-GradientBackground -form $featuresForm
    # Title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "WINDOWS FEATURES CONFIGURATION"
    $titleLabel.Location = New-Object System.Drawing.Point(0, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(470, 35)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
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

    # Add KeyDown event handler for Esc key
    $featuresForm.Add_KeyDown({
            param($sender, $e)
            if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
                $featuresForm.Close()
            }
        })

    # Enable key events
    $featuresForm.AcceptButton = $startButton
    $featuresForm.CancelButton = $closeButton

    # When form closes, show main menu
    $featuresForm.Add_FormClosed({
            Show-MainMenu
        })

    # Show the dialog
    $featuresForm.ShowDialog()
}

function Invoke-EnableWindowsFeatures {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)
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
            # Kiểm tra trạng thái hiện tại của feature bằng PowerShell cmdlet
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

function Invoke-DisableWindowsFeatures {
    param ([System.Windows.Forms.RichTextBox]$statusTextBox)
    # Lấy phiên bản hệ điều hành
    $osVersion = (Get-CimInstance Win32_OperatingSystem).Caption

    # Danh sách các features cần disable
    $featuresToDisable = @(
        @{
            Name        = "Internet-Explorer-Optional-amd64"
            DisplayName = "IExplorer 11"
            Command     = "dism /online /disable-feature /featurename:Internet-Explorer-Optional-amd64 /norestart"
            SupportedOS = "Windows 10"
        }
    )

    foreach ($feature in $featuresToDisable) {
        # Kiểm tra xem tính năng có hỗ trợ trên phiên bản hệ điều hành hiện tại không
        if ($feature.SupportedOS -and -not ($osVersion -like "*$($feature.SupportedOS)*")) {
            Add-Status "$($feature.DisplayName): Not apply on $osVersion." $statusTextBox
            continue
        }
        try {
            # Kiểm tra trạng thái hiện tại của feature
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
function Invoke-RenameDialog {
    Hide-MainMenu
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
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
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
    $deviceGroupBox.ForeColor = [System.Drawing.Color]::Lime
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

# Helper function to detect Windows version
function Get-WindowsVersion {
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $version = $osInfo.Version
        $caption = $osInfo.Caption

        $isWindows11 = $caption -like "*Windows 11*" -or
                      ($version -like "10.0.22*") -or
                      ([System.Environment]::OSVersion.Version.Build -ge 22000)

        return @{
            IsWindows11 = $isWindows11
            Version = $version
            Caption = $caption
            Build = [System.Environment]::OSVersion.Version.Build
        }
    }
    catch {
        # Fallback detection
        $build = [System.Environment]::OSVersion.Version.Build
        return @{
            IsWindows11 = $build -ge 22000
            Version = [System.Environment]::OSVersion.Version.ToString()
            Caption = "Unknown"
            Build = $build
        }
    }
}

function Show-SetPasswordForm {
    param(
        [string]$currentUser,
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )

    # Set Password Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Password"
    $form.Size = New-Object System.Drawing.Size(400, 270)
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
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
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

    # Current user label
    $currentUserLabel = New-Object System.Windows.Forms.Label
    $currentUserLabel.Text = $currentUser
    $currentUserLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $currentUserLabel.ForeColor = [System.Drawing.Color]::WhiteSmoke
    $currentUserLabel.BackColor = [System.Drawing.Color]::Transparent
    $currentUserLabel.AutoSize = $true
    $currentUserLabel.Location = New-Object System.Drawing.Point(150, 70)
    $form.Controls.Add($currentUserLabel)

    # Password label
    $passwordLabel = New-Object System.Windows.Forms.Label
    $passwordLabel.Text = "New Password:"
    $passwordLabel.Font = New-Object System.Drawing.Font("Arial", 12)
    $passwordLabel.ForeColor = [System.Drawing.Color]::White
    $passwordLabel.BackColor = [System.Drawing.Color]::Transparent
    $passwordLabel.Size = New-Object System.Drawing.Size(130, 30)
    $passwordLabel.Location = New-Object System.Drawing.Point(10, 110)
    $form.Controls.Add($passwordLabel)

    # Password textbox
    $passwordTextBox = New-Object System.Windows.Forms.TextBox
    $passwordTextBox.Font = New-Object System.Drawing.Font("Arial", 12)
    $passwordTextBox.Size = New-Object System.Drawing.Size(160, 30)
    $passwordTextBox.Location = New-Object System.Drawing.Point(150, 105)
    $passwordTextBox.BackColor = [System.Drawing.Color]::Black
    $passwordTextBox.ForeColor = [System.Drawing.Color]::Lime
    $passwordTextBox.UseSystemPasswordChar = $false
    $form.Controls.Add($passwordTextBox)

    # Show Password checkbox
    $showPasswordCheckBox = New-Object System.Windows.Forms.CheckBox
    $showPasswordCheckBox.Text = "Show"
    $showPasswordCheckBox.Location = New-Object System.Drawing.Point (320, 110)
    $showPasswordCheckBox.Size = New-Object System.Drawing.Size(80, 20)
    $showPasswordCheckBox.ForeColor = [System.Drawing.Color]::White
    $showPasswordCheckBox.Font = New-Object System.Drawing.Font("Arial", 9)
    $showPasswordCheckBox.BackColor = [System.Drawing.Color]::Transparent
    $showPasswordCheckBox.Checked = $true
    $showPasswordCheckBox.Add_CheckedChanged({
            $passwordTextBox.UseSystemPasswordChar = -not $showPasswordCheckBox.Checked
        })
    $form.Controls.Add($showPasswordCheckBox)

    # Info label for empty password
    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Text = "Leave the password field empty to set a blank password."
    $infoLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $infoLabel.ForeColor = [System.Drawing.Color]::Red
    $infoLabel.BackColor = [System.Drawing.Color]::Transparent
    $infoLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $infoLabel.Size = New-Object System.Drawing.Size(390, 30)
    $infoLabel.Location = New-Object System.Drawing.Point(0, 140)
    $form.Controls.Add($infoLabel)

    # Windows version info label
    try {
        $winVersion = Get-WindowsVersion
        $versionText = if ($winVersion.IsWindows11) { "Windows 11" } else { "Windows 10" }
        $versionLabel = New-Object System.Windows.Forms.Label
        $versionLabel.Text = "$versionText (Build: $($winVersion.Build))"
        $versionLabel.Font = New-Object System.Drawing.Font("Arial", 8)
        $versionLabel.ForeColor = [System.Drawing.Color]::Gray
        $versionLabel.BackColor = [System.Drawing.Color]::Transparent
        $versionLabel.TextAlign = [System.Drawing.ContentAlignment]::BottomRight
        $versionLabel.Size = New-Object System.Drawing.Size(200, 15)
        $versionLabel.Location = New-Object System.Drawing.Point(190, 250)
        $form.Controls.Add($versionLabel)
    }
    catch {
        # Ignore version detection errors
    }

    # Thêm biến lưu kết quả
    $dialogResult = @{ Action = ""; Password = "" }

    # Set Password button
    $setButton = New-Object System.Windows.Forms.Button
    $setButton.Text = "Set"
    $setButton.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $setButton.ForeColor = [System.Drawing.Color]::White
    $setButton.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 0)
    $setButton.Size = New-Object System.Drawing.Size(180, 40)
    $setButton.Location = New-Object System.Drawing.Point(10, 180)
    $setButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $setButton.Add_Click({
            $dialogResult.Action = "set"
            $dialogResult.Password = $passwordTextBox.Text
            $form.Close()
        })
    $form.Controls.Add($setButton)

    # Cancel button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $cancelButton.ForeColor = [System.Drawing.Color]::White
    $cancelButton.BackColor = [System.Drawing.Color]::FromArgb(150, 0, 0)
    $cancelButton.Size = New-Object System.Drawing.Size(180, 40)
    $cancelButton.Location = New-Object System.Drawing.Point(195, 180)
    $cancelButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cancelButton.Add_Click({
            $dialogResult.Action = "cancel"
            $form.Close()
        })
    $form.Controls.Add($cancelButton)

    # Set Accept/Cancel button for Enter/Esc
    $form.AcceptButton = $setButton
    $form.CancelButton = $cancelButton

    # Focus on password textbox when form shows
    $form.Add_Shown({
            $passwordTextBox.Focus()
        })

    # Show the form
    $form.ShowDialog()
    return $dialogResult
}

function Set-UserPassword {
    param(
        [string]$user,
        [string]$password
    )
    try {
        # Get Windows version info
        $winVersion = Get-WindowsVersion

        # Check if running as administrator
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

        if (-not $isAdmin) {
            throw "This operation requires administrative privileges. Please run as administrator."
        }

        # Validate user exists
        try {
            Get-LocalUser -Name $user -ErrorAction Stop | Out-Null
        }
        catch {
            throw "User '$user' does not exist on this system."
        }

        # Enhanced Windows 11 compatible password setting logic
        if ($winVersion.IsWindows11) {
            # Windows 11 - Multiple approaches for better compatibility
            if ([string]::IsNullOrEmpty($password)) {
                # Method 1: Try Set-LocalUser with empty password
                try {
                    $securePassword = ConvertTo-SecureString "" -AsPlainText -Force
                    Set-LocalUser -Name $user -Password $securePassword -ErrorAction Stop
                    return $true
                }
                catch {
                    Write-Warning "Set-LocalUser failed: $($_.Exception.Message)"
                }

                # Method 2: Try WMI approach for Windows 11
                try {
                    $userAccount = Get-WmiObject -Class Win32_UserAccount -Filter "Name='$user' AND LocalAccount=True" -ErrorAction Stop
                    if ($userAccount) {
                        $userAccount.SetPassword("")
                        return $true
                    }
                }
                catch {
                    Write-Warning "WMI approach failed: $($_.Exception.Message)"
                }

                # Method 3: Enhanced net user with UAC handling
                try {
                    $escapedUser = $user -replace '"', '""'
                    $arguments = "/c net user `"$escapedUser`" """""
                    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                    $processInfo.FileName = "cmd.exe"
                    $processInfo.Arguments = $arguments
                    $processInfo.UseShellExecute = $true
                    $processInfo.Verb = "runas"  # Force UAC elevation
                    $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

                    $process = [System.Diagnostics.Process]::Start($processInfo)
                    $process.WaitForExit(10000)  # 10 second timeout
                    return $process.ExitCode -eq 0
                }
                catch {
                    Write-Warning "Enhanced net user failed: $($_.Exception.Message)"
                }
            }
            else {
                # Set new password - Windows 11
                # Method 1: Try Set-LocalUser
                try {
                    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
                    Set-LocalUser -Name $user -Password $securePassword -ErrorAction Stop
                    return $true
                }
                catch {
                    Write-Warning "Set-LocalUser failed: $($_.Exception.Message)"
                }

                # Method 2: Try WMI approach
                try {
                    $userAccount = Get-WmiObject -Class Win32_UserAccount -Filter "Name='$user' AND LocalAccount=True" -ErrorAction Stop
                    if ($userAccount) {
                        $userAccount.SetPassword($password)
                        return $true
                    }
                }
                catch {
                    Write-Warning "WMI approach failed: $($_.Exception.Message)"
                }

                # Method 3: Enhanced net user with UAC handling
                try {
                    $escapedUser = $user -replace '"', '""'
                    $escapedPassword = $password -replace '"', '""'
                    $arguments = "/c net user `"$escapedUser`" `"$escapedPassword`""
                    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
                    $processInfo.FileName = "cmd.exe"
                    $processInfo.Arguments = $arguments
                    $processInfo.UseShellExecute = $true
                    $processInfo.Verb = "runas"  # Force UAC elevation
                    $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

                    $process = [System.Diagnostics.Process]::Start($processInfo)
                    $process.WaitForExit(10000)  # 10 second timeout
                    return $process.ExitCode -eq 0
                }
                catch {
                    Write-Warning "Enhanced net user failed: $($_.Exception.Message)"
                }
            }

            # If all Windows 11 methods fail, throw error
            throw "All Windows 11 password setting methods failed. Please ensure you have administrative privileges and UAC is properly configured."
        }
        else {
            # Windows 10 - use traditional approach with enhancements
            try {
                # Method 1: Try Set-LocalUser first (available in Windows 10 1607+)
                if ([string]::IsNullOrEmpty($password)) {
                    $securePassword = ConvertTo-SecureString "" -AsPlainText -Force
                }
                else {
                    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
                }
                Set-LocalUser -Name $user -Password $securePassword -ErrorAction Stop
                return $true
            }
            catch {
                # Method 2: Fallback to net user command
                if ([string]::IsNullOrEmpty($password)) {
                    $command = "net user `"$user`" """""
                }
                else {
                    $command = "net user `"$user`" `"$password`""
                }
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -NoNewWindow -Wait -PassThru
                return $process.ExitCode -eq 0
            }
        }
    }
    catch {
        Write-Error "Error setting password: $_"
        return $false
    }
}

function Remove-UserPassword {
    param(
        [string]$user
    )
    # This function is now redundant as Set-UserPassword handles empty passwords
    # Just call Set-UserPassword with empty password
    return Set-UserPassword -user $user -password ""
}

function Invoke-SetPasswordDialog {
    param(
        [string]$currentUser,
        [System.Windows.Forms.RichTextBox]$statusTextBox,
        [bool]$showMenuAfter = $true
    )

    try {
        $result = Show-SetPasswordForm -currentUser $currentUser -statusTextBox $statusTextBox
        Hide-MainMenu

        if ($result.Action -eq "set") {
            try {
                $success = Set-UserPassword -user $currentUser -password $result.Password
                if ($success) {
                    if ([string]::IsNullOrEmpty($result.Password)) {
                        [System.Windows.Forms.MessageBox]::Show("Password has been removed. User '$currentUser' can now log in without a password.", "Password Removed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                        if ($statusTextBox) {
                            Add-Status "Password removed successfully for user: $currentUser" $statusTextBox ([System.Drawing.Color]::Lime)
                        }
                    }
                    else {
                        [System.Windows.Forms.MessageBox]::Show("Password has been changed successfully.", "Password Change", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                        if ($statusTextBox) {
                            Add-Status "Password changed successfully for user: $currentUser" $statusTextBox ([System.Drawing.Color]::Lime)
                        }
                    }
                }
                else {
                    throw "Password operation failed"
                }
            }
            catch {
                # Enhanced error message for Windows 11 compatibility
                $winVersion = Get-WindowsVersion
                $versionText = if ($winVersion.IsWindows11) { "Windows 11" } else { "Windows 10" }

                $errorMessage = "Error setting password: $($_.Exception.Message)`n`n"
                $errorMessage += "System: $versionText (Build: $($winVersion.Build))`n`n"
                $errorMessage += "Troubleshooting steps:`n"
                $errorMessage += "1. Ensure you are running as Administrator`n"
                $errorMessage += "2. Check UAC (User Account Control) settings`n"

                if ($winVersion.IsWindows11) {
                    $errorMessage += "3. For Windows 11: Try running PowerShell as Administrator`n"
                    $errorMessage += "4. Check Windows Security policies`n"
                    $errorMessage += "5. Verify Local Security Policy settings`n"
                }
                else {
                    $errorMessage += "3. For Windows 10: Standard administrative privileges should work`n"
                }

                [System.Windows.Forms.MessageBox]::Show($errorMessage, "Password Setting Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                if ($statusTextBox) {
                    Add-Status "Failed to set password for user: $currentUser - $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
        }
        elseif ($result.Action -eq "remove") {
            try {
                $success = Remove-UserPassword -user $currentUser
                if ($success) {
                    [System.Windows.Forms.MessageBox]::Show("Password has been removed. User '$currentUser' can now log in without a password.", "Password Removed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                    if ($statusTextBox) {
                        Add-Status "Password removed successfully for user: $currentUser" $statusTextBox ([System.Drawing.Color]::Lime)
                    }
                }
                else {
                    throw "Password removal failed"
                }
            }
            catch {
                # Enhanced error message for Windows 11 compatibility
                $winVersion = Get-WindowsVersion
                $versionText = if ($winVersion.IsWindows11) { "Windows 11" } else { "Windows 10" }

                $errorMessage = "Error removing password: $($_.Exception.Message)`n`n"
                $errorMessage += "System: $versionText (Build: $($winVersion.Build))`n`n"
                $errorMessage += "Troubleshooting steps:`n"
                $errorMessage += "1. Ensure you are running as Administrator`n"
                $errorMessage += "2. Check UAC (User Account Control) settings`n"

                if ($winVersion.IsWindows11) {
                    $errorMessage += "3. For Windows 11: Try running PowerShell as Administrator`n"
                    $errorMessage += "4. Check Windows Security policies`n"
                    $errorMessage += "5. Verify Local Security Policy settings`n"
                }
                else {
                    $errorMessage += "3. For Windows 10: Standard administrative privileges should work`n"
                }

                [System.Windows.Forms.MessageBox]::Show($errorMessage, "Password Removal Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                if ($statusTextBox) {
                    Add-Status "Failed to remove password for user: $currentUser - $($_.Exception.Message)" $statusTextBox ([System.Drawing.Color]::Red)
                }
            }
        }
        elseif ($result.Action -eq "cancel") {
            if ($statusTextBox) {
                Add-Status "Password operation cancelled by user" $statusTextBox ([System.Drawing.Color]::Yellow)
            }
        }

        return $result.Action -ne "cancel"
    }
    catch {
        $errorMessage = "Unexpected error in password dialog: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show($errorMessage, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        if ($statusTextBox) {
            Add-Status $errorMessage $statusTextBox ([System.Drawing.Color]::Red)
        }
        return $false
    }
    if ($showMenuAfter) { Show-MainMenu }
}

# [9] Domain Management Functions
$script:DomainConfig = @{
    FormWidth         = 500
    FormHeight        = 450
    FormHeightMinimal = 380
    ButtonY           = 350
    ButtonYMinimal    = 280
    ControlSpacing    = 40
    DefaultWorkgroup  = "WORKGROUP"
}

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
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$FontSize = 12,
        [System.Drawing.FontStyle]$FontStyle = [System.Drawing.FontStyle]::Regular
    )

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Font = New-Object System.Drawing.Font("Arial", $FontSize, $FontStyle)
    $label.ForeColor = [System.Drawing.Color]::White
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.Location = New-Object System.Drawing.Point($X, $Y)

    return $label
}

function New-DomainManagementTextBox {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [bool]$IsPassword = $false,
        [string]$DefaultText = ""
    )

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Font = New-Object System.Drawing.Font("Arial", 12)
    $textBox.Size = New-Object System.Drawing.Size($Width, $Height)
    $textBox.Location = New-Object System.Drawing.Point($X, $Y)
    $textBox.BackColor = [System.Drawing.Color]::White
    $textBox.ForeColor = [System.Drawing.Color]::Black
    $textBox.Text = $DefaultText

    if ($IsPassword) {
        $textBox.UseSystemPasswordChar = $true
    }

    return $textBox
}

function New-DomainManagementRadioButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [bool]$IsChecked = $false,
        [bool]$IsEnabled = $true
    )

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
    param(
        [hashtable]$FormControls,
        [string]$OperationType
    )

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

function Test-DomainJoinInputs {
    param(
        [string]$DomainName,
        [string]$Username,
        [string]$Password
    )

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

function Test-WorkgroupInputs {
    param(
        [string]$WorkgroupName
    )

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
    param(
        [string]$Command,
        [string]$OperationType
    )

    try {
        # Create process start info for elevated execution
        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName = "powershell.exe"
        $processStartInfo.Arguments = "-Command Start-Process powershell.exe -ArgumentList '-Command $Command' -Verb RunAs"
        $processStartInfo.UseShellExecute = $true
        $processStartInfo.Verb = "runas"

        # Start the elevated process
        $process = [System.Diagnostics.Process]::Start($processStartInfo)

        if ($null -eq $process) {
            throw "Failed to start elevated process"
        }

        # Show appropriate success message
        $successMessages = @{
            'DomainJoin'    = "Domain join command has been initiated. If prompted, please allow the elevation request. Your computer will restart to apply the changes."
            'WorkgroupJoin' = "Workgroup join command has been initiated. If prompted, please allow the elevation request. Your computer will restart to apply the changes."
        }

        $message = $successMessages[$OperationType]
        if ([string]::IsNullOrEmpty($message)) {
            $message = "Command has been initiated. Your computer will restart to apply the changes."
        }

        [System.Windows.Forms.MessageBox]::Show(
            $message,
            $OperationType,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        return $true
    }
    catch {
        Write-Error "Failed to execute elevated domain command: $_"
        [System.Windows.Forms.MessageBox]::Show(
            "Error processing $OperationType operation: $_`n`nNote: This operation requires administrative privileges.",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
}

function Invoke-DomainJoinOperation {
    param(
        [string]$DomainName,
        [string]$Username,
        [string]$Password
    )

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

    # Escape special characters in password for command line
    $escapedPassword = $Password -replace "'", "''"

    # Build domain join command
    $command = "Add-Computer -DomainName '$DomainName' -Credential (New-Object System.Management.Automation.PSCredential ('$Username', (ConvertTo-SecureString '$escapedPassword' -AsPlainText -Force))) -Restart -Force"

    return Invoke-ElevatedDomainCommand -Command $command -OperationType "DomainJoin"
}

function Invoke-WorkgroupJoinOperation {
    param(
        [string]$WorkgroupName
    )

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
    param(
        [string]$deviceType,
        [System.Windows.Forms.RichTextBox]$statusTextBox
    )

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
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
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
    $joinForm.Controls.Add($currentNameBoldLabel)

    # Current domain/workgroup name label
    if (-not $computerInfo.IsPartOfDomain -or $computerInfo.Domain -eq $computerInfo.ComputerName) {
        $domainDisplay = "$($computerInfo.Domain)"
    }
    else {
        $domainDisplay = $computerInfo.Domain
    }
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
    $radioDomain.Add_CheckedChanged({
            if ($radioDomain.Checked) {
                Set-DomainFormLayout -FormControls $formControls -OperationType 'Domain'
            }
        })

    $radioWorkgroup.Add_CheckedChanged({
            if ($radioWorkgroup.Checked) {
                Set-DomainFormLayout -FormControls $formControls -OperationType 'Workgroup'
            }
        })

    # Join button click handler
    $joinButton.Add_Click({
            $name = $nameTextBox.Text.Trim()
            $success = $false

            try {
                if ($radioDomain.Checked) {
                    $success = Invoke-DomainJoinOperation -DomainName $name -Username $usernameTextBox.Text.Trim() -Password $passwordTextBox.Text
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
    $joinForm.Add_FormClosed({
            Show-MainMenu
        })

    # Show the form
    $joinForm.ShowDialog()
}

# Các nút menu
$menuButtons = @(
    @{text = '[1] Run All'; action = { Invoke-RunAllOperations -mainForm $script:form } },
    @{text = '[6] Features'; action = { Invoke-FeaturesDialog } },
    @{text = '[2] Software'; action = { Show-InstallSoftwareDialog } },
    @{text = '[7] Rename'; action = { Invoke-RenameDialog } },
    @{text = '[3] Power'; action = { Invoke-PowerOptionsDialog } },
    @{text = '[8] Password'; action = {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
        Invoke-SetPasswordDialog -currentUser $currentUser -statusTextBox $null -showMenuAfter $true
    } },
    @{text = '[4] Volume'; action = { Invoke-VolumeManagementDialog } },
    @{text = '[9] Domain'; action = { Show-DomainManagementForm } },
    @{text = '[5] Activate'; action = { Invoke-ActivationDialog } },
    @{text = '[0] Exit'; action = { $script:form.Close() } }
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
    if ($menuButtons[$i].text -eq '[0] Exit') {
        $btnL = New-DynamicButton -text $menuButtons[$i].text -x $buttonLeft -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i].action -normalColor ([System.Drawing.Color]::FromArgb(200, 0, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(255, 50, 50)) -pressColor ([System.Drawing.Color]::FromArgb(150, 0, 0))
    }
    else {
        $btnL = New-DynamicButton -text $menuButtons[$i].text -x $buttonLeft -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i].action
    }
    # if ($menuButtons[$i].text -eq '[3] Power' -or $menuButtons[$i].text -eq '[2] Software' -or $menuButtons[$i].text -eq '[5] Activate' -or $menuButtons[$i].text -eq '[6] Features') {
    #     $btnL.Visible = $false
    # }
    $btnL.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $script:form.Controls.Add($btnL)
    $buttonControls += $btnL
    # Nút bên phải
    if ($i + 1 -lt $menuButtons.Count) {
        if ($menuButtons[$i + 1].text -eq '[0] Exit') {
            $btnR = New-DynamicButton -text $menuButtons[$i + 1].text -x 0 -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i + 1].action -normalColor ([System.Drawing.Color]::FromArgb(200, 0, 0)) -hoverColor ([System.Drawing.Color]::FromArgb(255, 50, 50)) -pressColor ([System.Drawing.Color]::FromArgb(150, 0, 0))
        }
        else {
            $btnR = New-DynamicButton -text $menuButtons[$i + 1].text -x 0 -y ($buttonTop + [math]::Floor($i / 2) * ($buttonHeight + $buttonSpacingY)) -width 1 -height $buttonHeight -clickAction $menuButtons[$i + 1].action
        }
        $btnR.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
        # if ($menuButtons[$i + 1].text -eq '[6] Features' -or $menuButtons[$i + 1].text -eq '[7] Rename' -or $menuButtons[$i + 1].text -eq '[8] Password' -or $menuButtons[$i + 1].text -eq '[9] Domain') {
        #     $btnR.Visible = $false
        # }
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

# Add KeyDown event handler for Esc key
$script:form.Add_KeyDown({
        param($sender, $e)
        if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
            $script:form.Close()
        }
    })

# Enable key events
$script:form.KeyPreview = $true

# Show the form
$script:form.ShowDialog()