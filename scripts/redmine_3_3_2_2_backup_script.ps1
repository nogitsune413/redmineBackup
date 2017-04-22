# ---  ヘルパー関数  ---

function initializeFolders ($settings) {
    makeFolderIfNotExists (Join-Path $settings.bkRoot work)
    makeFolderIfNotExists (Join-Path $settings.bkRoot backup_files)
    makeFolderIfNotExists ($settings.mir)
}

function makeFolderIfNotExists($path){
    if(-not (Test-Path $path)){
        New-Item $path -ItemType Directory
    }
}

# ---  初期化  ---

# アクセスするリソースのパスをINIファイルから読み込みます。
$s = Get-Content (Split-Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent | Join-Path -ChildPath config\settings.ini) | ConvertFrom-StringData

# 処理対象となるフォルダを作成します。
initializeFolders($s)


# ---  バックアップ  ---

# 添付ファイルが格納されているfilesフォルダをworkフォルダにコピーします。
Copy-Item -Path $s.files -Destination (Join-Path $s.bkRoot work) -Recurse

# mySqlに格納されているデータをworkフォルダに取得します。
Start-Process -NoNewWindow `
              -FilePath $s.mysqldump `
              -ArgumentList ("--user=" + $s.user), `
                            ("--password=" + $s.password), `
                            ("--host=" + $s.host), `
                            ("--port=" + $s.port), `
                            ("--result-file=" + (Join-Path $s.bkRoot $s.resultFile)), `
                            ("--log-error=" + (Join-Path $s.bkRoot $s.logError)), `
                            $s.dbname `
              -Wait

# 取得したバックアップデータを圧縮します。
Start-Process -NoNewWindow -FilePath $s._7zip -ArgumentList a,-sdel,(Join-Path $s.bkRoot work\redmineBackup.7z),(Join-Path $s.bkRoot work\files),(Join-Path $s.bkRoot work\databaseBackUp.sql) -Wait

# バックアップファイルの末尾に日付を付加します。
$backUpFile = "redmineBackup_" + (Get-Date -Format "yyyy-MMdd-HHmmss") + ".7z"
Rename-Item (Join-Path $s.bkRoot work\redmineBackup.7z) -NewName $backUpFile

# バックアップデータを保管用フォルダに移動します。
Move-Item -Path (Join-Path $s.bkRoot work | Join-Path -ChildPath $backUpFile)  -Destination (Join-Path $s.bkRoot backup_files)

# 4世代以前のバックアップファイルを削除します。
Get-ChildItem (Join-Path $s.bkRoot backup_files) |
Sort-Object CreationTime -Descending |
Select-Object -Skip 3 |
foreach{Remove-Item -Path $_.FullName}


# ---  ミラーリング  ---

# バックアップファイルを外付けHDDとミラーリングします。
if((Get-ChildItem (Join-Path $s.bkRoot backup_files) | Measure-Object).Count -ne 0){ # 万が一、コピー元が空で同期してしまうと、コピー先のファイルが全部消えるので。
    ROBOCOPY (Join-Path $s.bkRoot backup_files) $s.mir /MIR
}