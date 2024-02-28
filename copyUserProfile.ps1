# Prompt user for information
$userToCopy = Read-Host "Enter the username to be copied"
$sourceComputer = Read-Host "Enter the source computer name"
$destinationComputer = Read-Host "Enter the destination computer name"

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
    "Recent",              # Exclude Recent folder
    "Cookies",             # Exclude Cookies folder
    "AppData\Local\Temp",  # Exclude Temp folder in AppData\Local
)

# Create a folder C:\Reg-Export on the source computer
$exportPath = "C:\Reg-Export"
if (-not (Test-Path $exportPath -PathType Container)) {
    New-Item -Path $exportPath -ItemType Directory -Force
}

# Create a folder on the source computer using the source computer's name
$sourceFolder = "C:\$sourceComputer"
if (-not (Test-Path $sourceFolder -PathType Container)) {
    New-Item -Path $sourceFolder -ItemType Directory -Force
}

# Search the registry for the user's SID
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
$regKeys = Get-ChildItem -Path $regPath

foreach ($key in $regKeys) {
    $profileImagePath = Get-ItemPropertyValue -Path $key.PSPath -Name "ProfileImagePath" -ErrorAction SilentlyContinue

    if ($profileImagePath -eq "C:\Users\$userToCopy") {
        $userSID = $key.PSChildName
        Write-Host "User profile folder found on $($sourceComputer): C:\Users\$userToCopy"
        Write-Host "ProfileImagePath for $($userToCopy): $($profileImagePath)"
        Write-Host "User's SID: $userSID"
        break  # Exit the loop once the correct SID is found
    }
}

if ($userSID -eq $null) {
    Write-Host "User profile not found in the registry on $sourceComputer. Exiting." -ForegroundColor Red
    Exit
}

# Export the entire registry branch for the user's SID
$destinationRegFile = "$exportPath\$userSID.reg"
reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$userSID" $destinationRegFile

# Output SID and file information
Write-Host "Registry branch exported to: $destinationRegFile"

# Robocopy the user's profile folder to the source computer
$sourceProfileFolder = "C:\Users\$userToCopy"
$robocopyCommand = "robocopy ""$sourceProfileFolder"" ""$sourceFolder\$userToCopy"" /E /NFL /NJH /NJS /R:0 /W:0 /COPYALL /XJ /TEE /XD $excludeList"
Invoke-Expression -Command $robocopyCommand

# Check if the user's profile folder already exists on the source computer
# If it does, compare the sizes to determine if a new copy is needed
$sourceProfileOnSource = "$sourceFolder\$userToCopy"
if (Test-Path $sourceProfileOnSource -PathType Container) {
    $sourceProfileSize = (Get-ChildItem $sourceProfileOnSource -Recurse | Measure-Object -Property Length -Sum).Sum
    $sourceProfileSizeOnDisk = (Get-Item $sourceProfileOnSource).length
    if ($sourceProfileSize -eq $sourceProfileSizeOnDisk) {
        Write-Host "User profile folder already exists and is up-to-date on $sourceComputer. Skipping robocopy." -ForegroundColor Yellow
    } else {
        Write-Host "User profile folder exists on $sourceComputer, but sizes differ. Initiating robocopy." -ForegroundColor Yellow
        Invoke-Expression -Command $robocopyCommand
    }
}

# Move the C:\Reg-Export folder on the source computer to the source computer's user folder
$sourceRegExport = "C:\Reg-Export"
$destinationRegExport = "$sourceFolder\$userToCopy\Reg-Export"
robocopy "$sourceRegExport" "$destinationRegExport" /E /NFL /NJH /NJS /R:0 /W:0 /MOVE /XJ /TEE

# Copy the source computer's folder to the destination computer
$destinationFolder = "\\$destinationComputer\C$"
$robocopyCommand = "robocopy ""$sourceFolder"" ""$destinationFolder\$sourceComputer"" /E /NFL /NJH /NJS /R:0 /W:0 /COPYALL /XJ /TEE /XD $excludeList"
Invoke-Expression -Command $robocopyCommand

# Output completion information
Write-Host "User profile folder and Reg-Export folder copied successfully to: $destinationFolder\$userToCopy" -ForegroundColor Green
