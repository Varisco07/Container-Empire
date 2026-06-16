# =============================================================================
# Dev run con dati PERSISTENTI.
#
# "flutter run -d chrome" apre Chrome con un profilo temporaneo usa-e-getta:
# ad ogni riavvio azzera login + dati locali (Hive/IndexedDB), e l'impero
# sembra resettarsi. Questo script invece serve l'app su una porta FISSA (8080)
# e apre il TUO browser normale: login e impero restano tra i riavvii.
#
# Uso:   .\run.ps1            (oppure  .\run.ps1 -Port 9000)
# Stop:  Ctrl+C nel terminale
# Dopo una modifica al codice: premi  r  (hot reload) o  R  (restart) nel
# terminale, poi aggiorna la pagina del browser (F5).
# =============================================================================
param(
    [int]$Port = 8080
)

$url = "http://localhost:$Port"

# In background: appena la porta risponde, apre il browser predefinito una volta.
Start-Job -ArgumentList $Port, $url -ScriptBlock {
    param($p, $u)
    while ($true) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $client.Connect('127.0.0.1', [int]$p)
            $client.Close()
            Start-Process $u
            break
        } catch {
            Start-Sleep -Seconds 1
        }
    }
} | Out-Null

Write-Host ""
Write-Host "  Dev server su $url  -  browser persistente (login + impero non si azzerano)" -ForegroundColor Cyan
Write-Host "  Compilo... il browser si apre da solo appena pronto." -ForegroundColor DarkGray
Write-Host ""

flutter run -d web-server --web-port=$Port
