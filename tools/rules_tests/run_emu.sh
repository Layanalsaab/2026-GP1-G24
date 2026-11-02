#!/bin/sh
# usage: run_emu.sh <project> <node script>   (frees a stale Firestore emulator first)
powershell.exe -NoProfile -Command 'Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { $p = Get-Process -Id $_ -ErrorAction SilentlyContinue; if ($p -and $p.ProcessName -eq "java") { Stop-Process -Id $_ -Force } }' >/dev/null 2>&1
sleep 2
npx firebase emulators:exec --only firestore --project "$1" "node $2" 2>&1
powershell.exe -NoProfile -Command 'Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { $p = Get-Process -Id $_ -ErrorAction SilentlyContinue; if ($p -and $p.ProcessName -eq "java") { Stop-Process -Id $_ -Force } }' >/dev/null 2>&1
