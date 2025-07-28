# Test script for Windows 11 compatible password functions
# This script tests the enhanced password logic for Windows 11

# ADMIN PRIVILEGES CHECK
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrative privileges. Attempting to restart with elevation..."
    
    # Restart script with admin privileges
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-ExecutionPolicy Bypass -WindowStyle Normal -File `"$scriptPath`""
    
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    
    # Exit the current non-elevated instance
    exit
}

Write-Host "Testing Enhanced Password Functions for Windows 11" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

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

# Enhanced Set-UserPassword function (copy from main script)
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

        Write-Host "Testing password setting for Windows version: $($winVersion.Caption)" -ForegroundColor Yellow
        Write-Host "Build: $($winVersion.Build), IsWindows11: $($winVersion.IsWindows11)" -ForegroundColor Yellow

        # Enhanced Windows 11 compatible password setting logic
        if ($winVersion.IsWindows11) {
            Write-Host "Using Windows 11 enhanced methods..." -ForegroundColor Cyan
            
            # Windows 11 - Multiple approaches for better compatibility
            if ([string]::IsNullOrEmpty($password)) {
                Write-Host "Attempting to remove password (set to blank)..." -ForegroundColor Yellow
                
                # Method 1: Try Set-LocalUser with empty password
                try {
                    Write-Host "Method 1: Set-LocalUser cmdlet..." -ForegroundColor White
                    $securePassword = ConvertTo-SecureString "" -AsPlainText -Force
                    Set-LocalUser -Name $user -Password $securePassword -ErrorAction Stop
                    Write-Host "✓ Set-LocalUser succeeded" -ForegroundColor Green
                    return $true
                }
                catch {
                    Write-Host "✗ Set-LocalUser failed: $($_.Exception.Message)" -ForegroundColor Red
                }

                # Method 2: Try WMI approach for Windows 11
                try {
                    Write-Host "Method 2: WMI approach..." -ForegroundColor White
                    $userAccount = Get-WmiObject -Class Win32_UserAccount -Filter "Name='$user' AND LocalAccount=True" -ErrorAction Stop
                    if ($userAccount) {
                        $userAccount.SetPassword("")
                        Write-Host "✓ WMI approach succeeded" -ForegroundColor Green
                        return $true
                    }
                }
                catch {
                    Write-Host "✗ WMI approach failed: $($_.Exception.Message)" -ForegroundColor Red
                }

                # Method 3: Enhanced net user with UAC handling
                try {
                    Write-Host "Method 3: Enhanced net user with UAC..." -ForegroundColor White
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
                    if ($process.ExitCode -eq 0) {
                        Write-Host "✓ Enhanced net user succeeded" -ForegroundColor Green
                        return $true
                    }
                    else {
                        Write-Host "✗ Enhanced net user failed with exit code: $($process.ExitCode)" -ForegroundColor Red
                    }
                }
                catch {
                    Write-Host "✗ Enhanced net user failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Attempting to set password to: '$password'..." -ForegroundColor Yellow
                
                # Set new password - Windows 11
                # Method 1: Try Set-LocalUser
                try {
                    Write-Host "Method 1: Set-LocalUser cmdlet..." -ForegroundColor White
                    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
                    Set-LocalUser -Name $user -Password $securePassword -ErrorAction Stop
                    Write-Host "✓ Set-LocalUser succeeded" -ForegroundColor Green
                    return $true
                }
                catch {
                    Write-Host "✗ Set-LocalUser failed: $($_.Exception.Message)" -ForegroundColor Red
                }

                # Method 2: Try WMI approach
                try {
                    Write-Host "Method 2: WMI approach..." -ForegroundColor White
                    $userAccount = Get-WmiObject -Class Win32_UserAccount -Filter "Name='$user' AND LocalAccount=True" -ErrorAction Stop
                    if ($userAccount) {
                        $userAccount.SetPassword($password)
                        Write-Host "✓ WMI approach succeeded" -ForegroundColor Green
                        return $true
                    }
                }
                catch {
                    Write-Host "✗ WMI approach failed: $($_.Exception.Message)" -ForegroundColor Red
                }

                # Method 3: Enhanced net user with UAC handling
                try {
                    Write-Host "Method 3: Enhanced net user with UAC..." -ForegroundColor White
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
                    if ($process.ExitCode -eq 0) {
                        Write-Host "✓ Enhanced net user succeeded" -ForegroundColor Green
                        return $true
                    }
                    else {
                        Write-Host "✗ Enhanced net user failed with exit code: $($process.ExitCode)" -ForegroundColor Red
                    }
                }
                catch {
                    Write-Host "✗ Enhanced net user failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            
            # If all Windows 11 methods fail, throw error
            throw "All Windows 11 password setting methods failed. Please ensure you have administrative privileges and UAC is properly configured."
        }
        else {
            Write-Host "Using Windows 10 methods..." -ForegroundColor Cyan
            
            # Windows 10 - use traditional approach with enhancements
            try {
                # Method 1: Try Set-LocalUser first (available in Windows 10 1607+)
                Write-Host "Method 1: Set-LocalUser cmdlet..." -ForegroundColor White
                if ([string]::IsNullOrEmpty($password)) {
                    $securePassword = ConvertTo-SecureString "" -AsPlainText -Force
                }
                else {
                    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
                }
                Set-LocalUser -Name $user -Password $securePassword -ErrorAction Stop
                Write-Host "✓ Set-LocalUser succeeded" -ForegroundColor Green
                return $true
            }
            catch {
                # Method 2: Fallback to net user command
                Write-Host "Method 2: Fallback to net user..." -ForegroundColor White
                if ([string]::IsNullOrEmpty($password)) {
                    $command = "net user `"$user`" """""
                }
                else {
                    $command = "net user `"$user`" `"$password`""
                }
                $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command" -NoNewWindow -Wait -PassThru
                if ($process.ExitCode -eq 0) {
                    Write-Host "✓ net user succeeded" -ForegroundColor Green
                    return $true
                }
                else {
                    Write-Host "✗ net user failed with exit code: $($process.ExitCode)" -ForegroundColor Red
                    return $false
                }
            }
        }
    }
    catch {
        Write-Host "✗ Error setting password: $_" -ForegroundColor Red
        return $false
    }
}

# Test the enhanced password function
Write-Host "`n1. Testing Windows Version Detection..." -ForegroundColor Yellow
$winVersion = Get-WindowsVersion
Write-Host "   Windows Version: $($winVersion.Caption)" -ForegroundColor White
Write-Host "   Build Number: $($winVersion.Build)" -ForegroundColor White
Write-Host "   Is Windows 11: $($winVersion.IsWindows11)" -ForegroundColor White

Write-Host "`n2. Testing User Detection..." -ForegroundColor Yellow
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
Write-Host "   Current User: $currentUser" -ForegroundColor White

Write-Host "`n3. Testing Administrative Privileges..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
Write-Host "   Running as Administrator: $isAdmin" -ForegroundColor $(if ($isAdmin) { "Green" } else { "Red" })

if ($isAdmin) {
    Write-Host "`n4. Testing Password Setting Function..." -ForegroundColor Yellow
    Write-Host "   This is a DRY RUN - no actual password changes will be made" -ForegroundColor Cyan
    Write-Host "   To test actual password setting, modify the script" -ForegroundColor Cyan
    
    # Uncomment the lines below to test actual password setting
    # Write-Host "`n   Testing setting password to 'test123'..." -ForegroundColor Yellow
    # $result = Set-UserPassword -user $currentUser -password "test123"
    # Write-Host "   Result: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
    
    # Write-Host "`n   Testing removing password (blank)..." -ForegroundColor Yellow
    # $result = Set-UserPassword -user $currentUser -password ""
    # Write-Host "   Result: $result" -ForegroundColor $(if ($result) { "Green" } else { "Red" })
}
else {
    Write-Host "`n   WARNING: Not running as administrator!" -ForegroundColor Red
    Write-Host "   Password operations will fail without admin privileges." -ForegroundColor Red
}

Write-Host "`n✅ Enhanced Password Function Test Completed!" -ForegroundColor Green
Write-Host "`nKey improvements for Windows 11:" -ForegroundColor Yellow
Write-Host "  ✓ Multiple fallback methods (Set-LocalUser, WMI, net user)" -ForegroundColor Green
Write-Host "  ✓ Enhanced UAC handling with ProcessStartInfo" -ForegroundColor Green
Write-Host "  ✓ Better error messages and troubleshooting info" -ForegroundColor Green
Write-Host "  ✓ Windows version specific logic" -ForegroundColor Green
Write-Host "  ✓ Proper timeout handling for processes" -ForegroundColor Green

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
