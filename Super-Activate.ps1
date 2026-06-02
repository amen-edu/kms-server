# 1. طلب صلاحيات المسؤول تلقائياً لكي تعمل أوامر التفعيل
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# 2. تحديد مسار برنامج cloudflared وتشغيل النفق في الخلفية
$cloudflaredPath = "C:\Program Files (x86)\cloudflared"
if (!(Test-Path "$cloudflaredPath\cloudflared.exe")) {
    $cloudflaredPath = "C:\Program Files\cloudflared"
}

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "        Welcome to Cloud KMS Auto-Activator        " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Launching Cloudflare Tunnel..." -ForegroundColor Green
cd $cloudflaredPath
# تشغيل النفق كعملية منفصلة في الخلفية لكي لا يتوقف السكربت عنده
$tunnelProcess = Start-Process .\cloudflared.exe -ArgumentList "access tcp --hostname kms.amen7.qzz.io --listener 127.0.0.1:1688" -WindowStyle Hidden -PassThru

# الانتظار 5 ثوانٍ لضمان استقرار الاتصال والنفق
Write-Host "Waiting for connection establishment..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 3. تنفيذ أوامر التفعيل (slmgr)
Write-Host ""
Write-Host "[2/3] Connecting Windows to local network tunnel..." -ForegroundColor Green
cmd.exe /c "slmgr /skms 127.0.0.1:1688"

Write-Host ""
Write-Host "[3/3] Sending activation request to your server..." -ForegroundColor Green
cmd.exe /c "slmgr /ato"

Write-Host ""
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "Process finished! Check the system popup for success." -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# 4. إغلاق النفق وتنظيف العمليات لراحة الجهاز
Write-Host "Closing the background tunnel..." -ForegroundColor Yellow
Stop-Process -Id $tunnelProcess.Id -Force -ErrorAction SilentlyContinue

Write-Host "Done. Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
