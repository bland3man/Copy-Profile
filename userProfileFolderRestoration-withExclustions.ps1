# Prompt for source PC, destination PC, and user to restore
$sourcePC = Read-Host "Enter source PC name or IP address"
$destinationPC = Read-Host "Enter destination PC name or IP address"
$userToRestore = Read-Host "Enter the user to restore"

# Normalize input to lowercase
$userToRestore = $userToRestore.ToLower()

# Define source and destination paths
$sourceBackupPath = "\\$sourcePC\C$\$userToRestore-BACKUP\$userToRestore"
$destinationPath = "\\$destinationPC\C$\Users\$userToRestore"

# Define files and directories to exclude
$excludeList = @(
    "*ntuser.dat*",                # Exclude ntuser.dat files
    "*config*",                    # Exclude configuration files
    "*database*",                  # Exclude database files
    "*system*",                    # Exclude system files
    "Temp",                        # Exclude Temp folder
    "Cache",                       # Exclude Cache folder
    "NTUSER.DAT*",                 # Exclude NTUSER.DAT files
    "UsrClass.dat*",               # Exclude UsrClass.dat files
    "Desktop.ini",                 # Exclude Desktop.ini file
    "Thumbs.db",                   # Exclude Thumbs.db file
    "AppData\Local\Temp",          # Exclude Temp folder in AppData\Local
    "AppData\Local\Microsoft\Windows\Temporary Internet Files",   # Exclude Temporary Internet Files
    "AppData\Local\Microsoft\Windows\WER",                        # Exclude Windows Error Reporting
    "AppData\Local\Microsoft\Windows\Caches",                     # Exclude Caches folder
    "AppData\Local\Microsoft\Windows\WebCache",                   # Exclude WebCache folder
    "AppData\Roaming\Microsoft\Windows\Recent"                    # Exclude Recent folder
)

# Function to move files and folders using robocopy
function Move-UserFiles {
    param (
        [string]$source,
        [string]$destination
    )

    robocopy "$source" "$destination" /E /XJ /COPYALL /XD $excludeList /R:0 /W:0 /XO
}

# Validate source and destination paths
if (-not (Test-Path $sourceBackupPath)) {
    Write-Host "Source backup path '$sourceBackupPath' not found or inaccessible. Please check the path and try again."
    exit
}

if (-not (Test-Path $destinationPath)) {
    Write-Host "Destination path '$destinationPath' not found or inaccessible. Please check the path and try again."
    exit
}

# Confirm details before proceeding
Write-Host "Source PC: $sourcePC"
Write-Host "Destination PC: $destinationPC"
Write-Host "User to restore: $userToRestore"
$confirm = Read-Host "Confirm the details above and proceed? (Y/N)"
if ($confirm -ne "Y") {
    Write-Host "Operation aborted."
    exit
}

# Move user data to the new profile preserving permissions and structure
Move-UserFiles -source $sourceBackupPath -destination $destinationPath
