#以下のコマンドでダウンロードする
#Set-ExecutionPolicy Bypass -Scope process

$settings = Join-Path $PSScriptRoot '../settings/installation_settings.json' | Resolve-Path | Get-Content -Encoding UTF8 -Raw | ConvertFrom-Json
$settings.installer -match 'python-\d.\d+'
$pythonVersion = ($Matches[0] -Replace "python-", "") -Replace "\.", ""
$pythonExe = Join-Path $env:PROGRAMFILES "/Python${pythonVersion}/python.exe"

$packages = (Join-Path $PSScriptRoot '..\packages')
$requirements = (Join-Path $PSScriptRoot '..\settings\requirements.txt')

& $pythonExe -m pip download --dest=$packages --requirement $requirements