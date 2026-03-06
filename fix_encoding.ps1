$path = 'C:\Users\braulio.augusto\Documents\Git\tiny11builder\Tiny11Gui.ps1'
$content = Get-Content $path -Raw -Encoding UTF8
Set-Content -Path $path -Value $content -Encoding UTF8
