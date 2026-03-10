$logFile = "C:\Users\braulio.augusto\Documents\Git\tiny11builder\cleanup.log"
"Iniciando limpeza profunda..." > $logFile

Write-Output "Tentando desmontar a imagem..." >> $logFile
dism /unmount-image /mountdir:"C:\Users\braulio.augusto\Documents\Git\tiny11builder\build\scratchdir" /discard >> $logFile 2>&1

Write-Output "Limpando pontos de montagem WIM fumaça..." >> $logFile
dism /cleanup-wim >> $logFile 2>&1

Write-Output "Tomando posse da pasta build (Isso pode demorar um pouco)..." >> $logFile
takeown /f "C:\Users\braulio.augusto\Documents\Git\tiny11builder\build" /r /d y | Out-Null
icacls "C:\Users\braulio.augusto\Documents\Git\tiny11builder\build" /grant "Administradores:(OI)(CI)F" /T /C /Q | Out-Null
icacls "C:\Users\braulio.augusto\Documents\Git\tiny11builder\build" /grant "Administrators:(OI)(CI)F" /T /C /Q | Out-Null

Write-Output "Excluindo a pasta build..." >> $logFile
Remove-Item -Path "C:\Users\braulio.augusto\Documents\Git\tiny11builder\build" -Recurse -Force >> $logFile 2>&1

Write-Output "Limpeza finalizada." >> $logFile
