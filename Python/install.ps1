function Install-Python{
    Param(
        [String]$installer, #Python�C���X�g�[���[
        [String]$venvRoot   #���z���̃C���X�g�[����
    )
    
    # Python�C���X�g�[��
    # �R�}���h���C���I�v�V�����͈ȉ����Q��
    # https://docs.python.org/ja/3/using/windows.html
    & $installer /passive InstallAllUsers=1 PrependPath=1 CompileAll=1
    $installerProcessName = ([System.IO.Path]::GetFileNameWithoutExtension($installer))
    Wait-Process -Name $installerProcessName
    
    # PowerShell�̃v���t�@�C���i�X�^�[�g�A�b�v�j��Activate-Venv�R�}���h���b�g����o�^
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
        [String]$installer, #Python�C���X�g�[���[
        [String]$venvRoot,  #���z���̃C���X�g�[����
        [String]$venvName   #���z����
    )
    
    # ���z���쐬
    $installerProcessName = ([System.IO.Path]::GetFileNameWithoutExtension($installer))
    $installerProcessName -match 'python-\d.\d+'
    $pythonVersion = ($Matches[0] -Replace "python-", "") -Replace "\.", ""
    $pythonExe = Join-Path $env:PROGRAMFILES "/Python${pythonVersion}/python.exe"
    
    New-Item $venvRoot -ItemType Directory -Force
    Push-Location -Path $venvRoot
    & $pythonExe -m venv $venvName
    Copy-Item "./${venvName}/Scripts/python.exe" "./${venvName}/Scripts/python_venv_${venvName}.exe" #.py�t�@�C�������z����python.exe�Ɋ֘A�t������悤�ʖ��ŃR�s�[
    Pop-Location # ���̃t�H���_�[�ɖ߂�    
}


function Install-Packages{
    Param(
        [String]$venvRoot,  #���z���̃C���X�g�[����
        [String]$venvName   #���z����
    )
    
    # ���z����activate
    & (Join-Path $venvRoot ($venvName + '\Scripts\Activate.ps1'))
    
    # �p�b�P�[�W�C���X�g�[��
    $packages = (Join-Path $PSScriptRoot '.\packages') # �ϐ��ɂ��Ȃ� or �Ō��\�������pip install�Ɏ��s����
    $requirements = (Join-Path $PSScriptRoot '.\settings\requirements.txt')
    python -m pip install `
        --force `
        --no-index --find-links=$packages `
        --requirement $requirements 
}


function Install-XlwingsAddin{
    Param(
        [String]$venvRoot,  #���z���̃C���X�g�[����
        [String]$venvName   #���z����
    )
    
    # ���z����activate
    & (Join-Path $venvRoot ($venvName + '\Scripts\Activate.ps1'))
    
    
    # Excel���I��
    $ErrorActionPreference = "silentlycontinue"
    Stop-Process -Name Excel -force
    $ErrorActionPreference = "continue"
    
    # xlwings�A�h�C�� �C���X�g�[��
    xlwings addin install
    xlwings config create --force
    $xlwingsConf = (Join-Path $env:USERPROFILE \.xlwings\xlwings.conf)       
    Add-Content -Path $xlwingsConf -Value '"SHOW CONSOLE","True"'       
    Add-Content -Path $xlwingsConf -Value '"USE UDF SERVER","True"'    
}


function Invoke-Main{
    # �ݒ�
    $settings = Join-Path $PSScriptRoot './settings/installation_settings.json' | Resolve-Path | Get-Content -Encoding UTF8 -Raw | ConvertFrom-Json
    $installer = Resolve-Path (Join-Path $PSScriptRoot ('./installer/' + $settings.installer))
    $venvRoot = $settings.venvRoot # ���z���C���X�g�[����t�H���_�[
    $venvName = $settings.venvName # ���z����


    # �J�n���b�Z�[�W
    Write-Host ((
        'Python����уp�b�P�[�W���C���X�g�[�����܂��B',
        '�C���X�g�[���Ώۂɉ�����1�`5����͂��Ă��������B',
        '�i1�A2�͊Ǘ��Ҍ������K�v�ł��j',
        '    1: �ȉ���2�`4',
        '    2: Python�{��',
        '    3: ���z���ibase:venv�j�쐬',
        '    4: Python�p�b�P�[�W',
        '    5: xlwings�A�h�C��',
        '    ����ȊO: �C���X�g�[�����~'
    ) -join "`n")


    # �C���X�g�[��
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


    # �I�����b�Z�[�W
    if ($target -in @(1, 2, 3, 4, 5)){
        Write-Host '�C���X�g�[�����I�����܂����B'
    }
    Write-Host '�I������ɂ͔C�ӂ̃L�[�������Ă��������B'
    Read-Host   
}


# Python��if __name__ == '__main__': �I��
If ((Resolve-Path -Path $MyInvocation.InvocationName).ProviderPath -eq $MyInvocation.MyCommand.Path) {
    Invoke-Main
}
