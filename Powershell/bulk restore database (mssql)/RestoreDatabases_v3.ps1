#---------------------------------------- Permission Check -------------------------------------------#
$permission = Get-ExecutionPolicy;
if( $permission -ne "RemoteSigned" ){
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
}

function exit_program {
    param(
        $time
    )
    $close = $time;
    WRITE-HOST "";
    WRITE-HOST "QUIT IMMEDIATELY:(CTRL+C)" -BackgroundColor DarkGray;
    WRITE-HOST "CLOSING PROGRAM...IN "$close" SECONDS..." -NoNewline;
    while( $close -ge 1 ){
        if( $time -ne 3600 ){
            WRITE-HOST ' '$close -NoNewline;
        }  
        start-sleep -Seconds 1;
        $close -= 1;
    }
    exit;
}

function startTimer {
    $timer = [Diagnostics.Stopwatch]::StartNew();
    return $timer;
}

function stopTimer {
    param(
        $timer
    )
    $timer.Stop();
    write-host "`nDatabase Restored Successfully!" -ForegroundColor Green;
    write-host "Execution time: " $timer.Elapsed;
    exit_program 3600;
}

enum SQLServerType {
    SQLEXPRESS= 0
    MSSQLSERVER= 1
}

function GetSQLServerType {
    $SQLEXPRESS_Service_Display_Name = "SQL Server (SQLEXPRESS)"
    $MSSQLSERVER_Service_Display_Name = "SQL Server (MSSQLSERVER)"
    get-service -Name *SQL* | ForEach-Object {
        if(  $_.DisplayName -eq $SQLEXPRESS_Service_Display_Name ){
            return [SQLServerType]::SQLEXPRESS.ToString();
        }elseif( $_.DisplayName -eq $MSSQLSERVER_Service_Display_Name ){
            return [SQLServerType]::MSSQLSERVER.ToString();
        }
    }
    return $null;
}

function GetSQLServerName {
    $type = GetSQLServerType;
    if( $type -eq  [SQLServerType]::SQLEXPRESS ){
        return "$(hostname)\SQLEXPRESS";
    }elseif( $type -eq  [SQLServerType]::MSSQLSERVER ){
        return "(local)";
    }else{
        write-host "Please start SQL Server Service." -ForegroundColor White -BackgroundColor DarkRed; 
        exit_program 30;
        #return $null;
    }
}

$pattern_backup_bak = "*.BAK";
$pattern_backup_mdf = "*.mdf";
$SQLServerType = GetSQLServerType;
$ServerName = GetSQLServerName;
$DbName = "master";
function run_query {
    param(
        $query
    )
    try{ 
        $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DbName -Query $query -QueryTimeout 0 -Verbose -ErrorAction Stop -ConnectionTimeout 0;
        return $result;
    }catch{
        write-host "Something went wrong. Could not execute query!" -ForegroundColor White -BackgroundColor DarkRed;
        #write-host "Caught an exception:" -ForegroundColor DarkRed
        #write-host "Exception type: $($_.Exception.GetType().FullName)" -ForegroundColor DarkRed
        write-host "Exception message: $($_.Exception.Message)" -ForegroundColor DarkRed
        #write-host "Error: " $_.Exception -ForegroundColor DarkRed
        exit_program 3600;
    }
}

function run_query_ignore_errors {
    param(
        $query
    )
    try{ 
        $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DbName -Query $query -QueryTimeout 0 -Verbose -ErrorAction Continue -ConnectionTimeout 0 2>$null;
        return $result;
    }catch{
        write-host "Something went wrong..could not execute query." -ForegroundColor White -BackgroundColor DarkRed;
        #write-host "Caught an exception:" -ForegroundColor DarkRed
        write-host "Exception type: $($_.Exception.GetType().FullName)" -ForegroundColor DarkRed
        write-host "Exception message: $($_.Exception.Message)" -ForegroundColor DarkRed
        #write-host "Error: " $_.Exception -ForegroundColor DarkRed
        exit_program 3600;
    }
}

function delete_existing_database {
    $query = "SELECT name FROM master.sys.databases WHERE database_id > 4";
    $result = run_query $query;
    
    $delete_query = "";
    $result | ForEach-Object {
        $delete_query += " DROP DATABASE [$($_.name)]; `n";
    }

    echo $delete_query;
    if( $delete_query -ne "" ){
        run_query $delete_query;
    }
}

function detach_existing_database {
    $query = "SELECT name FROM master.sys.databases WHERE database_id > 4";
    $result = run_query $query;
    
    $delete_query = "";
    $result | ForEach-Object {
        $delete_query += " EXEC master.dbo.sp_detach_db @dbname = N'$($_.name)'; `n";
    }
    
    echo $delete_query;
    if( $delete_query -ne "" ){
        run_query $delete_query;
    }
}

function get_db_file_from_default_directory {
    param(
        $mssql_path
    )
    $query =  "DECLARE @dirPath nvarchar(500) = '$($mssql_path)' ";
    $query += "DECLARE @tblgetfileList TABLE ";
    $query += "(FileName nvarchar(500) ,depth int,isFile int) ";
    $query += "INSERT INTO @tblgetfileList EXEC xp_DirTree @dirPath,1,1 ";
    $query += "SELECT FileName from @tblgetfileList where isFile=1 and FileName Like '%.mdf'; ";             
    $result = run_query $query;
    return $result;
}

function get_sql_database_path{
    $SQLServerVersion = "";
    run_query "SELECT SERVERPROPERTY('ProductMajorVersion') as Major" | ForEach-Object {
        $SQLServerVersion = $_.Major;
    };
    
    $mssql_path_64 = "C:\Program Files\Microsoft SQL Server\MSSQL$($SQLServerVersion)";
    $mssql_path_64 += ".$($SQLServerType)".trim();
    $mssql_path_64 += "\MSSQL\DATA";

    $mssql_path_86 = "C:\Program Files (x86)\Microsoft SQL Server\MSSQL$($SQLServerVersion)";
    $mssql_path_86 += ".$($SQLServerType)".trim();
    $mssql_path_86 += "\MSSQL\DATA";

    $mssql_path_64_exists = TEST-PATH -Path $mssql_path_64;
    $mssql_path_86_exists = TEST-PATH -Path $mssql_path_86;

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
            exit_program 3600; 
        }
    }
    $mssql_path = $mssql_path + "\"
    return $mssql_path;
}

function restore_database {

    WRITE-HOST "---------------------------------------------------------------------------------------------- " -ForegroundColor Green;
    WRITE-HOST "# If anything goes wrong delete the databases from \DATA Folder of SQL Server then start over. " -ForegroundColor Green;
    WRITE-HOST "# (Ctrl + C) to exit from the console/shell at any moment.                                     " -ForegroundColor Green;
    WRITE-HOST "---------------------------------------------------------------------------------------------- " -ForegroundColor Green;
    WRITE-HOST "";
    WRITE-HOST "";

    WRITE-HOST "Press enter for bak else type mdf" -ForegroundColor DarkCyan;
    $backup_type = Read-Host("Backup File Type(mdf/bak)?").ToLower().Trim();
    IF( ($backup_type -ne "mdf") -And ($backup_type -ne "bak") -And ($backup_type -ne "") ){ 
        WRITE-HOST "ERROR: INVALID BACKUP TYPE!" -ForegroundColor White -BackgroundColor DarkRed; exit_program 30;
    }
    ELSEIF ( $backup_type -eq "" ) {
        $backup_type = "bak";
    }
    IF( $backup_type -eq "mdf" ){
        WRITE-HOST "`n";
        WRITE-HOST "Press enter if .mdf files are already in SQL Server else provide folder path." -ForegroundColor DarkCyan;
    } 
    $backup_path = READ-HOST("Enter Backup Folder Path: ");
    #IF( $backup_path -eq "" ) { $backup_path = $pwd.path; } #IF only enter is given then put current location of the script file.
    IF( $backup_path[-1] -ne "\" ){ $backup_path = $backup_path+"\"; }

    $backup_path_exists = TEST-PATH -Path $backup_path;
    IF( $backup_path_exists -eq $false ){ WRITE-HOST "ERROR: THE BACKUP PATH DOESN'T EXIST!" -ForegroundColor White -BackgroundColor DarkRed; exit_program 30; }

    $mssql_path = get_sql_database_path;
    
    #Database Restore
    IF( $backup_type -eq "bak" ){
        #Creating script.txt file and reading file names with extention from the given backup path.
        $list = get-childitem -path $backup_path -filter $pattern_backup_bak -file | ForEach-Object { $_.Name };
        IF( $list.Length -eq 0 ){ WRITE-HOST "ERROR: NO .BAK files found in the given path." -ForegroundColor White -BackgroundColor DarkRed; exit_program 30;  }
        
        #Delete Existing Databases
        delete_existing_database

        $restore_query = "";
        foreach($file_name in $list){         
            $disk_path = $backup_path+$file_name;
            $to_path = $mssql_path+$file_name.split(".")[0];       
            $restore_query += "RESTORE DATABASE [$($file_name.split(".")[0])] FROM  DISK = N'$disk_path' ";
            $restore_query += "WITH  FILE = 1,  MOVE N'MyDataBaseName' ";
            $restore_query += "TO N'$($to_path).mdf', ";
            $restore_query += "MOVE N'MyDataBaseName_log' TO N'$($to_path)_log.ldf', ";
            $restore_query += "NOUNLOAD,  STATS = 5; ";
            #write-host "`n";
            #write-host "Restoring Database [$($file_name.split(".")[0])].....";
        }
        $timer = startTimer; 
        run_query $restore_query;
        stopTimer $timer;
    }ELSE{ #Database Attachment
        IF ( $backup_type -eq "mdf" -And $backup_path -eq "\" ){ #empty path string will be given "\" (look up for the logic)
             #Detach Database
             detach_existing_database;

             $db_files = get_db_file_from_default_directory $mssql_path;
             $restore_query = "";
             $db_files | ForEach-Object {
                $file_name = $_.FileName;
                $to_path = $mssql_path+$file_name.split(".")[0];
                $restore_query += "CREATE DATABASE [$($file_name.split(".")[0])] ON ";
                $restore_query += "( FILENAME = N'$($to_path).mdf' ), ";
                $restore_query += "( FILENAME = N'$($to_path)_log.ldf' ) ";
                $restore_query += "FOR ATTACH; `n";
             }
             $timer = startTimer; 
             run_query_ignore_errors $restore_query;
             stopTimer $timer;
             exit_program 30;
        }

        #Creating script.txt file and reading file names with extention from the given backup path.
        $list = get-childitem -path $backup_path -filter $pattern_backup_mdf -file | ForEach-Object { $_.Name };
        IF( $list.Length -eq 0 ){ WRITE-HOST "ERROR: NO .mdf files found in the given path." -ForegroundColor White -BackgroundColor DarkRed; exit_program 30;  }

        #Detach Database
        detach_existing_database;

        $restore_query = "";
        foreach($file_name in $list){
            $disk_path = $backup_path+$file_name.split(".")[0];
            $to_path = $mssql_path+$file_name.split(".")[0];
            $restore_query += "CREATE DATABASE [$($file_name.split(".")[0])] ON ";
            $restore_query += "( FILENAME = N'$($disk_path).mdf' ), ";
            $restore_query += "( FILENAME = N'$($disk_path)_log.ldf' ) ";
            $restore_query += "FOR ATTACH; `n";
        }
        $timer = startTimer; 
        run_query $restore_query;
        stopTimer $timer;
    }

    #$query = Get-Content $script_file_path;
    #write-host $query;
    #run_query $query;
}

#delete_existing_database
#detach_existing_database

restore_database
#exit_program 3600