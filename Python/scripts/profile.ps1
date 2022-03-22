# $PSHome(=C:\Windows\System32\WindowsPowerShell\v1.0)に配置することで、
# PowerShell起動時に自動的に読み込まれる。
# ExecutionPolicyの変更が必要になるが、VSCodeのsettings.json -> "terminal.integrated.profiles.windows"で起動時に変更。
# VENV_ROOTはPythonインストール時にinstallation_settings.jsonの"venvRoot"で置換。

Function Activate-Venv{
    Param(
        $VenvName
    )
    $venvRoot = VENV_ROOT
    & (Join-Path $venvRoot "$VenvName/Scripts/Activate.ps1")
}

# Function New-Venv{
#     Param(
#         $venvName
#     )
#     $venvRoot = VENV_ROOT

#     Push-Location -Path $venvRoot
#     python -m venv $venvName
#     Copy-Item "./${venvName}/Scripts/python.exe" "./${venvName}/Scripts/python_venv_${venvName}.exe" #.pyファイルを仮想環境のpython.exeに関連付けられるよう別名でコピー
#     Activate-Venv $venvName
#     Pop-Location # 元のフォルダーに戻る    
# }

# Function Install-PyPackages{
#     Param(
#         [String]$findLinks, 
#         [String]$requirement
#     )

#     python -m pip install --force --no-index --find-links=$findLinks --requirement $requirement
# }
