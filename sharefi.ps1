
---

## ShareFI.ps1 (sanitized, portable)

```powershell
param(
    [Parameter(Mandatory=$false)][string]$Ssid,
    [Parameter(Mandatory=$false)][string]$Password,
    [Parameter(Mandatory=$false)][ValidateSet('WPA','WEP','nopass')][string]$AuthType = 'WPA',
    [Parameter(Mandatory=$false)][string]$OutPath = ".\wifi-qr.png",
    [Parameter(Mandatory=$false)][string]$QRCoderPath = ".\QRCoder.dll"
)

function Get-CurrentSsid {
    $out = netsh wlan show interfaces
    foreach ($line in $out) {
        if ($line -match '^\s*SSID\s*:\s*(.+)$') { return ($Matches[1]).Trim() }
    }
    return $null
}

function Get-SavedPassword {
    param([string]$ProfileName)
    $out = netsh wlan show profile name="$ProfileName" key=clear
    foreach ($line in $out) {
        if ($line -match '^\s*Key Content\s*:\s*(.+)$') { return ($Matches[1]).Trim() }
    }
    return $null
}

# Resolve inputs if not provided
if (-not $Ssid) { $Ssid = Get-CurrentSsid }
if (-not $Password -and $Ssid) { $Password = Get-SavedPassword -ProfileName $Ssid }
if (-not $Ssid) { Write-Error "SSID not found. Provide -Ssid or connect to Wi‑Fi."; exit 1 }
if ($AuthType -ne 'nopass' -and -not $Password) { Write-Error "Password not found. Provide -Password or use -AuthType nopass."; exit 1 }

# Build Wi‑Fi QR payload (Android/iOS standard)
# Escape semicolons/backslashes per common conventions if present
$esc = {
    param([string]$s)
    if ($null -eq $s) { return "" }
    return ($s -replace '\\','\\\\' -replace ';','\;')
}
$ssidEsc = & $esc $Ssid
$passEsc = & $esc $Password
$wifiPayload = "WIFI:T:$AuthType;S:$ssidEsc;P:$passEsc;;"

# Try PSQRCode first, else fall back to QRCoder.dll if present
try {
    if (Get-Module -ListAvailable -Name PSQRCode) {
        Import-Module PSQRCode -ErrorAction Stop
        New-PSQRCode -Payload $wifiPayload -OutPath $OutPath
        Write-Host "QR code saved to $OutPath"
        exit 0
    }
} catch {}

# Fallback to QRCoder.dll
if (Test-Path $QRCoderPath) {
    Add-Type -Path $QRCoderPath
    $gen   = New-Object QRCoder.QRCodeGenerator
    $data  = $gen.CreateQrCode($wifiPayload, [QRCoder.QRCodeGenerator+ECCLevel]::Q)
    $qr    = New-Object QRCoder.QRCode $data
    $bmp   = $qr.GetGraphic(20)
    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "QR code saved to $OutPath"
} else {
    Write-Error "No QR engine found. Install PSQRCode or place QRCoder.dll alongside the script."
    exit 1
}
