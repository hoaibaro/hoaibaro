# HIDE MAIN MENU
function Hide-MainMenu {
    param([System.Windows.Forms.Form]$mainForm)
    if ($mainForm) { $mainForm.Hide() }
}

# SHOW MAIN MENU
function Show-MainMenu {
    param([System.Windows.Forms.Form]$mainForm)
    if ($mainForm) { $mainForm.Show() }
}

# DYNAMIC BUTTON FACTORY
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

# GRADIENT BACKGROUND FOR FORMS
function Add-GradientBackground {
    param([System.Windows.Forms.Form]$form, [System.Drawing.Color]$topColor = [System.Drawing.Color]::FromArgb(0, 0, 0), [System.Drawing.Color]$bottomColor = [System.Drawing.Color]::FromArgb(0, 50, 0))
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

    if ($form.PSObject.Properties['DoubleBuffered']) { $form.DoubleBuffered = $true }
}

# ANIMATED TITLE LABEL
function Add-TitleAnimation {
    param([System.Windows.Forms.Label]$titleLabel, [int]$interval = 500, [System.Drawing.Color]$color1 = [System.Drawing.Color]::FromArgb(0, 255, 0), [System.Drawing.Color]$color2 = [System.Drawing.Color]::FromArgb(0, 200, 0))
    
    if (-not $titleLabel) { Write-Warning "TitleLabel is null, cannot add animation"; return $null }

    $titleTimer = New-Object System.Windows.Forms.Timer
    $titleTimer.Interval = $interval
    $titleTimer.Tag = @{ Label = $titleLabel; Color1 = $color1; Color2 = $color2 }

    $titleTimer.Add_Tick({
        try {
            $data = $this.Tag
            $label = $data.Label
            if ($label -and -not $label.IsDisposed) {
                if ($label.ForeColor.ToArgb() -eq $data.Color1.ToArgb()) {
                    $label.ForeColor = $data.Color2
                } else {
                    $label.ForeColor = $data.Color1
                }
            } else {
                $this.Stop()
            }
        } catch {
            $this.Stop()
        }
    })

    $titleTimer.Start()
    return $titleTimer
}

# ADD STATUS TO A RICH TEXT BOX
function Add-Status {
    param([string]$message, [System.Windows.Forms.RichTextBox]$rtb, [System.Drawing.Color]$color = [System.Drawing.Color]::Lime)
    if ($rtb.Text -eq "Please select a device type..." -or $rtb.Text -eq "Status messages will appear here...") { $rtb.Clear() }
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

# EXPORT ALL FUNCTIONS
Export-ModuleMember -Function Hide-MainMenu, Show-MainMenu, New-DynamicButton, Add-GradientBackground, Add-TitleAnimation, Add-Status
