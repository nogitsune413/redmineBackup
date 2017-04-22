## 概要
Redmineのデータをバックアップする、Power Shellスクリプトです。

## 機能
1. 以下のデータをバックアップします。
- 画像ファイルが入っている「files」フォルダ
- その他のデータが格納されているMySQLのDB

2. 外付けHDDとミラーリングし、データを2箇所で保持します。

## 運用
Windowsのタスクスケジューラを使って、定期的にバックアップを実行します。

## 使用方法

### 前提
以下がインストールされていること
- Redmine：Bitnamiのオールインワン・パッケージ
- 7-zip

### 準備
#### MySqlへのログイン情報を設定する。

redmineのデータが入っているmysqlのDBをダンプするには、DBにアクセスするためのユーザID/パスワードが必要になります。
このアカウント情報は、以下に記述されています。

C:\Bitnami\redmine_3_3_2_2\apps\redmine\htdocs\config\database.yml
```ファイル
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

config\settings.ini

#### 処理対象フォルダとコマンドラインツール(EXEファイル)のパスを設定する。

設定ファイルに記述します。

config\setteings.ini

#### タスクスケジューラへの登録

このプログラムは、タスクスケジューラに登録し、定期的に実行する事を想定しています。
タスクスケジューラでは、以下のように登録します。

```
【操作の編集】
操作：プログラムの開始
プログラム/スクリプト：%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe
引数の追加(オプション)：-Command "C:\Bitnami\redmineBackup\scripts\redmine_backup.ps1"
```

### 実行
タスクスケジューラから実行します。

## フォルダ構成
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
