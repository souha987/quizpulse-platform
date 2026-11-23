# Script pour exposer QuizPulse sur Internet (accessible depuis n'importe quel appareil 4G/5G/Wi-Fi)
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       QuizPulse - Tunnel Public Multi-Appareils" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

Write-Host "1. Démarrage du tunnel avec ngrok sur le port 5000..." -ForegroundColor Green
Write-Host "Si vous avez un compte ngrok configuré :" -ForegroundColor White
Write-Host "   ngrok http 5000`n" -ForegroundColor Yellow

Write-Host "2. Alternative via localtunnel :" -ForegroundColor Green
Write-Host "   npx localtunnel --port 5000`n" -ForegroundColor Yellow

$choice = Read-Host "Tapez 1 pour lancer ngrok ou 2 pour localtunnel (ou Entrée pour ngrok)"
if ($choice -eq "2") {
    npx localtunnel --port 5000
} else {
    ngrok http 5000
}
