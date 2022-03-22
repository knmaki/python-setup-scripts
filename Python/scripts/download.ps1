#以下のコマンドでダウンロードする
#Set-ExecutionPolicy Bypass -Scope process

# TODO: platform、python-versionを指定するとバイナリーのダウンロードしかできない
# この場合、xlwingsなど、ソース（xlwings本体）とバイナリ（pywin32）が混ざっていると
# ソースがダウンロードできないのでエラーとなり、--destに（バイナリーだけ出力して欲しいが）
# 何も出力されない。依存関係のバイナリー パッケージをrequirements.txtで個別に指定すると
# 依存関係に依っては複雑になり過ぎるため、行っていない。

$packages = (Join-Path $PSScriptRoot '..\packages')
$requirements = (Join-Path $PSScriptRoot '..\settings\requirements.txt')
python -m pip download --dest=$packages --requirement $requirements
