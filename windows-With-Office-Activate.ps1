# 1. طلب صلاحيات المسؤول تلقائياً
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# 2. تحديد مسار برنامج cloudflared وتجهيز النفق
$cloudflaredPath = "C:\Program Files (x86)\cloudflared"
if (!(Test-Path "$cloudflaredPath\cloudflared.exe")) {
    $cloudflaredPath = "C:\Program Files\cloudflared"
}

# دالة لتشغيل النفق في الخلفية
function Start-Tunnel {
    Write-Host "[*] Launching Cloudflare Tunnel..." -ForegroundColor Green
    cd $cloudflaredPath
    return Start-Process .\cloudflared.exe -ArgumentList "access tcp --hostname kms.amen7.qzz.io --listener 127.0.0.1:1688" -WindowStyle Hidden -PassThru
}

# دالة لتحديد مسار الأوفيس حسب المعمارية المحددة (x86 أو x64)
function Get-OfficePath ($architecture) {
    if ($architecture -eq "x86") {
        return "C:\Program Files (x86)\Microsoft Office\Office15", "C:\Program Files (x86)\Microsoft Office\Office16"
    } else {
        return "C:\Program Files\Microsoft Office\Office15", "C:\Program Files\Microsoft Office\Office16"
    }
}

# دالة تفعيل الأوفيس
function Activate-Office ($architecture) {
    $tunnel = Start-Tunnel
    Start-Sleep -Seconds 5
    
    $paths = Get-OfficePath $architecture
    $found = $false

    foreach ($path in $paths) {
        if (Test-Path "$path\ospp.vbs") {
            $found = $true
            Write-Host "[*] Office found in: $path" -ForegroundColor Cyan
            cd $path
            Write-Host "[*] Configuring KMS Server for Office..." -ForegroundColor Yellow
            cscript //nologo ospp.vbs /sethst:127.0.0.1
            cscript //nologo ospp.vbs /setprt:1688
            Write-Host "[*] Sending Office activation request..." -ForegroundColor Yellow
            cscript //nologo ospp.vbs /act
            break
        }
    }

    if (-not $found) {
        Write-Host "[ERROR] Microsoft Office ($architecture) was not found on this system!" -ForegroundColor Red
    }

    # إغلاق النفق
    Write-Host "[*] Closing background tunnel..." -ForegroundColor Yellow
    Stop-Process -Id $tunnel.Id -Force -ErrorAction SilentlyContinue
}

# دالة تفعيل الويندوز
function Activate-Windows {
    $tunnel = Start-Tunnel
    Start-Sleep -Seconds 5
    Write-Host "[*] Configuring KMS Server for Windows..." -ForegroundColor Yellow
    cmd.exe /c "slmgr /skms 127.0.0.1:1688"
    Write-Host "[*] Sending Windows activation request..." -ForegroundColor Yellow
    cmd.exe /c "slmgr /ato"
    
    Write-Host "[*] Closing background tunnel..." -ForegroundColor Yellow
    Stop-Process -Id $tunnel.Id -Force -ErrorAction SilentlyContinue
}

# --- القائمة الرئيسية التفاعلية ---
do {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "        Ultimate Cloud KMS Activation Menu         " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host " 1) Activate Windows (All Versions)" -ForegroundColor White
    Write-Host " 2) Activate Office (64-bit) - [2016 / 2019 / 2021 / 365]" -ForegroundColor White
    Write-Host " 3) Activate Office (32-bit/x86) - [2016 / 2019 / 2021 / 365]" -ForegroundColor White
    Write-Host " 4) Activate Office 2013 (64-bit)" -ForegroundColor White
    Write-Host " 5) Activate Office 2013 (32-bit/x86)" -ForegroundColor White
    Write-Host " 6) Exit" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Cyan
    $choice = Read-Host "Please enter your choice (1-6)"

    switch ($choice) {
        "1" { Clear-Host; Activate-Windows }
        "2" { Clear-Host; Activate-Office "x64" }
        "3" { Clear-Host; Activate-Office "x86" }
        "4" { Clear-Host; Activate-Office "x64" } # أوفيس 2013 يعتمد على مسار Office15 وتتعامل معه الدالة تلقائياً
        "5" { Clear-Host; Activate-Office "x86" }
        "6" { Write-Host "Exiting... Goodbye!" -ForegroundColor Green; Exit }
        default { Write-Host "Invalid choice! Please select between 1 and 6." -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
    
    if ($choice -ne "6") {
        Write-Host ""
        Write-Host "Press any key to return to the menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
} while ($choice -ne "6")
