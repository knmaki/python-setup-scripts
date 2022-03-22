# Windows向けPython & Visual Studio Codeセットアップ スクリプト

## 1. 概要
### 1.1. こんな人向け
- 社内でPythonを広めたいけど、1台ずつ環境構築するのがめんどい。
- 一発で色々インストールできるAnacondaは、[有償化](https://qiita.com/tfukumori/items/f8fc2c53077b234384fc)したため使えない。
- インストール対象のPCがインターネットにつながってないため、`pip install`が使えない。
- 利用者のPython/VSCode環境を揃えたい。
- 一度なんとか環境構築したけど、更新のために複数端末でまた同じ作業をするのは萎える（自分でやってくれないし）。
  
そんな感じで困った人向けのスクリプト。

### 1.2. 前提
このツールは以下の環境で利用を前提とする:

- OSはWindows
- インストール先はスタンドアローンPC（インターネットにつながっていない/非ブラウザ通信が遮断）
- 情シスからスタンドアローンPCでのアドミン権限付きアカウントの利用が（一時的に）許可されている
- スタンドアローンPCでのPowerShellの実行が可能（情シスがPCに制限をかけている場合がある）

### 1.3. できること
以下を自動で実行する:

- Pythonのインストール（要アドミン権限）
- Python仮想環境の作成 & 作成した仮想環境へのパッケージのインストール / 更新
- VSCodeのインストール（要アドミン権限（初回のみ））/ 更新
- VSCode拡張機能のインストール / 更新

## 2. セットアップの準備（配布者向け）
インストーラー等のダウンロードが必要になるため、インターネットが使えるPC（OSはWindows）に本リポジトリをクローンし以下の作業を行う。全部終わらせたら、すべてのファイルを非配布者のPCにコピーして3.に進む。
### 2.1. Python
- Pythonインストーラー: 
  1. [配布元](https://www.python.org/downloads/windows/)からダウンロードし、`root/Python/installer`に配置。
  2. `root/Python/settings/installation_settings.json`の各値を更新。
     - `installer`: インストーラーのファイル名
     - `venvRoot`: 仮想環境のルート フォルダーを絶対パスで指定。標準ユーザー権限で読み書きできる場所にしておくのがおすすめ。
     - `venvName`: この名前の仮想環境を`venvRoot`下に作成
- Pythonパッケージ: 
  1. Pythonインストーラーと同じバージョンのPythonをインストール。
  2. `root/Python/settings/requirements.txt`で、仮想環境にインストールするパッケージを編集。このファイルはインストール用スクリプト等で[`pip download -r`](https://pip.pypa.io/en/stable/cli/pip_download/#cmdoption-r)/[`pip install -r`](https://pip.pypa.io/en/stable/cli/pip_install/#cmdoption-r)の引数として使用。書き方は[ドキュメント](https://pip.pypa.io/en/stable/reference/requirements-file-format/)を参照。
  3. `root/Python/packages`内のファイルを削除
  4. `root/Python/PowerShell(ps1実行可).lnk`からPowershellを起動し`root/Python/scripts/download.ps1`を実行し、パッケージ インストーラー（`.whl`ファイルとか）をダウンロード。ちなみに`root/Python/PowerShell(ps1実行可).lnk`は`powershell.exe`に起動オプション`-ExecutionPolicy Bypass`を追加したもの。

- 共通設定: 
  1. `root/Python/scripts/profile.ps1`: PowerShell起動時に実行されるスクリプト。ユーザーが使いやすいようなコマンドレットを追加するためのもの。（あれば）既存の`$PSHome/profile.ps1`を上書きするため、不要であれば`root/Python/install.ps1`の`Install-Python`関数から該当部分を削除。

### 2.2. VSCode
- VSCodeインストーラー
  1. [配布元](https://code.visualstudio.com/download)からzip版をダウンロードし、`root/VSCode/installer`に配置。
  2. `root/VSCode/settings/installation_settings.json`の各値を更新
     - `installer`: インストーラーのファイル名。初期値`"VSCode-win32-x64-*.zip"`は、`root/VSCode/installer`フォルダー内の最新版を取得する（Pythonの[`Path.glob`関数](https://docs.python.org/ja/3/library/pathlib.html#pathlib.Path.glob)で取得したPathのリストの最後のやつ）。
     - `dest_folder`: VSCodeのインストール先。標準ユーザー権限で読み書きできる場所にしておくのがおすすめ。
- VSCode拡張機能
  1. [配布元](https://marketplace.visualstudio.com/)からダウンロードし、`root/VSCode/extensions`に配置。VSCodeから直接インストールする場合には、依存パッケージも自動的にインストールされる（Python拡張機能をインストールすればPylanceも自動的に）が、ダウンロードは全て個別に行う必要がある。また、C/C++拡張機能のように、マーケットプレイスからではなく、GitHubから取得しなければならないものもあるため注意すること（どれがそうなのかはやってみないと分からない）。
  2. `root/VSCode/settings/extension-list.txt`に対象拡張機能を記載。`#`でコメント アウト可。
- 共通設定
  1. `root/VSCode/Python.lnk`: python.exeのショートカット。リポジトリ内に最初からあるものはPython 3.9のものであるためPythonのバージョンに合わせて修正すること。
  1. `root/VSCode/settings/settings.json`: チームで共有したい設定があればここに記載。
     - 初回インストール時: この`settings.json`をユーザーの設定として取り込む。
     - 2回目以降: 既存の`settings.json`に項目がなければ追加、あれば値を上書き（値がリストの場合は追加）。
  2. `root/VSCode/patch/00-vscode_attach_PID.ipy`: ipython起動時のスクリプト。インストール時に`%USERPROFILE%/.ipython/profile_default/startup`にコピーされる。デフォルトではJupyter Notebookに自動アタッチするための処理が書かれており、C++等Pythonスクリプト以外からの自動アタッチに必要。Pythonスクリプトからしかアタッチしなければ不要なので、空ファイルにする（そのままでも良い）。（Jupyter Notebookへの自動アタッチについては[こちら](https://qiita.com/k_maki/items/475f6be71279cffdd909#4-%E3%82%82%E3%81%A3%E3%81%A8%E8%87%AA%E5%8B%95%E3%81%A7%E3%82%A2%E3%82%BF%E3%83%83%E3%83%81)を参照。PythonスクリプトからJupyter Notebookへの自動アタッチは2021年のJupyter拡張機能の更新で取り込まれたけど、[C++からアタッチする場合](https://qiita.com/k_maki/items/75bf05e4159be92c0bd9)はまだ使えるので残している。）
  3. `root/VSCode/patch/add_context_menu.reg`: コンテキスト メニュー(エクスプローラーで右クリックした時に出るやつ)にVSCodeを追加するためのレジストリー設定。zip版VSCodeのインストールでは、コンテキスト メニューにVSCodeが追加されないため、レジストリーを編集して追加する。更新不要（VSCodeへのパスは `root/VSCode/settings/installation_settings.json` から読み込むため）。
  4. `root/VSCode/patch/code.ps1`: 拡張機能インストール時に`VSCodeインストール先/bin/code.cmd`の代わりに使うためのPowerShellスクリプト。情シスから`.cmd`ファイルや`.bat`ファイルが制限されることってあるよね。
  5. `root/VSCode/patch/delete_context_men.reg`: インストール時には使わない。アンインストール時に使用。


## 3. セットアップの方法（被配布者向け）
2.で準備したファイル一式をインストール対象のPCにコピーして以下を行う。
### 3.1. Python
1. アドミン権限のアカウントでWindowsにログイン
2. `root/Python `フォルダーを開き、`install.ps1`を`Powershell(ps1実行可).lnk`にドラッグ&ドロップ
3. `1`を入力しエンター → Python本体インストール、仮想環境作成、仮想環境へのパッケージのインストール

2回目以降、パッケージの更新だけであればアドミン権限は不要。その場合、自分のアカウント（標準ユーザー）でWindowsにログインし、3.で`4`を入力しエンター → 仮想環境のパッケージ更新

<br>

[xlwings](https://docs.xlwings.org/ja/latest/index.html)のExcelアドインをインストールする場合には以下も実行（アドミン権限は不要）
1. 自分のアカウント（標準ユーザー）でWindowsにログイン
2. `root/Python `フォルダーを開き、`install.ps1`を`Powershell(ps1実行可).lnk`にドラッグ&ドロップ
3. `5`を入力しエンター → xlwingsのアドインがExcelにインストールされる

### 3.2. VSCode
Pythonインストール後に作業。
1. アドミン アカウントでWindowsにログイン
2. VSCodeフォルダーを開き、`install.py`を`Python.lnk`にドラッグ&ドロップ。
3. `1`を入力しエンター → VSCode本体インストール、コンテキストメニュー追加、拡張機能のインストール
4. 自分のアカウントでWindowsにログイン
5. 再度、VSCodeフォルダーを開き、`install.py`を`Python.lnk`にドラッグ&ドロップ
6. `5`を入力しエンター → 各種設定が取り込まれる

2回目以降、VSCodeおよび拡張機能の更新だけであればアドミン権限は不要。その場合、自分のアカウント（標準ユーザー）でWindowsにログインし、3.で`2`～`4`のいずれかを入力しエンター → VSCode本体 and/or 拡張機能の更新

### 3.3. 利用時のヒント
- インストール後はVSCode上のPowerShellで仮想環境（`base:venv`）が有効になる。
また、コマンド`Activate-Venv base`で有効にすることもできる（コマンド`Activate-Venv base`はショートカット`PowerShell(ps1実行可)`から起動した場合も利用可）。
- VSCode内のPowerShellで仮想環境が有効となっていない場合には、Python拡張機能が有効な状態で`Ctrl+Shift+@`を押せば、仮想環境が有効なPowershellを開くことができる。


## 4. アンインストール（被配布者向け）
### 4.1. Python
通常どおり、Windowsの機能からアンインストール。

### 4.2. VSCode
インストール先のフォルダーを削除。コンテキスト メニューにVSCodeは`root/VSCode/patch/delete_context_menu.reg`を実行し削除。
