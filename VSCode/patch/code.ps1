$env:VSCODE_DEV=$null
$env:ELECTRON_RUN_AS_NODE=1

& (Join-Path $PSScriptRoot "../Code.exe") (Join-Path $PSScriptRoot '..\resources\app\out\cli.js')  --ms-enable-electron-run-as-node $Args | %{echo $_}
