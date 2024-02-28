# Prompt user for information
$backupPC = Read-Host "Enter the backup computer name"
$sourcePC = Read-Host "Enter the source computer name"
$destinationPC = Read-Host "Enter the destination computer name"

# Check if the backupPC has the sourcePC folder
$sourcePCFolderOnBackup = "\\$backupPC\C`$\$sourcePC"
if (-not (Test-Path $sourcePCFolderOnBackup -PathType Container)) {
    Write-Host "Error: SourcePC folder not found on ${backupPC}. Exiting." -ForegroundColor Red
    Exit
}

# Output information about the data to be restored
Write-Host "Data to be restored from ${backupPC} to ${destinationPC}:"
Write-Host "SourcePC folder on ${backupPC}: ${sourcePCFolderOnBackup}"
Write-Host "DestinationPC: ${destinationPC}"

# Robocopy the sourcePC folder and its contents to the destinationPC
$destinationPCFolder = "\\$destinationPC\C`$"
$robocopyCommand = "robocopy ""$sourcePCFolderOnBackup"" ""$destinationPCFolder\$sourcePC"" /E /NFL /NJH /NJS /R:0 /W:0 /MOVE /XJ /TEE"
Invoke-Expression -Command $robocopyCommand

# Check if $userToRestore is not null
$userFolderOnDestination = "$destinationPCFolder\$sourcePC\$userToRestore"
if (-not (Test-Path $userFolderOnDestination -PathType Container)) {
    Write-Host "Error: User folder not found on ${destinationPC}. Exiting." -ForegroundColor Red
    Exit
}

# On the destinationPC, retrieve user name from the copied folder
$userToRestore = Get-ChildItem -Path "$destinationPCFolder\$sourcePC" | Select-Object -ExpandProperty Name

# Extract SID from the .reg filename in Reg-Export folder
$regExportFolder = "$destinationPCFolder\$sourcePC\$userToRestore\Reg-Export"
$regFile = Get-ChildItem "$regExportFolder\*.reg" | Select-Object -ExpandProperty FullName

if ($regFile -eq $null) {
    Write-Host "Error: No .reg file found in ${regExportFolder}. Exiting." -ForegroundColor Red
    Exit
}

$userSID = [System.IO.Path]::GetFileNameWithoutExtension($regFile)

# Create the key in the registry using the extracted SID
$regKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$userSID"
New-Item -Path $regKeyPath -Force

# Output information about the registry key creation
Write-Host "Registry key created on ${destinationPC}: ${regKeyPath}"

# Import the registry file for the user on the destinationPC
reg import $regFile

# Output that the registry has been imported
Write-Host "Registry file imported on ${destinationPC}."

# Robocopy the user folder to the C:\Users directory on destinationPC
$robocopyCommand = "robocopy ""$userFolderOnDestination"" ""$destinationPCFolder\Users\$userToRestore"" /E /NFL /NJH /NJS /R:0 /W:0 /MOVE /XJ /TEE"
Invoke-Expression -Command $robocopyCommand

# Output completion information
Write-Host "Data restored on ${destinationPC}. C:\Users\${userToRestore} now contains the user's data." -ForegroundColor Green

# Remove the C:\$sourcePC\$userToRestore directory from destinationPC
Remove-Item "$userFolderOnDestination" -Force -Recurse

# Remove the Reg-Export folder and its contents
Remove-Item "$regExportFolder" -Force -Recurse

# Output removal completion information
Write-Host "Directory ${userFolderOnDestination} removed from ${destinationPC}." -ForegroundColor Green
Write-Host "Reg-Export folder removed from ${destinationPC}." -ForegroundColor Green

# Prompt to run the script again
$runAgain = Read-Host "Do you want to run the script again? (Y/N)"
if ($runAgain -eq 'Y' -or $runAgain -eq 'y') {
    Start-Process powershell -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
}
