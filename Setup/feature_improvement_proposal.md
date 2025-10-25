# Đề xuất cải tiến: Tự động sử dụng nguồn cục bộ cho Windows Features

**Người đề xuất:** Gemini
**Ngày:** 2025-10-25

## 1. Vấn đề

Trên các máy Windows mới cài đặt, chức năng "Features" (ví dụ: bật .NET 3.5) thường thất bại. Nguyên nhân là do lệnh `dism.exe` không thể tìm thấy các tệp cài đặt cần thiết từ Windows Update.

## 2. Giải pháp đề xuất

Cải tiến kịch bản để nó có khả năng "dự phòng" (fallback). Cụ thể:

1.  **Ưu tiên** sử dụng phương pháp online (kết nối Windows Update) như hiện tại.
2.  **Nếu thất bại**, kịch bản sẽ **tự động** chuyển sang sử dụng một nguồn cài đặt cục bộ (thư mục `sxs` từ bộ cài Windows) do người dùng định nghĩa trong `config.json`.

Điều này giúp chức năng hoạt động ổn định ngay cả trên các máy mới cài mà không cần chờ Windows Update.

## 3. Các thay đổi cần thực hiện

### Bước 1: Cập nhật tệp `config.json`

Cần thêm một khóa mới là `"sxs"` vào mục `"sourcePaths"` để chỉ định đường dẫn đến thư mục `sources\sxs` đã được sao chép từ bộ cài Windows.

**Ví dụ:**
```json
{
  "sourcePaths": {
    "drivers": "D:\\...",
    "software": "D:\\...",
    "sxs": "D:\\Win-Setup\\sxs",
    "...": "..."
  },
  "...": "..."
}
```

### Bước 2: Cập nhật hàm `Set-WindowsFeatureState` trong `WindowsFeatures.psm1`

Toàn bộ hàm `Set-WindowsFeatureState` sẽ được thay thế bằng phiên bản nâng cấp dưới đây. Logic mới sẽ xử lý việc thử lại với nguồn cục bộ.

```powershell
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

                # --- LOGIC CẢI TIẾN BẮT ĐẦU TỪ ĐÂY ---
                
                # 1. Thử phương pháp Online trước
                $onlineArgs = $feature.Command.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Skip 1
                $onlineResult = Start-Process -FilePath "dism" -ArgumentList $onlineArgs -Wait -PassThru -WindowStyle Hidden

                # 2. Kiểm tra kết quả, nếu thất bại thì thử lại với nguồn cục bộ
                # Mã lỗi 2 (ERROR_FILE_NOT_FOUND) và -2146498529 (CBS_E_SOURCE_MISSING) là các lỗi phổ biến khi không tìm thấy nguồn.
                if ($onlineResult.ExitCode -in 0, 3010) {
                    $statusMsg = "$($feature.DisplayName): $actionVerbPast completed (Online)."
                    if ($onlineResult.ExitCode -eq 3010) { $statusMsg += " (Restart required)" }
                    Add-Status $statusMsg $statusTextBox ([System.Drawing.Color]::Green)
                }
                else {
                    Add-Status "Online method failed (Code: $($onlineResult.ExitCode)). Checking for local source..." $statusTextBox ([System.Drawing.Color]::Yellow)
                    
                    $sxsPath = $Global:config.sourcePaths.sxs
                    if ($sxsPath -and (Test-Path $sxsPath)) {
                        Add-Status "Local source found at '$sxsPath'. Retrying..." $statusTextBox ([System.Drawing.Color]::Cyan)
                        
                        $offlineArgs = "/online /enable-feature /featurename:$($feature.Name) /all /LimitAccess /Source:`"$sxsPath`""
                        $offlineResult = Start-Process -FilePath "dism" -ArgumentList $offlineArgs -Wait -PassThru -WindowStyle Hidden

                        if ($offlineResult.ExitCode -in 0, 3010) {
                            $statusMsg = "$($feature.DisplayName): $actionVerbPast completed (Local Source)."
                            if ($offlineResult.ExitCode -eq 3010) { $statusMsg += " (Restart required)" }
                            Add-Status $statusMsg $statusTextBox ([System.Drawing.Color]::Green)
                        }
                        else {
                            Add-Status "ERROR: Local source method also failed (Code: $($offlineResult.ExitCode))." $statusTextBox ([System.Drawing.Color]::Red)
                        }
                    }
                    else {
                        Add-Status "ERROR: Local source path not configured or invalid in config.json." $statusTextBox ([System.Drawing.Color]::Red)
                    }
                }
                # --- KẾT THÚC LOGIC CẢI TIẾN ---
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
```

## 4. Các bước tiếp theo

Khi bạn sẵn sàng, hãy cho tôi biết và tôi sẽ áp dụng những thay đổi này vào code của bạn.
