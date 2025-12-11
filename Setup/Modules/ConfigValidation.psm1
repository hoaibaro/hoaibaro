function Test-BaroConfig {
    param (
        [string]$ConfigPath
    )

    $result = @{
        IsValid  = $true
        Errors   = @()
        Warnings = @()
        Config   = $null
    }

    # 1. Check Existence
    if (-not (Test-Path $ConfigPath)) {
        $result.IsValid = $false
        $result.Errors += "Config file not found at: $ConfigPath"
        return $result
    }

    # 2. Check JSON Syntax
    try {
        $jsonContent = Get-Content -Raw -Path $ConfigPath -ErrorAction Stop
        $config = $jsonContent | ConvertFrom-Json -ErrorAction Stop
        $result.Config = $config
    }
    catch {
        $result.IsValid = $false
        $result.Errors += "Invalid JSON syntax: $($_.Exception.Message)"
        return $result
    }

    # 3. Schema Validation (Required Fields)
    $requiredFields = @("sourcePaths", "wifi", "windowsActivation", "officeActivation", "domain")
    foreach ($field in $requiredFields) {
        if (-not $config.PSObject.Properties[$field]) {
            $result.IsValid = $false
            $result.Errors += "Missing required section: $field"
        }
    }

    # Validate specific keys if sections exist
    if ($config.windowsActivation) {
        if (-not $config.windowsActivation.productKey) { $result.Errors += "Missing windowsActivation.productKey"; $result.IsValid = $false }
    }
    if ($config.officeActivation) {
        if (-not $config.officeActivation.productKey) { $result.Errors += "Missing officeActivation.productKey"; $result.IsValid = $false }
    }
    if ($config.domain) {
        if (-not $config.domain.name) { $result.Errors += "Missing domain.name"; $result.IsValid = $false }
    }

    # 4. Path Validation (Optional but recommended)
    if ($config.sourcePaths) {
        if ($config.sourcePaths.software -and -not (Test-Path $config.sourcePaths.software)) {
            $result.Warnings += "Software source path does not exist: $($config.sourcePaths.software)"
        }
    }

    return $result
}

function New-BaroConfigTemplate {
    param (
        [string]$Path
    )
    
    $template = @{
        sourcePaths       = @{
            software = "D:\SETUP"
            drivers  = "D:\DRIVER"
        }
        wifi              = @{
            ssid     = "VietUnion_5.0GHz"
            password = "Pay00@17Years$"
        }
        windowsActivation = @{
            productKey = "R84N4-RPC7Q-W8TKM-VM7Y4-7H66Y"
            upgradeKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
        }
        officeActivation  = @{
            productKey = "Q2NKY-J42YJ-X2KVK-9Q9PT-MKP63"
        }
        domain            = @{
            name        = "vietunion.local"
            defaultUser = "-hdk-hieudang"
        }
        userManagement    = @{
            presetPasswords = @("Pr0t3ct10c@1@VU", "Aa1234567890")
        }
    }

    $json = $template | ConvertTo-Json -Depth 4
    Set-Content -Path $Path -Value $json
    Write-Host "Created template config at $Path" -ForegroundColor Green
}

Export-ModuleMember -Function Test-BaroConfig, New-BaroConfigTemplate
