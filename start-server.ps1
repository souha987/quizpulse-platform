# Script de lancement tout-en-un pour QuizPulse (Accès local & multi-appareils)
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       QuizPulse - Lancement & Déploiement Multi-Appareils" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# Récupération de l'adresse IP locale Wi-Fi
$ip = "10.135.214.89"
try {
    $foundIp = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceAlias -notmatch "Loopback|vEthernet" -and $_.IPAddress -notmatch "^169\." } | Select-Object -ExpandProperty IPAddress -First 1)
    if ($foundIp) { $ip = $foundIp }
} catch {}

Write-Host "`n🚀 Serveur Express + Flutter Web actif sur le port 5000 :" -ForegroundColor Green
Write-Host "💻 Sur cet ordinateur :            http://localhost:5000" -ForegroundColor White
Write-Host "📱 Sur votre smartphone / Wi-Fi :  http://${ip}:5000" -ForegroundColor Yellow
Write-Host "🌐 Pour un accès externe (4G/5G) : Utilisez un tunnel (ngrok http 5000) ou Render" -ForegroundColor Cyan
Write-Host "==========================================================`n" -ForegroundColor Cyan

Set-Location -Path "$PSScriptRoot"
node backend/dist/server.js
