## 概要
Redmineのデータをバックアップする、Power Shellスクリプトです。

## 機能
1. 以下のデータをバックアップします。
- 画像ファイルが入っている「files」フォルダ
- その他のデータが格納されているMySQLのDB

2. 外付けHDDとミラーリングし、データを2箇所で保持します。

## 想定している運用
Windowsのタスクスケジューラを用いた、定期的なバックアップ。<br />
ただし、ここにUPされているスクリプトには、タスクスケジューラの情報は含まれていません。<br />
スクリプトを実行すると、単に1回バックアップします。

## 使用方法

### 前提
以下がインストールされていること
- Redmine：Bitnamiのオールインワン・パッケージ
- 7-zip

### 準備
#### 設定ファイルの作成
##### テンプレートをコピーしてファイルを作成します。

設定ファイルのテンプレートが以下にあるので、コピーしてファイル名をsettings.iniに変更し、保存します。

- 設定ファイルのテンプレート
```
config/settings-template.ini 
```
- 作成する設定ファイル
```
config/settings.ini
```

##### 処理対象フォルダとコマンドラインツール(EXEファイル)のパスを設定します。
Redmineの画像フォルダや、ミラーリング先のバックアップフォルダなどのパス情報を設定ファイルに追記します。

##### MySqlへのログイン情報を設定します。
redmineのデータが入っているmysqlのDBをダンプするには、DBにアクセスするためのユーザID/パスワードが必要になります。
このアカウント情報は、以下に記述されています。
```
(Bitnamiのインストール先)\apps\redmine\htdocs\config\database.yml

production:
  adapter: xxx
  database: xxx
  host: xx.xx.xx.xx
  username: xxx
  password: xxx
  encoding: utf8
  port: xxx
```

この情報を設定ファイルに追記します。

#### タスクスケジューラへの登録

このプログラムは、タスクスケジューラに登録し、定期的に実行する事を想定しています。
タスクスケジューラでは、以下のように登録します。

```
【操作の編集】
操作：プログラムの開始
プログラム/スクリプト：%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe
引数の追加(オプション)：-Command "(当スクリプトの配置先)\redmineBackup\scripts\redmine_backup.ps1"
```

### 実行
タスクスケジューラから実行します。

## フォルダ構成例
```
【内蔵HDD】
C:
└─Bitnami
    └─redmineBackup
        ├─backup_files
        │      redmineBackup_YYYY-MMDD-HHMMSS.7z
        │      redmineBackup_YYYY-MMDD-HHMMSS.7z
        │      redmineBackup_YYYY-MMDD-HHMMSS.7z
        │
        ├─config
        │      settings.ini
        │
        ├─log
        │      dumpMySqlDataError.log
        │      
        ├─scripts
        │      redmine_backup.ps1
        │          
        └─work

【外付けHDD】
E:
└─Bitnami
    └─redmine_data_backup
            redmineBackup_YYYY-MMDD-HHMMSS.7z
            redmineBackup_YYYY-MMDD-HHMMSS.7z
            redmineBackup_YYYY-MMDD-HHMMSS.7z
```
