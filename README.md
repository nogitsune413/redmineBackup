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

設定ファイルのテンプレートが以下にあるので、コピーしてファイル名から「-template」を削除し、保存します。

- 設定ファイルのテンプレート
```
[当アプリの設定ファイルのテンプレート]
config/settings-template.ini 

[ダンプツールmysqldump.exeのオプションファイルのテンプレート]
config/mysqldump-options-template.ini
```

- 作成する設定ファイル
```
[当アプリの設定ファイル]
config/settings.ini

[ダンプツールmysqldump.exeのオプションファイル]
config/mysqldump-options.ini
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

この情報をオプションファイルに追記します。

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
タスクスケジューラから実行します。<br />
初回実行時、アプリのルートフォルダ直下に、以下のフォルダを作成します。

- work
- log
- backup_files

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
        │      mysqldump-options.ini
        │
        ├─log
        │      dumpMySqlDataError.log
        │      redmineBackup.log
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

## 補足
圧縮には、Power ShellのCompress-Archive関数を使っても良いと思いますが、Compress-Archive関数のバグを報告するWebサイトの記事をいくつか見かけたので、今回は7-zipを使って実装しました。
簡単なプログラムですので、標準関数であるCompress-Archiveを使いたい方は、Power Shell内に書かれた、圧縮処理のコードを書き換えてください。

【バグを報告しているサイト】<br />
[powershellのcompress-archiveコマンドで作成したzipに潜むちょっとした罠](http://qiita.com/noranuk0/items/cb9de67bfc269391bf6e)<br />
[これで解消！「KB2704299」でCompress-Archiveの文字化け対処](https://cheshire-wara.com/powershell/ps-column/compress-archive-resolved/)

## 動作環境
Power Shell 5.1<br />
7-zip 16.04<br />
Bitnami Redmine Stack 3.3.2-2<br />
&nbsp;&nbsp;&nbsp;・Redmine 3.3.2<br />
&nbsp;&nbsp;&nbsp;・MySQL 5.6.35<br />
windows 10 Home
