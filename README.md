# ShareFI

**ShareFI** is a lightweight Windows utility that generates scannable Wi‑Fi QR codes.  
Scan the QR with Android or iOS to connect instantly — no typing passwords.

## ✨ Features
- Detects the current Wi‑Fi SSID (and retrieves the saved password when available)
- Generates a QR code in the Android/iOS Wi‑Fi standard format
- Saves as PNG for easy sharing
- Optional right‑click integration (planned)

## 🔧 Usage

### Option A: PowerShell module (recommended)
Install the QR module once, then generate your code.

```powershell
Install-Module -Name PSQRCode -Scope CurrentUser
New-PSQRCodeWiFiAccess -SSID "<SSID>" -Password "<PASSWORD>" -OutPath ".\wifi-qr.png"
