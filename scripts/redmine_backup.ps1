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

function deleteFileIfExists($path){
    if(Test-Path $path){
        Remove-Item $path
    }
}

function getBackUpFileName($filenameExtension){
    return "redmineBackup_" + (Get-Date -Format "yyyy-MMdd-HHmmss") + "." + $filenameExtension
}

function log($message, $bkroot){
    Write-Output $message
    Write-Output ((Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "  " + $message) | Out-File (Join-Path $bkRoot log\redmineBackup.log) -Encoding utf8 -Append
}

# ---  初期化  ---

# プログラムのルートフォルダを取得します。
$bkRoot = Split-Path $MyInvocation.MyCommand.Path -Parent | Split-Path -Parent

# アクセスするリソースのパスをINIファイルから読み込みます。
$s = Get-Content (Join-Path $bkRoot config\settings.ini) | ConvertFrom-StringData

# 処理対象となるフォルダを作成します。
initializeFolders $bkRoot $s

# 古いログファイルがあれば削除します。
deleteFileIfExists (Join-Path $bkRoot log\redmineBackup.log)

# ---  バックアップ  ---

log "添付ファイルが格納されているfilesフォルダをworkフォルダにコピーします。" $bkRoot
Copy-Item -Path $s.files -Destination (Join-Path $bkRoot work) -Recurse

log "mySqlに格納されているデータをworkフォルダに取得します。" $bkRoot
Start-Process -NoNewWindow `
              -FilePath $s.mysqldump `
              -ArgumentList ("--defaults-file=" + (Join-Path $bkRoot config\mysqldump-options.ini)) , `
                            ("--result-file=" + (Join-Path $bkRoot work\databaseBackUp.sql)), `
                            ("--log-error=" + (Join-Path $bkRoot log\dumpMySqlDataError.log)), `
                            $s.dbname `
              -Wait

log "取得したバックアップデータを圧縮します。" $bkRoot
$backUpFile = getBackUpFileName "7z"
Start-Process -NoNewWindow `
              -FilePath $s._7zip `
              -ArgumentList a, `
                            -sdel, `
                            (Join-Path $bkRoot work | Join-Path -ChildPath $backUpFile), `
                            (Join-Path $bkRoot work\files), `
                            (Join-Path $bkRoot work\databaseBackUp.sql) `
              -Wait


log "バックアップデータを保管用フォルダに移動します。" $bkRoot
Move-Item -Path (Join-Path $bkRoot work | Join-Path -ChildPath $backUpFile) -Destination (Join-Path $bkRoot backup_files)

log "4世代以前のバックアップファイルを削除します。" $bkRoot
Get-ChildItem (Join-Path $bkRoot backup_files) |
Sort-Object CreationTime -Descending |
Select-Object -Skip 3 |
foreach{Remove-Item -Path $_.FullName}


# ---  ミラーリング  ---


log "バックアップファイルを外付けHDDとミラーリングします。" $bkRoot
if((Join-Path $bkRoot backup_files | Get-ChildItem | Measure-Object).Count -ne 0){ # 万が一、コピー元が空で同期してしまうと、コピー先のファイルが全部消えるので。
    ROBOCOPY (Join-Path $bkRoot backup_files) $s.mir /MIR
}