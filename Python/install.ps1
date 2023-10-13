function Install-Python{
    Param(
        [String]$installer, #Pythonインストーラー
        [String]$venvRoot   #仮想環境のインストール先
    )
    
    # Pythonインストール
    # コマンドラインオプションは以下を参照
    # https://docs.python.org/ja/3/using/windows.html
    & $installer /passive InstallAllUsers=1 PrependPath=1 CompileAll=1
    $installerProcessName = ([System.IO.Path]::GetFileNameWithoutExtension($installer))
    Wait-Process -Name $installerProcessName
    
    # PowerShellのプロファイル（スタートアップ）にActivate-Venvコマンドレット等を登録
    $tmpFolder = Join-Path $PSScriptRoot './tmp'
    $tmpProfile = Join-Path $PSScriptRoot './tmp/profile.ps1'
    New-Item $tmpFolder -ItemType Directory -Force
    Get-Content (Join-Path $PSScriptRoot './scripts/profile.ps1') -Encoding UTF8 `
    | ForEach-Object {$_ -replace 'VENV_ROOT', "'$($venvRoot)'"} `
    | Out-File $tmpProfile -Encoding UTF8
    Copy-Item $tmpProfile $PSHome -Force
}


function New-Venv{
    Param(
        [String]$installer, #Pythonインストーラー
        [String]$venvRoot,  #仮想環境のインストール先
        [String]$venvName   #仮想環境名
    )
    
    # 仮想環境作成
    $installerProcessName = ([System.IO.Path]::GetFileNameWithoutExtension($installer))
    $installerProcessName -match 'python-\d.\d+'
    $pythonVersion = ($Matches[0] -Replace "python-", "") -Replace "\.", ""
    $pythonExe = Join-Path $env:PROGRAMFILES "/Python${pythonVersion}/python.exe"
    
    New-Item $venvRoot -ItemType Directory -Force
    Push-Location -Path $venvRoot
    & $pythonExe -m venv $venvName
    Copy-Item "./${venvName}/Scripts/python.exe" "./${venvName}/Scripts/python_venv_${venvName}.exe" #.pyファイルを仮想環境のpython.exeに関連付けられるよう別名でコピー
    Pop-Location # 元のフォルダーに戻る    
}


function Install-Packages{
    Param(
        [String]$venvRoot,  #仮想環境のインストール先
        [String]$venvName   #仮想環境名
    )
    
    # 仮想環境をactivate
    & (Join-Path $venvRoot ($venvName + '\Scripts\Activate.ps1'))
    
    # パッケージインストール
    $packages = (Join-Path $PSScriptRoot '.\packages') # 変数にしない or 最後に\を入れるとpip installに失敗する
    $requirements = (Join-Path $PSScriptRoot '.\settings\requirements.txt')
    python -m pip install `
        --force `
        --no-index --find-links=$packages `
        --requirement $requirements 
}


function Install-XlwingsAddin{
    Param(
        [String]$venvRoot,  #仮想環境のインストール先
        [String]$venvName   #仮想環境名
    )
    
    # 仮想環境をactivate
    & (Join-Path $venvRoot ($venvName + '\Scripts\Activate.ps1'))
    
    
    # Excelを終了
    $ErrorActionPreference = "silentlycontinue"
    Stop-Process -Name Excel -force
    $ErrorActionPreference = "continue"
    
    # xlwingsアドイン インストール
    xlwings addin install
    xlwings config create --force
    $xlwingsConf = (Join-Path $env:USERPROFILE \.xlwings\xlwings.conf)       
    Add-Content -Path $xlwingsConf -Value '"SHOW CONSOLE","True"'       
    Add-Content -Path $xlwingsConf -Value '"USE UDF SERVER","True"'    
}


function Invoke-Main{
    # 設定
    $settings = Join-Path $PSScriptRoot './settings/installation_settings.json' | Resolve-Path | Get-Content -Encoding UTF8 -Raw | ConvertFrom-Json
    $installer = Resolve-Path (Join-Path $PSScriptRoot ('./installer/' + $settings.installer))
    $venvRoot = $settings.venvRoot # 仮想環境インストール先フォルダー
    $venvName = $settings.venvName # 仮想環境名


    # 開始メッセージ
    Write-Host ((
        'Pythonおよびパッケージをインストールします。',
        'インストール対象に応じて1～5を入力してください。',
        '（1、2は管理者権限が必要です）',
        '    1: 以下の2～4',
        '    2: Python本体',
        '    3: 仮想環境（base:venv）作成',
        '    4: Pythonパッケージ',
        '    5: xlwingsアドイン',
        '    それ以外: インストール中止'
    ) -join "`n")


    # インストール
    $target = Read-Host
    switch ($target){
        1 {
            Install-Python -installer $installer -venvRoot $venvRoot
            New-Venv -installer $installer -venvRoot $venvRoot -venvName $venvName
            Install-Packages -venvRoot $venvRoot -venvName $venvName
        }
        2 {
            Install-Python -installer $installer -venvRoot $venvRoot
        }
        3 {
            New-Venv -installer $installer -venvRoot $venvRoot -venvName $venvName
        }
        4 {
            Install-Packages -venvRoot $venvRoot -venvName $venvName
        }
        5 {
            Install-XlwingsAddin -venvRoot $venvRoot -venvName $venvName
        }
    }


    # 終了メッセージ
    if ($target -in @(1, 2, 3, 4, 5)){
        Write-Host 'インストールが終了しました。'
    }
    Write-Host '終了するには任意のキーを押してください。'
    Read-Host   
}


# Pythonのif __name__ == '__main__': 的な
If ((Resolve-Path -Path $MyInvocation.InvocationName).ProviderPath -eq $MyInvocation.MyCommand.Path) {
    Invoke-Main
}
