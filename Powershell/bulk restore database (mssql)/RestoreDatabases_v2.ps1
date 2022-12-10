#----------------------------------------- FOLDER PATHS & PATTERNS -----------------------------------#
#$backup_path = "D:\backup\Bonpara Backup\Tue\";
$sql_type = "MSSQLSERVER"; #TYPES: 1.MSSQLSERVER 2.SQLEXPRESS
$mssql_path_64 = "C:\Program Files\Microsoft SQL Server\MSSQL15.$($sql_type)\MSSQL\DATA";
$mssql_path_86 = "C:\Program Files (x86)\Microsoft SQL Server\MSSQL15.$($sql_type)\MSSQL\DATA";

#Find files that starts with CCULB and ends with .mdf; #Another Pattern: A2Z*.mdf
$pattern_backup_bak = "CCULB*.BAK"; #Can also replace with A2Z*.mdf
$pattern_backup_mdf = "CCULB*.mdf"; #Can also replace with A2Z*.mdf
$backup_type = "mdf"; #TYPES: 1.mdf 2.bak
#-----------------------------------------------------------------------------------------------------#

WRITE-HOST "-----------------------------------------------------------------------------------" -ForegroundColor Green;
WRITE-HOST "# You can change the MSSQL folder paths in the powershell script file.(IF Needed!) " -ForegroundColor Green;
WRITE-HOST "# You have to change file name pattern in the script file. Default is CCULB*.mdf   " -ForegroundColor Green;
WRITE-HOST "-----------------------------------------------------------------------------------" -ForegroundColor Green;
WRITE-HOST "";
WRITE-HOST "";

function exit_program {
    param(
        $time
    )
    $close = $time;
    WRITE-HOST "";
    WRITE-HOST "QUIT IMMEDIATELY:(CTRL+C)" -BackgroundColor DarkGray;
    WRITE-HOST "CLOSING PROGRAM...IN "$close" SECONDS..." -NoNewline;
    while( $close -ge 1 ){
        WRITE-HOST ' '$close -NoNewline;
        start-sleep -Seconds 1;
        $close -= 1;
    }
    exit;
}

WRITE-HOST "Press enter for bak else type mdf" -BackgroundColor DarkBlue;
$backup_type = Read-Host("Backup File Type(mdf/bak)?").ToLower().Trim();
IF( ($backup_type -ne "mdf") -And ($backup_type -ne "bak") -And ($backup_type -ne "") ){ 
    WRITE-HOST "ERROR: INVALID BACKUP TYPE!" -ForegroundColor White -BackgroundColor DarkRed; exit_program 4;
}
ELSEIF ( $backup_type -eq "" ) {
    $backup_type = "bak";
}
$backup_path = READ-HOST("Enter Backup Folder Path: ");
IF( $backup_path -eq "" ) { $backup_path = $pwd.path; } #IF only enter is given then put current location of the script file.
IF( $backup_path[-1] -ne "\" ){ $backup_path = $backup_path+"\"; }

$backup_path_exists   = TEST-PATH -Path $backup_path;
$mssql_path_64_exists = TEST-PATH -Path $mssql_path_64;
$mssql_path_86_exists = TEST-PATH -Path $mssql_path_86;

IF( $backup_path_exists -eq $false ){ WRITE-HOST "ERROR: THE BACKUP PATH DOESN'T EXIST!" -ForegroundColor White -BackgroundColor DarkRed; exit_program 8; }

$mssql_path = "";
IF( $mssql_path_64_exists -eq $true ) { $mssql_path = $mssql_path_64; } 
ELSE { 
    IF( $mssql_path_86_exists -eq $true ){ $mssql_path = $mssql_path_86;  }
    ELSE { 
        WRITE-HOST "ERROR: MSSQL MAY NOT BE INSTALLED!" -ForegroundColor White -BackgroundColor DarkRed;
        WRITE-HOST "  ---------STEPS TO FIX---------  " -ForegroundColor White -BackgroundColor DarkRed;
        WRITE-HOST "";
        WRITE-HOST "  #1 Install MMSQL";
        WRITE-HOST "";
        WRITE-HOST "  #2 OR Change folder path of the script by right clicking and editing with notepad.";
        WRITE-HOST "     Change both the `$mssql_path_64` and `$mssql_path_86` variable.";
        WRITE-HOST "";
        WRITE-HOST "  #3 OR Try changing the type of `$sql_type` variable";
        exit_program 30; 
    }
}
$mssql_path = $mssql_path + "\"


IF( $backup_type -eq "bak" ){
    #Creating script.txt file and reading file names with extention from the given backup path.
    $list = get-childitem -path $backup_path -filter $pattern_backup_bak -file | ForEach-Object { $_.Name };
    IF( $list.Length -eq 0 ){ WRITE-HOST "ERROR: NO .BAK files found in the given path." -ForegroundColor White -BackgroundColor DarkRed; exit_program 8;  }
    $script_file_path = $pwd.path+'\script.txt'; 
    New-Item $script_file_path | Out-Null;

    #Reading only file names which start with CCULB and has extention of .mdf from MSSQL DATA folder to delete previous database content.
    $dbList = get-childitem -path $mssql_path -filter $pattern_backup_mdf -file | ForEach-Object { $_.Name.split(".")[0] }
    Add-Content $script_file_path "-- ----- DELETE PREVIOUS DATABASE -----";
    foreach($dbName in $dbList){
        add-content $script_file_path "USE [master]";
        add-content $script_file_path "DROP DATABASE [$dbName]";
        add-content $script_file_path "GO";
    }
    Add-Content $script_file_path "";
    Add-Content $script_file_path "";

    Add-Content $script_file_path "-- ----- RESTORE NEW DATABASE -----";
    foreach($file_name in $list){
        $disk_path = $backup_path+$file_name;
        $to_path = $mssql_path+$file_name.split(".")[0];
        add-content $script_file_path "USE [master]";
        add-content $script_file_path "RESTORE DATABASE [$($file_name.split(".")[0])] FROM  DISK = N'$disk_path' ";
        add-content $script_file_path "WITH  FILE = 1,  MOVE N'MyDataBaseName' ";
        add-content $script_file_path "TO N'$($to_path).mdf',";  
        add-content $script_file_path "MOVE N'MyDataBaseName_log' TO N'$($to_path)_log.ldf',  "
        add-content $script_file_path "NOUNLOAD,  STATS = 5"
        add-content $script_file_path "GO"
        Add-Content $script_file_path "";
        Add-Content $script_file_path "";
    }
}ELSE{
    #Creating script.txt file and reading file names with extention from the given backup path.
    $list = get-childitem -path $backup_path -filter $pattern_backup_mdf -file | ForEach-Object { $_.Name };
    IF( $list.Length -eq 0 ){ WRITE-HOST "ERROR: NO .mdf files found in the given path." -ForegroundColor White -BackgroundColor DarkRed; exit_program 8;  }
    $script_file_path = $pwd.path+'\script.txt'; 
    New-Item $script_file_path | Out-Null;

    $dbList = get-childitem -path $mssql_path -filter $pattern_backup_mdf -file | ForEach-Object { $_.Name.split(".")[0] }
    Add-Content $script_file_path "-- ----- DETACH PREVIOUS DATABASE -----";
    foreach($dbName in $dbList){
        add-content $script_file_path "USE [master]";
        add-content $script_file_path "GO";
        add-content $script_file_path "EXEC master.dbo.sp_detach_db @dbname = N'$dbName'";
        add-content $script_file_path "GO";
    }
    Add-Content $script_file_path "";
    Add-Content $script_file_path "";

    Add-Content $script_file_path "-- ----- ATTACH NEW DATABASE -----";
    foreach($file_name in $list){
        $disk_path = $backup_path+$file_name;
        $to_path = $mssql_path+$file_name.split(".")[0];
        Add-Content $script_file_path "USE [master]";
        Add-Content $script_file_path "GO";
        Add-Content $script_file_path "CREATE DATABASE [$($file_name.split(".")[0])] ON ";
        Add-Content $script_file_path "( FILENAME = N'$($to_path).mdf' ),";
        Add-Content $script_file_path "( FILENAME = N'$($to_path)_log.ldf' )";
        Add-Content $script_file_path "FOR ATTACH";
        Add-Content $script_file_path "GO";
        Add-Content $script_file_path "";
        Add-Content $script_file_path "";
    }
}

Get-Content $script_file_path | Set-Clipboard;
Remove-Item $script_file_path;

WRITE-HOST "";
WRITE-HOST " ------------------------------------------------------------------ " -ForegroundColor White -BackgroundColor DarkGreen;
WRITE-HOST "| SUCCESS! SCRIPT COPIED TO CLIPBOARD.(JUST PASTE IT OR DO CTRL+V) |" -ForegroundColor White -BackgroundColor DarkGreen;
WRITE-HOST " ------------------------------------------------------------------ " -ForegroundColor White -BackgroundColor DarkGreen;
WRITE-HOST "";

exit_program 10;






























