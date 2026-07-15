# Deploy do MX PERDCOMP para a VPS
# Publica o index.html em /var/www/perdcomp (perdcomp.maximosapp.com.br)
# Tambem atualiza o GitHub Pages (git push), que serve como espelho.
$ErrorActionPreference = "Stop"
$pasta = Split-Path -Parent $MyInvocation.MyCommand.Path
$chave = "$env:USERPROFILE\.ssh\mxwhats_deploy"
$destino = "root@76.13.235.201:/var/www/perdcomp/index.html"

Write-Host "== Deploy MX PERDCOMP ==" -ForegroundColor Cyan
Write-Host "Enviando index.html para a VPS..."
scp -i $chave "$pasta\index.html" $destino
if ($LASTEXITCODE -ne 0) { throw "Falha no scp (codigo $LASTEXITCODE)" }
Write-Host "Publicado na VPS!" -ForegroundColor Green
Write-Host "  https://perdcomp.maximosapp.com.br  (dominio oficial)"
Write-Host "  https://perdcomp.76-13-235-201.sslip.io  (endereco reserva)"

# Espelho no GitHub Pages (opcional; ignora erro se sem alteracoes)
try {
    Set-Location $pasta
    git add -A 2>$null
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        git commit -m "deploy: atualizacao via deploy.ps1" | Out-Null
        git push origin master | Out-Null
        Write-Host "Espelho GitHub Pages atualizado." -ForegroundColor Green
    }
} catch { Write-Host "(espelho GitHub nao atualizado: $_)" -ForegroundColor Yellow }
