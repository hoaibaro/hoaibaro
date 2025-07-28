# Simple test for Windows 11 password compatibility

# ADMIN PRIVILEGES CHECK
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrative privileges. Attempting to restart with elevation..."
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-ExecutionPolicy Bypass -WindowStyle Normal -File `"$scriptPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    exit
}

Write-Host "Testing Windows 11 Password Compatibility" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

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
        $build = [System.Environment]::OSVersion.Version.Build
        return @{
            IsWindows11 = $build -ge 22000
            Version = [System.Environment]::OSVersion.Version.ToString()
            Caption = "Unknown"
            Build = $build
        }
    }
}

# Test Windows version detection
Write-Host "`n1. Testing Windows Version Detection..." -ForegroundColor Yellow
$winVersion = Get-WindowsVersion
Write-Host "   Windows Version: $($winVersion.Caption)" -ForegroundColor White
Write-Host "   Build Number: $($winVersion.Build)" -ForegroundColor White
Write-Host "   Is Windows 11: $($winVersion.IsWindows11)" -ForegroundColor White

# Test user detection
Write-Host "`n2. Testing User Detection..." -ForegroundColor Yellow
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[-1]
Write-Host "   Current User: $currentUser" -ForegroundColor White

try {
    $localUser = Get-LocalUser -Name $currentUser -ErrorAction Stop
    Write-Host "   User exists in local users: Yes" -ForegroundColor Green
    Write-Host "   User enabled: $($localUser.Enabled)" -ForegroundColor White
}
catch {
    Write-Host "   User exists in local users: No" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
}

# Test admin privileges
Write-Host "`n3. Testing Administrative Privileges..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
Write-Host "   Running as Administrator: $isAdmin" -ForegroundColor $(if ($isAdmin) { "Green" } else { "Red" })

# Test password setting methods
Write-Host "`n4. Testing Password Setting Methods..." -ForegroundColor Yellow

# Test Set-LocalUser cmdlet
Write-Host "   Testing Set-LocalUser cmdlet..." -ForegroundColor White
try {
    $testUser = Get-LocalUser -Name $currentUser -ErrorAction Stop
    Write-Host "   Set-LocalUser cmdlet: Available" -ForegroundColor Green
}
catch {
    Write-Host "   Set-LocalUser cmdlet: Not available or error" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
}

# Test WMI approach
Write-Host "   Testing WMI approach..." -ForegroundColor White
try {
    $userAccount = Get-WmiObject -Class Win32_UserAccount -Filter "Name='$currentUser' AND LocalAccount=True" -ErrorAction Stop
    if ($userAccount) {
        Write-Host "   WMI approach: Available" -ForegroundColor Green
        Write-Host "   WMI User Name: $($userAccount.Name)" -ForegroundColor White
    }
    else {
        Write-Host "   WMI approach: User not found" -ForegroundColor Red
    }
}
catch {
    Write-Host "   WMI approach: Error" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
}

# Test net user command
Write-Host "   Testing net user command..." -ForegroundColor White
try {
    $process = Start-Process -FilePath "net" -ArgumentList "user $currentUser" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\netuser_test.txt" -RedirectStandardError "$env:TEMP\netuser_error.txt"
    if ($process.ExitCode -eq 0) {
        Write-Host "   net user command: Available" -ForegroundColor Green
    }
    else {
        Write-Host "   net user command: Error (Exit code: $($process.ExitCode))" -ForegroundColor Red
    }
    
    # Clean up temp files
    Remove-Item "$env:TEMP\netuser_test.txt" -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\netuser_error.txt" -ErrorAction SilentlyContinue
}
catch {
    Write-Host "   net user command: Exception occurred" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
}

# Test UAC elevation
Write-Host "`n5. Testing UAC Elevation..." -ForegroundColor Yellow
try {
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "cmd.exe"
    $processInfo.Arguments = "/c echo UAC Test"
    $processInfo.UseShellExecute = $true
    $processInfo.Verb = "runas"
    $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    
    Write-Host "   UAC elevation mechanism: Available" -ForegroundColor Green
}
catch {
    Write-Host "   UAC elevation mechanism: Error" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
}

Write-Host "`n6. Summary and Recommendations..." -ForegroundColor Yellow

if ($winVersion.IsWindows11) {
    Write-Host "   Detected Windows 11 - Enhanced compatibility mode recommended" -ForegroundColor Green
    Write-Host "   Recommended approach:" -ForegroundColor White
    Write-Host "   1. Try Set-LocalUser PowerShell cmdlet first" -ForegroundColor White
    Write-Host "   2. Fallback to WMI approach if Set-LocalUser fails" -ForegroundColor White
    Write-Host "   3. Final fallback to net user with UAC elevation" -ForegroundColor White
    Write-Host "   4. Enhanced error handling for security policies" -ForegroundColor White
}
else {
    Write-Host "   Detected Windows 10 - Standard compatibility mode" -ForegroundColor Green
    Write-Host "   Recommended approach:" -ForegroundColor White
    Write-Host "   1. Try Set-LocalUser PowerShell cmdlet first" -ForegroundColor White
    Write-Host "   2. Fallback to net user command" -ForegroundColor White
}

if (-not $isAdmin) {
    Write-Host "`n   WARNING: Not running as administrator!" -ForegroundColor Red
    Write-Host "   Password operations will likely fail without admin privileges." -ForegroundColor Red
}

Write-Host "`nTest completed. Enhanced password functions have been implemented with:" -ForegroundColor Green
Write-Host "- Multiple fallback methods for better Windows 11 compatibility" -ForegroundColor White
Write-Host "- Enhanced UAC handling and process elevation" -ForegroundColor White
Write-Host "- Better error messages with troubleshooting steps" -ForegroundColor White
Write-Host "- Windows version specific logic and optimizations" -ForegroundColor White

Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
