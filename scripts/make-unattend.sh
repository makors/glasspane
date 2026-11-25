#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf build/payload-root
mkdir -p build state 'build/payload-root/$OEM$/$1/glasspane'
xml=build/Autounattend.xml
payload='build/payload-root/$OEM$/$1/glasspane'

cat > "$xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>en-US</UILanguage></SetupUILanguage>
      <InputLocale>0409:00000409</InputLocale>
      <SystemLocale>en-US</SystemLocale>
      <UILanguage>en-US</UILanguage>
      <UserLocale>en-US</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <DiskConfiguration>
        <WillShowUI>OnError</WillShowUI>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <CreatePartition wcm:action="add">
              <Order>1</Order>
              <Type>Primary</Type>
              <Extend>true</Extend>
            </CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add">
              <Order>1</Order>
              <PartitionID>1</PartitionID>
              <Active>true</Active>
              <Format>NTFS</Format>
              <Label>Windows</Label>
              <Letter>C</Letter>
            </ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallFrom>
            <MetaData wcm:action="add">
              <Key>/IMAGE/INDEX</Key>
              <Value>6</Value>
            </MetaData>
          </InstallFrom>
          <InstallTo>
            <DiskID>0</DiskID>
            <PartitionID>1</PartitionID>
          </InstallTo>
          <WillShowUI>OnError</WillShowUI>
          <InstallToAvailablePartition>false</InstallToAvailablePartition>
        </OSImage>
      </ImageInstall>
      <DynamicUpdate>
        <Enable>false</Enable>
        <WillShowUI>Never</WillShowUI>
      </DynamicUpdate>
      <UpgradeData>
        <Upgrade>false</Upgrade>
        <WillShowUI>Never</WillShowUI>
      </UpgradeData>
      <UserData>
        <AcceptEula>true</AcceptEula>
        <FullName>Glasspane</FullName>
        <Organization>Glasspane</Organization>
        <ProductKey>
          <!-- Public Microsoft Windows 10 Pro generic retail setup key: installation only, not activation. -->
          <Key>VK7JG-NPHTM-C97JM-9MPGT-3V66T</Key>
          <WillShowUI>Never</WillShowUI>
        </ProductKey>
      </UserData>
      <EnableFirewall>false</EnableFirewall>
      <Diagnostics><OptIn>false</OptIn></Diagnostics>
      <UseConfigurationSet>true</UseConfigurationSet>
    </component>
  </settings>

  <settings pass="specialize">
    <component name="Microsoft-Windows-Deployment" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <RunSynchronous>
        <RunSynchronousCommand wcm:action="add">
          <Order>1</Order>
          <Description>Install the Glasspane payload from its ISO</Description>
          <Path>C:\Windows\System32\cmd.exe /c C:\glasspane\install-payload.cmd</Path>
          <WillReboot>Never</WillReboot>
        </RunSynchronousCommand>
      </RunSynchronous>
    </component>
    <component name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <SkipAutoActivation>true</SkipAutoActivation>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <ComputerName>GLASSPANE-PC</ComputerName>
      <TimeZone>UTC</TimeZone>
      <RegisteredOrganization>Glasspane</RegisteredOrganization>
      <RegisteredOwner>Glasspane</RegisteredOwner>
    </component>
    <component name="Microsoft-Windows-ErrorReportingCore" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <DisableWER>1</DisableWER>
    </component>
    <component name="Microsoft-Windows-SQMApi" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <CEIPEnabled>0</CEIPEnabled>
    </component>
    <component name="Microsoft-Windows-SystemRestore-Main" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <DisableSR>1</DisableSR>
    </component>
    <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <InputLocale>0409:00000409</InputLocale>
      <SystemLocale>en-US</SystemLocale>
      <UILanguage>en-US</UILanguage>
      <UserLocale>en-US</UserLocale>
    </component>
  </settings>

  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <InputLocale>0409:00000409</InputLocale>
      <SystemLocale>en-US</SystemLocale>
      <UILanguage>en-US</UILanguage>
      <UserLocale>en-US</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC>
      </OOBE>
      <UserAccounts>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Name>Glasspane</Name>
            <Group>Administrators</Group>
            <Password>
              <Value>ZwBsAGEAcwBzAHAAYQBuAGUAUABhAHMAcwB3AG8AcgBkAFAAYQBzAHMAdwBvAHIAZAA=</Value>
              <PlainText>false</PlainText>
            </Password>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
      <AutoLogon>
        <Username>Glasspane</Username>
        <Enabled>true</Enabled>
        <LogonCount>65432</LogonCount>
        <Password>
          <Value>ZwBsAGEAcwBzAHAAYQBuAGUAUABhAHMAcwB3AG8AcgBkAFAAYQBzAHMAdwBvAHIAZAA=</Value>
          <PlainText>false</PlainText>
        </Password>
      </AutoLogon>
      <Display>
        <ColorDepth>32</ColorDepth>
        <HorizontalResolution>1280</HorizontalResolution>
        <VerticalResolution>720</VerticalResolution>
      </Display>
      <RegisteredOrganization>Glasspane</RegisteredOrganization>
      <RegisteredOwner>Glasspane</RegisteredOwner>
    </component>
  </settings>
</unattend>
XML

cat > "$payload/install-payload.cmd" <<'CMD'
@echo off
setlocal
set DEST=C:\glasspane
set LOG=%DEST%\payload-install.log
echo %DATE% %TIME% payload validation started> "%LOG%"
set FAIL=0

for %%F in (finalize.cmd optimize.ps1 run-stage.ps1 SetupComplete.cmd vmmouse.inf vmmouse.cat vmmouse.sys) do (
  if not exist "%DEST%\%%F" (
    echo missing payload file: %%F>>"%LOG%"
    set FAIL=1
  )
)

if not exist "%WINDIR%\Setup\Scripts" mkdir "%WINDIR%\Setup\Scripts" >>"%LOG%" 2>&1
copy /y "%DEST%\SetupComplete.cmd" "%WINDIR%\Setup\Scripts\SetupComplete.cmd" >>"%LOG%" 2>&1
if errorlevel 1 set FAIL=1

if "%FAIL%"=="0" (
  echo payload installed> "%DEST%\payload-installed.txt"
) else (
  echo payload installation incomplete> "%DEST%\payload-failed.txt"
)
exit /b 0
CMD

cat > "$payload/SetupComplete.cmd" <<'CMD'
@echo off
set LOG=C:\glasspane\setupcomplete.log
echo %DATE% %TIME% SetupComplete started> "%LOG%"
if not exist C:\glasspane\finalize.cmd (
  echo finalize.cmd is missing>>"%LOG%"
  exit /b 0
)
C:\Windows\System32\cmd.exe /c C:\glasspane\finalize.cmd stage1 >>"%LOG%" 2>&1
echo finalize stage1 exit %ERRORLEVEL%>>"%LOG%"
exit /b 0
CMD

cat > "$payload/finalize.cmd" <<'CMD'
@echo off
setlocal
set DIR=C:\glasspane
set LOG=%DIR%\finalize.log
set STAGE=%~1
if "%STAGE%"=="" set STAGE=stage1
echo %DATE% %TIME% begin %STAGE%>>"%LOG%"

if /i "%STAGE%"=="stage1" goto stage1
if /i "%STAGE%"=="stage2" goto stage2
if /i "%STAGE%"=="stage3" goto stage3
echo unknown stage %STAGE%>>"%LOG%"
exit /b 2

:stage1
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%DIR%\run-stage.ps1" -Stage 1 -TimeoutSeconds 1800 >>"%LOG%" 2>&1
set RC=%ERRORLEVEL%
echo stage1 runner exit %RC%>>"%LOG%"
if not "%RC%"=="0" echo stage1 runner failed> "%DIR%\glasspane-stage1-failed.txt"
if "%RC%"=="0" echo done> "%DIR%\glasspane-stage1.done"
schtasks /create /tn GlasspaneStage2 /sc onlogon /ru SYSTEM /tr "cmd.exe /c C:\glasspane\finalize.cmd stage2" /f >>"%LOG%" 2>&1
if errorlevel 1 (
  echo GlasspaneStage2 creation failed> "%DIR%\glasspane-task-failed.txt"
  echo GlasspaneStage2 creation failed>>"%LOG%"
)
exit /b 0

:stage2
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%DIR%\run-stage.ps1" -Stage 2 -TimeoutSeconds 3600 >>"%LOG%" 2>&1
set RC=%ERRORLEVEL%
echo stage2 runner exit %RC%>>"%LOG%"
if not "%RC%"=="0" echo stage2 runner failed> "%DIR%\glasspane-stage2-failed.txt"
if "%RC%"=="0" echo done> "%DIR%\glasspane-stage2.done"
schtasks /delete /tn GlasspaneStage2 /f >>"%LOG%" 2>&1
schtasks /create /tn GlasspaneStage3 /sc onstart /ru SYSTEM /tr "cmd.exe /c C:\glasspane\finalize.cmd stage3" /f >>"%LOG%" 2>&1
if errorlevel 1 (
  echo GlasspaneStage3 creation failed> "%DIR%\glasspane-task-failed.txt"
  echo GlasspaneStage3 creation failed>>"%LOG%"
)
shutdown /r /f /t 5 >>"%LOG%" 2>&1
exit /b 0

:stage3
powercfg.exe /h off >>"%LOG%" 2>&1
reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >>"%LOG%" 2>&1
reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagingFiles /t REG_MULTI_SZ /d "" /f >>"%LOG%" 2>&1
del /a /f C:\hiberfil.sys C:\pagefile.sys C:\swapfile.sys >>"%LOG%" 2>&1

set FAILED=0
if exist "%DIR%\glasspane-stage1-failed.txt" set FAILED=1
if exist "%DIR%\glasspane-stage2-failed.txt" set FAILED=1
if exist "%DIR%\glasspane-task-failed.txt" set FAILED=1
if exist C:\hiberfil.sys set FAILED=1
if exist C:\pagefile.sys set FAILED=1
if exist C:\swapfile.sys set FAILED=1

schtasks /delete /tn GlasspaneStage2 /f >>"%LOG%" 2>&1
schtasks /delete /tn GlasspaneStage3 /f >>"%LOG%" 2>&1
if "%FAILED%"=="0" (
  echo Glasspane image preparation complete> C:\glasspane-ready.txt
  echo ready marker written>>"%LOG%"
) else (
  echo Glasspane image preparation failed> C:\glasspane-failed.txt
  echo failure marker written>>"%LOG%"
)
shutdown /s /f /t 5 >>"%LOG%" 2>&1
exit /b 0
CMD

cat > "$payload/run-stage.ps1" <<'PS1'
param([int]$Stage = 1, [int]$TimeoutSeconds = 1800)
$ErrorActionPreference = 'Continue'
$script = 'C:\glasspane\optimize.ps1'
if (-not (Test-Path $script)) {
    Write-Host "Missing $script"
    exit 2
}
$arguments = @(
    '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
    '-File', $script, '-Stage', [string]$Stage
)
$process = Start-Process -FilePath "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $arguments -WorkingDirectory 'C:\glasspane' -PassThru -NoNewWindow
if ($process.WaitForExit($TimeoutSeconds * 1000)) {
    exit $process.ExitCode
}
Write-Host "Optimization stage $Stage timed out after $TimeoutSeconds seconds"
try { Stop-Process -Id $process.Id -Force -ErrorAction Stop } catch { Write-Host $_ }
exit 124
PS1

cat > "$payload/optimize.ps1" <<'PS1'
param([int]$Stage = 1)
$ErrorActionPreference = 'Continue'
Start-Transcript -Path "C:\glasspane\optimize-stage$Stage.log" -Force | Out-Null

function Invoke-Logged([string]$File, [string[]]$Arguments = @()) {
    Write-Host "> $File $($Arguments -join ' ')"
    & $File @Arguments 2>&1 | Out-Host
    Write-Host "< exit $LASTEXITCODE"
}

if ($Stage -eq 1) {
    Invoke-Logged powercfg.exe @('/h', 'off')
    Invoke-Logged reg.exe @('add', 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power', '/v', 'HiberbootEnabled', '/t', 'REG_DWORD', '/d', '0', '/f')

    try {
        $cs = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
        $cs.AutomaticManagedPagefile = $false
        $cs.Put() | Out-Null
        Get-WmiObject -Class Win32_PageFileSetting -ErrorAction SilentlyContinue | ForEach-Object { $_.Delete() | Out-Null }
    } catch { Write-Host $_ }
    Invoke-Logged cmd.exe @('/c', 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagingFiles /t REG_MULTI_SZ /d "" /f')
    Invoke-Logged reg.exe @('add', 'HKLM\SYSTEM\CurrentControlSet\Control\CrashControl', '/v', 'CrashDumpEnabled', '/t', 'REG_DWORD', '/d', '0', '/f')

    $services = @(
        'WSearch','SysMain','DiagTrack','dmwappushservice','Spooler','PrintNotify','Fax',
        'TabletInputService','wuauserv','UsoSvc','WaaSMedicSvc','BITS','DoSvc','diagsvc',
        'WMPNetworkSvc','RetailDemo','WerSvc','RemoteRegistry','CscService','TrkWks',
        'LanmanServer','wisvc','SecurityHealthService','edgeupdate','edgeupdatem',
        'MicrosoftEdgeElevationService','DPS','WdiServiceHost','WdiSystemHost','MapsBroker'
    )
    foreach ($name in $services) {
        Invoke-Logged sc.exe @('config', $name, 'start=', 'disabled')
        Invoke-Logged sc.exe @('stop', $name)
    }

    if (Test-Path 'C:\glasspane\vmmouse.inf') {
        Invoke-Logged pnputil.exe @('/add-driver', 'C:\glasspane\vmmouse.inf', '/install')
    } else {
        Write-Host 'C:\glasspane\vmmouse.inf is missing'
    }

    Invoke-Logged reg.exe @('load', 'HKU\GlasspaneDefault', 'C:\Users\Default\ntuser.dat')
    if ($LASTEXITCODE -eq 0) {
        Invoke-Logged reg.exe @('add', 'HKU\GlasspaneDefault\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects', '/v', 'VisualFXSetting', '/t', 'REG_DWORD', '/d', '2', '/f')
        Invoke-Logged reg.exe @('add', 'HKU\GlasspaneDefault\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize', '/v', 'EnableTransparency', '/t', 'REG_DWORD', '/d', '0', '/f')
        Invoke-Logged reg.exe @('add', 'HKU\GlasspaneDefault\Control Panel\Desktop', '/v', 'DragFullWindows', '/t', 'REG_SZ', '/d', '0', '/f')
        Invoke-Logged reg.exe @('add', 'HKU\GlasspaneDefault\Control Panel\Desktop', '/v', 'MenuShowDelay', '/t', 'REG_SZ', '/d', '0', '/f')
        Invoke-Logged reg.exe @('add', 'HKU\GlasspaneDefault\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced', '/v', 'TaskbarAnimations', '/t', 'REG_DWORD', '/d', '0', '/f')
        Invoke-Logged reg.exe @('add', 'HKU\GlasspaneDefault\Control Panel\Desktop\WindowMetrics', '/v', 'MinAnimate', '/t', 'REG_SZ', '/d', '0', '/f')
        Invoke-Logged reg.exe @('unload', 'HKU\GlasspaneDefault')
    }

    Invoke-Logged reg.exe @('add', 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters', '/v', 'EnablePrefetcher', '/t', 'REG_DWORD', '/d', '0', '/f')
    Invoke-Logged reg.exe @('add', 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters', '/v', 'EnableSuperfetch', '/t', 'REG_DWORD', '/d', '0', '/f')

    try { Set-MpPreference -DisableRealtimeMonitoring $true } catch { Write-Host $_ }
    try {
        Get-ScheduledTask | Where-Object { $_.TaskName -match 'Customer Experience Improvement Program|Consolidator|UsbCeip|DmClient|Feedback|DiskFootprint|Scheduled Defrag' } |
            Disable-ScheduledTask -ErrorAction SilentlyContinue
    } catch { Write-Host $_ }
} else {
    Invoke-Logged powercfg.exe @('/h', 'off')
    Invoke-Logged reg.exe @('add', 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power', '/v', 'HiberbootEnabled', '/t', 'REG_DWORD', '/d', '0', '/f')
    Invoke-Logged dism.exe @('/Online', '/Cleanup-Image', '/StartComponentCleanup')

    $paths = @(
        'C:\Windows\Temp\*',
        'C:\Windows\Logs\CBS\*.log',
        'C:\Windows\Logs\DISM\*.log',
        'C:\Windows\Panther\*',
        'C:\Program Files\Microsoft\EdgeUpdate\Download\*',
        'C:\Program Files\Microsoft\EdgeUpdate\Install\*',
        'C:\ProgramData\Microsoft\Windows Defender\Scans\History\*',
        'C:\ProgramData\Microsoft\Windows Defender\Scans\mpcache-*',
        'C:\Recovery\WindowsRE\Winre.wim'
    )
    foreach ($path in $paths) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }

    Invoke-Logged defrag.exe @('C:', '/O', '/H')
    Invoke-Logged cmd.exe @('/c', 'del /q /f /s %TEMP%\*')
}
Stop-Transcript | Out-Null
PS1

python3 - "$payload" <<'PYCRLF'
import pathlib
import sys
root = pathlib.Path(sys.argv[1])
for name in ("install-payload.cmd", "SetupComplete.cmd", "finalize.cmd"):
    path = root / name
    data = path.read_bytes().replace(b"\r\n", b"\n").replace(b"\n", b"\r\n")
    path.write_bytes(data)
PYCRLF

# Put the answer file at the configuration-set root. Windows Setup can
# discover it on CD/DVD media, and UseConfigurationSet makes it process the
# adjacent $OEM$ tree without relying on a legacy floppy inside installed Windows.
cp -f "$xml" build/payload-root/Autounattend.xml

printf 'Created %s and payload files in %s\n' "$xml" "$payload"
