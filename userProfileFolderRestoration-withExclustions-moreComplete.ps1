# Prompt for source PC, destination PC, and user to restore
$sourcePC = Read-Host "Enter source PC name or IP address"
$destinationPC = Read-Host "Enter destination PC name or IP address"
$userToRestore = Read-Host "Enter the user to restore"

# Normalize input to lowercase
$userToRestore = $userToRestore.ToLower()

# Define source and destination paths
$sourceBackupPath = "\\$sourcePC\C$\$userToRestore-BACKUP\$userToRestore"
$destinationPath = "\\$destinationPC\C$\Users\$userToRestore"
$registryBackupFolder = "$sourceBackupPath\Reg-Export"  # Folder containing all registry settings

# Define files and directories to exclude
$excludeList = @(
    "*ntuser.dat*",        # Exclude ntuser.dat files
    "*config*",            # Exclude configuration files
    "*database*",          # Exclude database files
    "*system*",            # Exclude system files
    "*Temp*",              # Exclude Temp folder
    "*Cache*",             # Exclude Cache folder
    "NTUSER.DAT*",         # Exclude NTUSER.DAT files
    "UsrClass.dat*",       # Exclude UsrClass.dat files
    "Desktop.ini",         # Exclude Desktop.ini file
    "Thumbs.db",           # Exclude Thumbs.db file
    "AppData\Local\Temp",  # Exclude Temp folder in AppData\Local
    "AppData\Roaming\Microsoft\Windows\Recent"   # Exclude Recent folder
)

# Remove Chrome and Edge directories from the exclusion list
$excludeList = $excludeList | Where-Object { $_ -notlike "AppData\Local\Google\Chrome*" -and $_ -notlike "AppData\Local\Packages\Microsoft.MicrosoftEdge*" }

# Function to move files and folders using robocopy
function Move-UserFiles {
    param (
        [string]$source,
        [string]$destination
    )

    robocopy "$source" "$destination" /E /COPYALL /XD $excludeList /R:0 /W:0 /XO
}

# Function to import registry settings
function Import-RegistrySettings {
    param (
        [string]$registryBackupFolder
    )

    $importedFiles = @()
    if (Test-Path $registryBackupFolder) {
        $regFiles = Get-ChildItem $registryBackupFolder -Filter "*.reg"
        foreach ($regFile in $regFiles) {
            # Check if the file has already been imported
            if ($importedFiles -notcontains $regFile.Name) {
                reg import $regFile.FullName
                $importedFiles += $regFile.Name
            }
        }
    } else {
        Write-Host "Registry settings folder not found: $registryBackupFolder" -ForegroundColor Yellow
    }
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

# Import all registry settings
Import-RegistrySettings -registryBackupFolder $registryBackupFolder
