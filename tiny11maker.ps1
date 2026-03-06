<#
.SYNOPSIS
    Scripts to build a trimmed-down Windows 11 image.

.DESCRIPTION
    This is a script created to automate the build of a streamlined Windows 11 image, similar to tiny10.
    My main goal is to use only Microsoft utilities like DISM, and no utilities from external sources.
    The only executable included is oscdimg.exe, which is provided in the Windows ADK and it is used to create bootable ISO images.

.PARAMETER ISO
    Drive letter given to the mounted iso (eg: E)

.PARAMETER SCRATCH
    Drive letter of the desired scratch disk (eg: D)

.EXAMPLE
    .\tiny11maker.ps1 E D
    .\tiny11maker.ps1 -ISO E -SCRATCH D
    .\tiny11maker.ps1 -SCRATCH D -ISO E
    .\tiny11maker.ps1

    *If you ordinal parameters the first one must be the mounted iso. The second is the scratch drive.
    prefer the use of full named parameter (eg: "-ISO") as you can put in the order you want.

.NOTES
    Auteur: ntdevlabs
    Date: 09-07-25
#>

#---------[ Parameters ]---------#
param (
    [ValidatePattern('^[c-zC-Z]$')][string]$ISO,
    [ValidatePattern('^[c-zC-Z]$')][string]$SCRATCH,
    [switch]$RemoveCopilot,
    [switch]$KeepEdge,
    [switch]$KeepOneDrive,
    [string]$AppListFile,
    [int]$ImageIndex = 1
)

$ErrorActionPreference = "Stop"

trap {
    Write-Host "`n========================================================" -ForegroundColor Red
    Write-Host "[ERRO CRITICO] O script encontrou uma falha irreparável!" -ForegroundColor Red
    Write-Host "Detalhes do erro:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host "========================================================`n" -ForegroundColor Red
    
    # Pausa a tela para depuração antes de fechar o console
    Write-Host "Pressione qualquer tecla para sair..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Sair do script garantindo que processos filhos morram se aplicável
    exit 1
}

if (-not $SCRATCH) {
    $ScratchDisk = Join-Path ($PSScriptRoot -replace '[\\]+$', '') "build"
}
else {
    $ScratchDisk = Join-Path ($SCRATCH + ":") "build"
}
if (-not (Test-Path $ScratchDisk)) { New-Item -ItemType Directory -Force -Path $ScratchDisk | Out-Null }

#---------[ Functions ]---------#
function Set-RegistryValue {
    param (
        [string]$path,
        [string]$name,
        [string]$type,
        [string]$value
    )
    try {
        & 'reg' 'add' $path '/v' $name '/t' $type '/d' $value '/f' | Out-Null
        Write-Output "Set registry value: $path\$name"
    }
    catch {
        Write-Output "Error setting registry value: $_"
    }
}

function Remove-RegistryValue {
    param (
        [string]$path
    )
    try {
        & 'reg' 'delete' $path '/f' | Out-Null
        Write-Output "Removed registry value: $path"
    }
    catch {
        Write-Output "Error removing registry value: $_"
    }
}

#---------[ Execution ]---------#
# Check if PowerShell execution is restricted
if ((Get-ExecutionPolicy) -eq 'Restricted') {
    Write-Output "Your current PowerShell Execution Policy is set to Restricted, which prevents scripts from running. Do you want to change it to RemoteSigned? (yes/no)"
    $response = Read-Host
    if ($response -eq 'yes') {
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm:$false
    }
    else {
        Write-Output "The script cannot be run without changing the execution policy. Exiting..."
        exit
    }
}

# Check and run the script as admin if required
$adminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$adminGroup = $adminSID.Translate([System.Security.Principal.NTAccount])
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
if (! $myWindowsPrincipal.IsInRole($adminRole)) {
    Write-Output "Restarting Tiny11 image creator as admin in a new window, you can close this one."
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);
    exit
}

if (-not (Test-Path -Path "$PSScriptRoot/autounattend.xml")) {
    Invoke-RestMethod "https://raw.githubusercontent.com/ntdevlabs/tiny11builder/refs/heads/main/autounattend.xml" -OutFile "$PSScriptRoot/autounattend.xml"
}

# Start the transcript and prepare the window
Start-Transcript -Path "$ScratchDisk\tiny11_$(get-date -f yyyyMMdd_HHmmss).log"

$Host.UI.RawUI.WindowTitle = "Tiny11 image creator"
Clear-Host
Write-Output "Welcome to the tiny11 image creator! Release: 09-07-25"

$hostArchitecture = $Env:PROCESSOR_ARCHITECTURE
New-Item -ItemType Directory -Force -Path "$ScratchDisk\tiny11\sources" | Out-Null
if (-not $ISO) {
    Write-Output "Nenhum drive de imagem fornecido."
    exit
}
else {
    $DriveLetter = $ISO
}
if ($DriveLetter -match '^[c-zC-Z]$') {
    $DriveLetter = $DriveLetter + ":"
    Write-Output "Drive letter set to $DriveLetter"
}
else {
    Write-Output "Invalid drive letter. Please enter a letter between C and Z."
    exit
}

Write-Output "Copying Windows image..."
# Movemos a cópia para ATES do Export-WindowsImage, assim o Export já salva na pasta final
# e não precisa se preocupar com a etapa Copy-Item sobrescrevendo ou ignorando
Copy-Item -Path "$DriveLetter\*" -Destination "$ScratchDisk\tiny11" -Recurse -Force | Out-Null
Set-ItemProperty -Path "$ScratchDisk\tiny11\sources\install.esd" -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
Remove-Item "$ScratchDisk\tiny11\sources\install.esd" -ErrorAction SilentlyContinue
Write-Output "Copy complete!"
Start-Sleep -Seconds 2

if ((Test-Path "$DriveLetter\sources\boot.wim") -eq $false -or (Test-Path "$DriveLetter\sources\install.wim") -eq $false) {
    if ((Test-Path "$DriveLetter\sources\install.esd") -eq $true) {
        Write-Output "Found install.esd, converting to install.wim..."
        Get-WindowsImage -ImagePath $DriveLetter\sources\install.esd
        $index = $ImageIndex
        Write-Output "Selecionado Index $index."
        Write-Output ' '
        Write-Output 'Converting install.esd to install.wim. This may take a while...'
        
        # Remoção de WIM residual de execuções anteriores falhas
        if (Test-Path "$ScratchDisk\tiny11\sources\install.wim") {
            Remove-Item "$ScratchDisk\tiny11\sources\install.wim" -Force
        }
        
        Export-WindowsImage -SourceImagePath $DriveLetter\sources\install.esd -SourceIndex $index -DestinationImagePath $ScratchDisk\tiny11\sources\install.wim -Compressiontype Maximum -CheckIntegrity
        
        # Como o WIM exportado só terá UM index (a versão extraída), forçamos o index interno das próximas etapas para 1.
        $ImageIndex = 1
    }
    else {
        Write-Output "Can't find Windows OS Installation files in the specified Drive Letter.."
        Write-Output "Please enter the correct DVD Drive Letter.."
        exit
    }
}

Clear-Host
Write-Output "Selecionado Index $ImageIndex."
$index = $ImageIndex
Write-Output "Mounting Windows image. This may take a while."
$wimFilePath = "$ScratchDisk\tiny11\sources\install.wim"
& takeown "/F" $wimFilePath
& icacls $wimFilePath "/grant" "$($adminGroup.Value):(F)"
try {
    Set-ItemProperty -Path $wimFilePath -Name IsReadOnly -Value $false -ErrorAction Stop
}
catch {
    # This block will catch the error and suppress it.
    Write-Error "$wimFilePath not found"
}

if (Test-Path "$ScratchDisk\scratchdir") {
    Write-Host "Limpando diretorio de montagem (scratchdir) de execucoes anteriores..." -ForegroundColor Yellow
    
    # Force an explicit dismount in case the system locked the folder
    Dismount-WindowsImage -Path "$ScratchDisk\scratchdir" -Discard -ErrorAction SilentlyContinue | Out-Null
    
    # Try DISM cleanup first in case there's a stale mount
    & dism.exe /Cleanup-Mountpoints | Out-Null
    & dism.exe /Cleanup-Wim | Out-Null
    
    Remove-Item -Path "$ScratchDisk\scratchdir" -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path "$ScratchDisk\scratchdir" > $null

Mount-WindowsImage -ImagePath $ScratchDisk\tiny11\sources\install.wim -Index $index -Path $ScratchDisk\scratchdir

Write-Output "Exporting list of all provisioned Appx packages..."
Get-AppxProvisionedPackage -Path "$ScratchDisk\scratchdir" | Select-Object -ExpandProperty DisplayName | Sort-Object | Out-File -FilePath "$ScratchDisk\all_installed_apps.txt" -Encoding UTF8

$imageIntl = & dism /English /Get-Intl "/Image:$($ScratchDisk)\scratchdir"
$languageLine = $imageIntl -split '\n' | Where-Object { $_ -match 'Default system UI language : ([a-zA-Z]{2}-[a-zA-Z]{2})' }

if ($languageLine) {
    $languageCode = $Matches[1]
    Write-Output "Default system UI language code: $languageCode"
}
else {
    Write-Output "Default system UI language code not found."
}

$imageInfo = & 'dism' '/English' '/Get-WimInfo' "/wimFile:$($ScratchDisk)\tiny11\sources\install.wim" "/index:$index"
$lines = $imageInfo -split '\r?\n'

foreach ($line in $lines) {
    if ($line -like '*Architecture : *') {
        $architecture = $line -replace 'Architecture : ', ''
        # If the architecture is x64, replace it with amd64
        if ($architecture -eq 'x64') {
            $architecture = 'amd64'
        }
        Write-Output "Architecture: $architecture"
        break
    }
}

if (-not $architecture) {
    Write-Output "Architecture information not found."
}

Write-Output "Mounting complete! Performing removal of applications..."

$packages = & 'dism' '/English' "/image:$($ScratchDisk)\scratchdir" '/Get-ProvisionedAppxPackages' |
ForEach-Object {
    if ($_ -match 'PackageName : (.*)') {
        $matches[1]
    }
}

$packagePrefixes = @()

if ($AppListFile -and (Test-Path $AppListFile)) {
    Write-Output "Carregando a lista customizada de aplicaticos UWP ($AppListFile)..."
    $packagePrefixes = Get-Content $AppListFile -Encoding UTF8
}
else {
    Write-Output "[AVISO] Nenhuma lista customizada encontrada. O sistema de exclusao pulara a etapa Appx."
}

if ($RemoveCopilot) {
    Write-Output "Adicionando Copilot a lista de exclusao de pacotes.."
    $packagePrefixes += 'Microsoft.Copilot'
    $packagePrefixes += 'Microsoft.Windows.Copilot'
}

$packagesToRemove = $packages | Where-Object {
    $packageName = $_
    $packagePrefixes -contains ($packagePrefixes | Where-Object { $packageName -like "*$_*" })
}
foreach ($package in $packagesToRemove) {
    Write-Output "Removing App: $package"
    & 'dism' '/English' "/image:$($ScratchDisk)\scratchdir" '/Remove-ProvisionedAppxPackage' "/PackageName:$package" | Out-Null
}

if (-not $KeepEdge) {
    Write-Output "Removing Edge:"
    Remove-Item -Path "$ScratchDisk\scratchdir\Program Files (x86)\Microsoft\Edge" -Recurse -Force | Out-Null
    Remove-Item -Path "$ScratchDisk\scratchdir\Program Files (x86)\Microsoft\EdgeUpdate" -Recurse -Force | Out-Null
    Remove-Item -Path "$ScratchDisk\scratchdir\Program Files (x86)\Microsoft\EdgeCore" -Recurse -Force | Out-Null
    & 'takeown' '/f' "$ScratchDisk\scratchdir\Windows\System32\Microsoft-Edge-Webview" '/r' | Out-Null
    & 'icacls' "$ScratchDisk\scratchdir\Windows\System32\Microsoft-Edge-Webview" '/grant' "$($adminGroup.Value):(F)" '/T' '/C' | Out-Null
    Remove-Item -Path "$ScratchDisk\scratchdir\Windows\System32\Microsoft-Edge-Webview" -Recurse -Force | Out-Null
}
if (-not $KeepOneDrive) {
    Write-Output "Removing OneDrive:"
    & 'takeown' '/f' "$ScratchDisk\scratchdir\Windows\System32\OneDriveSetup.exe" | Out-Null
    & 'icacls' "$ScratchDisk\scratchdir\Windows\System32\OneDriveSetup.exe" '/grant' "$($adminGroup.Value):(F)" '/T' '/C' | Out-Null
    Remove-Item -Path "$ScratchDisk\scratchdir\Windows\System32\OneDriveSetup.exe" -Force | Out-Null
}
Write-Output "Removal complete!"
Start-Sleep -Seconds 2
Clear-Host
Write-Output "Loading registry..."
reg load HKLM\zCOMPONENTS $ScratchDisk\scratchdir\Windows\System32\config\COMPONENTS | Out-Null
reg load HKLM\zDEFAULT $ScratchDisk\scratchdir\Windows\System32\config\default | Out-Null
reg load HKLM\zNTUSER $ScratchDisk\scratchdir\Users\Default\ntuser.dat | Out-Null
reg load HKLM\zSOFTWARE $ScratchDisk\scratchdir\Windows\System32\config\SOFTWARE | Out-Null
reg load HKLM\zSYSTEM $ScratchDisk\scratchdir\Windows\System32\config\SYSTEM | Out-Null
Write-Output "Bypassing system requirements(on the system image):"
Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassCPUCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassRAMCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassStorageCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassTPMCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'
Write-Output "Disabling Sponsored Apps:"
Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'OemPreInstalledAppsEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'ContentDeliveryAllowed' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start' 'ConfigureStartPins' 'REG_SZ' '{"pinnedList": [{}]}'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'FeatureManagementEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEverEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContentEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-310093Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338393Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353694Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353696Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall' 'DisablePushToInstall' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\MRT' 'DontOfferThroughWUAU' 'REG_DWORD' '1'
Remove-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions'
Remove-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableCloudOptimizedContent' 'REG_DWORD' '1'
Write-Output "Enabling Local Accounts on OOBE:"
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' 'BypassNRO' 'REG_DWORD' '1'
Copy-Item -Path "$PSScriptRoot\autounattend.xml" -Destination "$ScratchDisk\scratchdir\Windows\System32\Sysprep\autounattend.xml" -Force | Out-Null

Write-Output "Disabling Reserved Storage:"
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' 'ShippedWithReserves' 'REG_DWORD' '0'
Write-Output "Disabling BitLocker Device Encryption"
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker' 'PreventDeviceEncryption' 'REG_DWORD' '1'
Write-Output "Disabling Chat icon:"
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat' 'ChatIcon' 'REG_DWORD' '3'
Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 'REG_DWORD' '0'
Write-Output "Removing Edge related registries"
Remove-RegistryValue "HKEY_LOCAL_MACHINE\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
Remove-RegistryValue "HKEY_LOCAL_MACHINE\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update"
Write-Output "Disabling OneDrive folder backup"
Set-RegistryValue "HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" "REG_DWORD" "1"
Write-Output "Disabling Telemetry:"
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Input\TIPC' 'Enabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice' 'Start' 'REG_DWORD' '4'
## Prevents installation of DevHome and Outlook
Write-Output "Prevents installation of DevHome and Outlook:"
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' 'workCompleted' 'REG_DWORD' '1'
Remove-RegistryValue 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'
Remove-RegistryValue 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'
if ($RemoveCopilot) {
    Write-Output "Disabling Copilot no Registro do Windows.."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 'REG_DWORD' '1'
}
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 'REG_DWORD' '1'
Write-Output "Prevents installation of Teams:"
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Teams' 'DisableInstallation' 'REG_DWORD' '1'
Write-Output "Prevent installation of New Outlook":
Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Mail' 'PreventRun' 'REG_DWORD' '1'

Write-Host "Deleting scheduled task definition files..."
$tasksPath = "$ScratchDisk\scratchdir\Windows\System32\Tasks"

# Application Compatibility Appraiser
Remove-Item -Path "$tasksPath\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -Force -ErrorAction SilentlyContinue

# Customer Experience Improvement Program (removes the entire folder and all tasks within it)
Remove-Item -Path "$tasksPath\Microsoft\Windows\Customer Experience Improvement Program" -Recurse -Force -ErrorAction SilentlyContinue

# Program Data Updater
Remove-Item -Path "$tasksPath\Microsoft\Windows\Application Experience\ProgramDataUpdater" -Force -ErrorAction SilentlyContinue

# Chkdsk Proxy
Remove-Item -Path "$tasksPath\Microsoft\Windows\Chkdsk\Proxy" -Force -ErrorAction SilentlyContinue

# Windows Error Reporting (QueueReporting)
Remove-Item -Path "$tasksPath\Microsoft\Windows\Windows Error Reporting\QueueReporting" -Force -ErrorAction SilentlyContinue
Write-Host "Task files have been deleted."
Write-Host "Unmounting Registry..."
reg unload HKLM\zCOMPONENTS | Out-Null
reg unload HKLM\zDEFAULT | Out-Null
reg unload HKLM\zNTUSER | Out-Null
reg unload HKLM\zSOFTWARE | Out-Null
reg unload HKLM\zSYSTEM | Out-Null
Write-Output "Cleaning up image..."
dism.exe /Image:$ScratchDisk\scratchdir /Cleanup-Image /StartComponentCleanup /ResetBase
Write-Output "Cleanup complete."
Write-Output ' '
Write-Output "Unmounting image..."
Dismount-WindowsImage -Path $ScratchDisk\scratchdir -Save
Write-Host "Exporting image..."
Dism.exe /Export-Image /SourceImageFile:"$ScratchDisk\tiny11\sources\install.wim" /SourceIndex:$index /DestinationImageFile:"$ScratchDisk\tiny11\sources\install2.wim" /Compress:recovery
Remove-Item -Path "$ScratchDisk\tiny11\sources\install.wim" -Force | Out-Null
Rename-Item -Path "$ScratchDisk\tiny11\sources\install2.wim" -NewName "install.wim" | Out-Null
Write-Output "Windows image completed. Continuing with boot.wim."
Start-Sleep -Seconds 2
Clear-Host
Write-Output "Mounting boot image:"
$wimFilePath = "$ScratchDisk\tiny11\sources\boot.wim"
& takeown "/F" $wimFilePath | Out-Null
& icacls $wimFilePath "/grant" "$($adminGroup.Value):(F)"
Set-ItemProperty -Path $wimFilePath -Name IsReadOnly -Value $false
Mount-WindowsImage -ImagePath $ScratchDisk\tiny11\sources\boot.wim -Index 2 -Path $ScratchDisk\scratchdir
Write-Output "Loading registry..."
reg load HKLM\zCOMPONENTS $ScratchDisk\scratchdir\Windows\System32\config\COMPONENTS
reg load HKLM\zDEFAULT $ScratchDisk\scratchdir\Windows\System32\config\default
reg load HKLM\zNTUSER $ScratchDisk\scratchdir\Users\Default\ntuser.dat
reg load HKLM\zSOFTWARE $ScratchDisk\scratchdir\Windows\System32\config\SOFTWARE
reg load HKLM\zSYSTEM $ScratchDisk\scratchdir\Windows\System32\config\SYSTEM

Write-Output "Bypassing system requirements(on the setup image):"
Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassCPUCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassRAMCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassStorageCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassTPMCheck' 'REG_DWORD' '1'
Set-RegistryValue 'HKLM\zSYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'
Write-Output "Tweaking complete!"

Write-Output "Unmounting Registry..."
reg unload HKLM\zCOMPONENTS | Out-Null
reg unload HKLM\zDEFAULT | Out-Null
reg unload HKLM\zNTUSER | Out-Null
reg unload HKLM\zSOFTWARE | Out-Null
reg unload HKLM\zSYSTEM | Out-Null

Write-Output "Unmounting image..."
Dismount-WindowsImage -Path $ScratchDisk\scratchdir -Save
Clear-Host
Write-Output "The tiny11 image is now completed. Proceeding with the making of the ISO..."
Write-Output "Copying unattended file for bypassing MS account on OOBE..."
Copy-Item -Path "$PSScriptRoot\autounattend.xml" -Destination "$ScratchDisk\tiny11\autounattend.xml" -Force | Out-Null
Write-Output "Creating ISO image..."
$ADKDepTools = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$hostarchitecture\Oscdimg"
$localOSCDIMGPath = "$PSScriptRoot\oscdimg.exe"

if ([System.IO.Directory]::Exists($ADKDepTools)) {
    Write-Output "Will be using oscdimg.exe from system ADK."
    $OSCDIMG = "$ADKDepTools\oscdimg.exe"
}
else {
    Write-Output "ADK folder not found. Will be using bundled oscdimg.exe."
    $url = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/3D44737265000/oscdimg.exe"

    if (-not (Test-Path -Path $localOSCDIMGPath)) {
        Write-Output "Downloading oscdimg.exe..."
        Invoke-WebRequest -Uri $url -OutFile $localOSCDIMGPath

        if (Test-Path $localOSCDIMGPath) {
            Write-Output "oscdimg.exe downloaded successfully."
        }
        else {
            Write-Error "Failed to download oscdimg.exe."
            exit 1
        }
    }
    else {
        Write-Output "oscdimg.exe already exists locally."
    }

    $OSCDIMG = $localOSCDIMGPath
}

& "$OSCDIMG" '-m' '-o' '-u2' '-udfver102' "-bootdata:2#p0,e,b$ScratchDisk\tiny11\boot\etfsboot.com#pEF,e,b$ScratchDisk\tiny11\efi\microsoft\boot\efisys.bin" "$ScratchDisk\tiny11" "$ScratchDisk\tiny11.iso"

# Finishing up
Write-Output "Creation completed! Processo automatizado chegou ao fim."
# Read-Host "Press Enter to continue"
Write-Output "Performing Cleanup..."
Remove-Item -Path "$ScratchDisk\tiny11" -Recurse -Force | Out-Null
Remove-Item -Path "$ScratchDisk\scratchdir" -Recurse -Force | Out-Null
Write-Output "Ejecting Iso drive"
Get-Volume -DriveLetter $DriveLetter[0] | Get-DiskImage | Dismount-DiskImage
Write-Output "Iso drive ejected"
Write-Output "Removing oscdimg.exe..."
Remove-Item -Path "$PSScriptRoot\oscdimg.exe" -Force -ErrorAction SilentlyContinue
Write-Output "Removing autounattend.xml..."
Remove-Item -Path "$PSScriptRoot\autounattend.xml" -Force -ErrorAction SilentlyContinue

Write-Output "Cleanup check :"
if (Test-Path -Path "$ScratchDisk\tiny11") {
    Write-Output "tiny11 folder still exists. Attempting to remove it again..."
    Remove-Item -Path "$ScratchDisk\tiny11" -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -Path "$ScratchDisk\tiny11") {
        Write-Output "Failed to remove tiny11 folder."
    }
    else {
        Write-Output "tiny11 folder removed successfully."
    }
}
else {
    Write-Output "tiny11 folder does not exist. No action needed."
}
if (Test-Path -Path "$ScratchDisk\scratchdir") {
    Write-Output "scratchdir folder still exists. Attempting to remove it again..."
    Remove-Item -Path "$ScratchDisk\scratchdir" -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -Path "$ScratchDisk\scratchdir") {
        Write-Output "Failed to remove scratchdir folder."
    }
    else {
        Write-Output "scratchdir folder removed successfully."
    }
}
else {
    Write-Output "scratchdir folder does not exist. No action needed."
}
if (Test-Path -Path "$PSScriptRoot\oscdimg.exe") {
    Write-Output "oscdimg.exe still exists. Attempting to remove it again..."
    Remove-Item -Path "$PSScriptRoot\oscdimg.exe" -Force -ErrorAction SilentlyContinue
    if (Test-Path -Path "$PSScriptRoot\oscdimg.exe") {
        Write-Output "Failed to remove oscdimg.exe."
    }
    else {
        Write-Output "oscdimg.exe removed successfully."
    }
}
else {
    Write-Output "oscdimg.exe does not exist. No action needed."
}
if (Test-Path -Path "$PSScriptRoot\autounattend.xml") {
    Write-Output "autounattend.xml still exists. Attempting to remove it again..."
    Remove-Item -Path "$PSScriptRoot\autounattend.xml" -Force -ErrorAction SilentlyContinue
    if (Test-Path -Path "$PSScriptRoot\autounattend.xml") {
        Write-Output "Failed to remove autounattend.xml."
    }
    else {
        Write-Output "autounattend.xml removed successfully."
    }
}
else {
    Write-Output "autounattend.xml does not exist. No action needed."
}

# Stop the transcript
Stop-Transcript

exit

