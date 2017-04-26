# ---  ヘルパー関数  ---

function initializeFolders ($bkroot,$settings) {
    createFolderIfNotExists (Join-Path $bkroot work)
    createFolderIfNotExists (Join-Path $bkroot log)
    createFolderIfNotExists (Join-Path $bkroot backup_files)
    createFolderIfNotExists $settings.mir
}

function createFolderIfNotExists($path){
    if(-not (Test-Path $path)){
        New-Item $path -ItemType Directory
    }
}

function getBackUpFileName($filenameExtension){
    return "redmineBackup_" + (Get-Date -Format "yyyy-MMdd-HHmmss") + "." + $filenameExtension
}

# ---  初期化  ---

# プログラムのルートフォルダを取得します。
$bkRoot = Split-Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent

# アクセスするリソースのパスをINIファイルから読み込みます。
$s = Get-Content (Join-Path $bkRoot config\settings.ini) | ConvertFrom-StringData

# 処理対象となるフォルダを作成します。
initializeFolders $bkRoot $s

# ---  バックアップ  ---

# 添付ファイルが格納されているfilesフォルダをworkフォルダにコピーします。
Copy-Item -Path $s.files -Destination (Join-Path $bkRoot work) -Recurse

# mySqlに格納されているデータをworkフォルダに取得します。
Start-Process -NoNewWindow `
              -FilePath $s.mysqldump `
              -ArgumentList ("--defaults-file=" + (Join-Path $bkRoot config\mysqldump-options.ini)) , `
                            ("--result-file=" + (Join-Path $bkRoot work\databaseBackUp.sql)), `
                            ("--log-error=" + (Join-Path $bkRoot log\dumpMySqlDataError.log)), `
                            $s.dbname `
              -Wait

# 取得したバックアップデータを圧縮します。
$backUpFile = getBackUpFileName "7z"
Start-Process -NoNewWindow `
              -FilePath $s._7zip `
              -ArgumentList a, `
                            -sdel, `
                            (Join-Path $bkRoot work | Join-Path -ChildPath $backUpFile), `
                            (Join-Path $bkRoot work\files), `
                            (Join-Path $bkRoot work\databaseBackUp.sql) `
              -Wait

# バックアップデータを保管用フォルダに移動します。
Move-Item -Path (Join-Path $bkRoot work | Join-Path -ChildPath $backUpFile) -Destination (Join-Path $bkRoot backup_files)

# 4世代以前のバックアップファイルを削除します。
Get-ChildItem (Join-Path $bkRoot backup_files) |
Sort-Object CreationTime -Descending |
Select-Object -Skip 3 |
foreach{Remove-Item -Path $_.FullName}


# ---  ミラーリング  ---

# バックアップファイルを外付けHDDとミラーリングします。
if((Join-Path $bkRoot backup_files | Get-ChildItem | Measure-Object).Count -ne 0){ # 万が一、コピー元が空で同期してしまうと、コピー先のファイルが全部消えるので。
    ROBOCOPY (Join-Path $bkRoot backup_files) $s.mir /MIR
}