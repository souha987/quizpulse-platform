# Script de nettoyage et préparation pour l'archive ZIP
Write-Host "Nettoyage des fichiers temporaires, caches et fichiers sensibles pour l'archive ZIP..." -ForegroundColor Cyan

# 1. Suppression .idea
if (Test-Path ".idea") { Remove-Item -Recurse -Force ".idea"; Write-Host "✔ .idea supprimé" -ForegroundColor Green }
if (Test-Path "frontend\.idea") { Remove-Item -Recurse -Force "frontend\.idea"; Write-Host "✔ frontend\.idea supprimé" -ForegroundColor Green }

# 2. Suppression .dart_tool/chrome-device
if (Test-Path "frontend\.dart_tool\chrome-device") { Remove-Item -Recurse -Force "frontend\.dart_tool\chrome-device"; Write-Host "✔ frontend\.dart_tool\chrome-device supprimé" -ForegroundColor Green }

# 3. Suppression dist
if (Test-Path "backend\dist") { Remove-Item -Recurse -Force "backend\dist"; Write-Host "✔ backend\dist supprimé" -ForegroundColor Green }

# 4. Suppression .env sensibles (en conservant .env.example)
if (Test-Path "backend\.env") { Remove-Item -Force "backend\.env"; Write-Host "✔ backend\.env supprimé (.env.example conservé)" -ForegroundColor Green }
if (Test-Path ".env") { Remove-Item -Force ".env"; Write-Host "✔ .env supprimé (.env.example conservé)" -ForegroundColor Green }

# 5. Optionnel : Suppression node_modules
# if (Test-Path "backend\node_modules") { Remove-Item -Recurse -Force "backend\node_modules"; Write-Host "✔ backend\node_modules supprimé" -ForegroundColor Green }

Write-Host "Projet prêt pour archivage propre !" -ForegroundColor Cyan
