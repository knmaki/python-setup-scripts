import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import textwrap
import traceback
import zipfile


# 設定読み込み
with open(Path(__file__).parent / 'settings/installation_settings.json', 'r') as f:
    settings = json.load(f)
INSTALLER = list((Path(__file__).parent / 'installer').glob(settings['installer']))[-1]
DEST_FOLDER = Path(settings['dest_folder'])


# 各種ファイル
PATCH_FOLDER = Path(__file__).parent / 'patch'
CODE_PS1_PATCH = PATCH_FOLDER / 'code.ps1'
CONTEXT_MENU_PATCH = PATCH_FOLDER / 'add_context_menu.reg'
IPY_STARTUP_PATCH = PATCH_FOLDER / '00-vscode_attach_PID.ipy'

SETTINGS_FOLDER = Path(__file__).parent / 'settings'
EXTENSION_LIST = SETTINGS_FOLDER / 'extension-list.txt'
SETTINGS_PATCH = SETTINGS_FOLDER / 'settings.json'

CODE_PS1 = DEST_FOLDER / 'bin/code.ps1' # パッチファイル適用先



def main_intall_vscode(add_context_menu: bool=True) -> None:
    '''vscodeのインストール

    以下を行う:
        - vscodeのインストール（zipファイル展開）
        - コマンドライン用のcode.ps1のbinフォルダーへのコピー
        - コンテキストメニュー追加（初回のみ必要、要管理者権限）
    
    Args:
        add_context_menu : コンテキストメニューを追加する場合はTrue
    Returns:
        None
    '''

    # vscodeのインストール（zipファイル展開）
    with zipfile.ZipFile(INSTALLER) as zf:
        zf.extractall(DEST_FOLDER) #既存ファイルは上書き
    (DEST_FOLDER / 'data').mkdir(exist_ok=True) # スタンドアローンとして使用するためdataフォルダー作成

    # コマンドライン用のcode.ps1のbinフォルダーへのコピー
    shutil.copy(CODE_PS1_PATCH, CODE_PS1)

    # コンテキストメニュー追加（初回のみ必要、要管理者権限）
    if add_context_menu:
        # ひな形読み込み
        with open(CONTEXT_MENU_PATCH , 'r') as f:
            reg_txt = f.readlines()

        # インストール先に合わせて修正し、一時ファイルに保存
        path_to_vscode = f'{DEST_FOLDER}\\Code.exe'.replace('\\', '\\\\')
        reg_txt_mod = [l.replace('PATH_TO_VSCODE', path_to_vscode) for l in reg_txt]
        context_menu_path_mod = Path(__file__).parent / f'tmp/{CONTEXT_MENU_PATCH.name}'
        context_menu_path_mod.parent.mkdir(exist_ok=True)
        with open(context_menu_path_mod, 'w') as f:
            f.writelines(reg_txt_mod)

        # レジストリ―に反映
        commands = []
        commands.append(f'regedit /I /S {path_to_PSstr(context_menu_path_mod)}')
        run_PS_commands(commands, print_stderr=True)

    # コマンドラインのテスト
    commands = []
    commands.append(f'& {path_to_PSstr(CODE_PS1)} --version')
    run_PS_commands(commands, print_stderr=True)


def main_install_extensions() -> None:
    '''extensionsフォルダーに格納されている拡張機能のインストール

    以下を行う:
        - 拡張機能のインストール
    
    Returns:
        None
    '''


    # 拡張機能インストールファイルの取得
    with open(EXTENSION_LIST, 'r') as f:         
        extension_names = [
            l.split('#')[0].rstrip(' ') 
            for l in f.read().splitlines() 
            if l.find('#') != 0 and len(l.rstrip(' ')) > 0
        ]
    
    extensions = []
    for extension_name in extension_names:
        try:
            extensions.append(
                [
                    f
                    for f in (Path(__file__).parent / 'extensions').iterdir() 
                    if re.match(f'{extension_name}(-\d.*|)\.vsix', f.name)
                ][-1]
            )
        except:
            print(f'Warning: 拡張機能{extension_name}の.vsixファイルの取得に失敗しました。')
            print(traceback.format_exc())


    # 拡張機能のインストール
    for extension in extensions:
        commands = []
        commands.append(
            f'& {path_to_PSstr(CODE_PS1)} '
            + ' --install-extension '
            + f' {path_to_PSstr(extension)} '
            + ' --force'
        )
        run_PS_commands(commands, print_stderr=True)


def main_import_settings() -> None:
    '''設定を取り込む

    以下を行う:
        - 設定（settings.json）の取り込み（patch用settings.jsonに存在するキーは上書き）
        - jupyter notebookデバッグ用のスタートアップ スクリプトの取り込み
    
    Returns:
        None
    '''

    # 設定（settings.json）の取り込み（patch用settings.jsonに存在するキーは上書き）
    settings_to = DEST_FOLDER / 'data/user-data/User/settings.json'
    if settings_to.exists() == False:
        shutil.copy(SETTINGS_PATCH, settings_to)
    else:
        with open(SETTINGS_PATCH, 'r', encoding='utf-8') as f:
            json_from = json.load(f)

        with open(settings_to, 'r', encoding='utf-8') as f:
            json_to = json.load(f)

        json_to = upsert_dict(json_from, json_to)
        with open(settings_to, 'w', encoding='utf-8') as f:
            json.dump(json_to, f, indent=4)

    # jupyter notebookデバッグ用のスタートアップ スクリプトの取り込み
    ipy_startup_folder = Path(os.environ['USERPROFILE']) / '.ipython/profile_default/startup'
    ipy_startup_folder.mkdir(parents=True, exist_ok=True)
    shutil.copy(IPY_STARTUP_PATCH, ipy_startup_folder)


def path_to_PSstr(path: Path) -> str:
    '''PythonのパスをPowershellで使用可能なパスに変換

    Args:
        path: 変換対象のパス
    Returns:
        変換後のパス（バックスラッシュをスラッシュに、文字列全体を'で囲う）
    '''
    return '\'' + str(path.resolve()).replace('\\', '/') + '\''


def run_PS_commands(commands: list, print_stderr: bool=True) -> None:
    '''Powershellでコマンドを実行

    Args:
        commands     : 実行対象のコマンド。リストの要素は実行可能な一つのコマンドとすること。
        print_stderr : エラーの出力要否
    Returns:
        None
    '''

    # プロファイルを読み込めるよう、起動オプションを設定
    one_line_commands = 'powershell.exe -ExecutionPolicy Bypass -Command "& {' + '; '.join(commands) + '}"'   

    # PowerShell.exeへのパスを通す
    path_to_PowerShell = rf'{os.environ["SystemRoot"]}\System32\WindowsPowerShell\v1.0'
    if path_to_PowerShell not in os.environ['path']:
        os.environ['path'] += f';{path_to_PowerShell}'

    # PowerShellでコマンド実行
    proc = subprocess.run(
        one_line_commands, shell=True, env={**os.environ},
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    )
    print(proc.stdout.decode('cp932'))


def upsert_dict(dict_from: dict, dict_to: dict) -> dict:
    '''辞書を更新/追加するための関数

    settins.json更新時に使用する。
    両方の辞書に存在するキーの値について、値の型ごとに
        - 辞書  : 再帰的に呼び出し
        - リスト: dict_fromの値を追加
        - 値    : dict_fromで上書き
    
    Args:
        dict_from : 更新用の辞書
        dict_to   : 更新される辞書
    
    Returns:
        更新後の辞書
    '''
    
    dict_to = dict_to.copy()

    for key in dict_from.keys():
        if key in dict_to.keys():
            if type(dict_to[key])==dict:
                dict_to[key] = upsert_dict(dict_from[key], dict_to[key])
            elif type(dict_to[key])==list:
                for val in dict_from[key]:
                    if val not in dict_to[key]:
                        dict_to[key].append(val)
            else:
                dict_to[key] = dict_from[key]
        else:
            dict_to[key] = dict_from[key]
    
    return dict_to


if __name__ == '__main__':
    # 開始メッセージ
    print(textwrap.dedent(
        '''\
        Visual Studio Codeおよび拡張機能をインストールします。
        インストール対象に応じて1または2を入力してください。
        （1はコンテキストメニューの追加を含むため管理者権限が必要です）
            1: すべて（初回）
            2: すべて（2回目以降）
            3: Visal Studio Code本体
            4: 拡張機能
            5: 設定取り込み
            それ以外: インストール中止\
        '''
    ))


    # インストール
    target = input()
    try:
        if target=='1':
            main_intall_vscode(add_context_menu=True)
            main_install_extensions()
            main_import_settings()
        elif target=='2':
            main_intall_vscode(add_context_menu=False)
            main_install_extensions()
            main_import_settings()
        elif target=='3':
            main_intall_vscode(add_context_menu=False)        
        elif target=='4':
            main_install_extensions()
        elif target=='5':
            main_import_settings()
        print('インストールが終了しました。')
    except:
        print(traceback.format_exc())

    # 終了メッセージ
    print('終了するには任意のキーを押してください。')
    input()
