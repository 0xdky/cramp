;------------------------------------------------------------------------------
; File : CRAMP.iss
; Desc : Input for Inno Setup program
; Help : http://www.jrsoftware.org/
; Time-stamp: <2003-11-24 18:19:10 dhruva>
;------------------------------------------------------------------------------

[Setup]
AppName=CRAMP
AppVerName=CRAMP 1.0
AppPublisher=Delmia Solutions Private Limited
AppPublisherURL=http://www.delmia.com/
AppSupportURL=http://www.delmia.com/
AppUpdatesURL=http://www.delmia.com/
AppMutex=CRAMPENGINE_MUTEX
DefaultDirName={pf}\CRAMP
DefaultGroupName=CRAMP

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "main"; Description: "CRAMP Files"; Types: full custom; Flags: fixed
Name: "STAF"; Description: "STAF"; Types: full custom
Name: "PERL"; Description: "PERL"; Types: full custom

[Tasks]
; NOTE: The following entry contains English phrases ("Create a desktop icon" and "Additional icons").
; You are free to translate them into another language if required.
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"

[Files]
; Main CRAMP files
Source: "D:\WRKSPS\cvs\cramp\bin\CRAMP.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "D:\WRKSPS\cvs\cramp\bin\CRAMPEngine.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "D:\WRKSPS\cvs\cramp\bin\libCRAMP.dll"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "D:\WRKSPS\cvs\cramp\bin\libCRAMP.exp"; DestDir: "{app}\lib"; Flags: ignoreversion
Source: "D:\WRKSPS\cvs\cramp\bin\libCRAMP.lib"; DestDir: "{app}\lib"; Flags: ignoreversion
Source: "D:\WRKSPS\cvs\cramp\inc\libCRAMP.h"; DestDir: "{app}\inc"; Flags: ignoreversion
Source: "D:\WRKSPS\cvs\cramp\scripts\crampstaf.pl"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "D:\WRKSPS\cvs\cramp\scripts\profileDB.pl"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "D:\WRKSPS\cvs\cramp\vbsrc\mainui\Attributes.txt"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "D:\WRKSPS\cvs\cramp\vbsrc\mainui\MostRecentFiles.txt"; DestDir: "{app}\bin"; Flags: ignoreversion

; VB related files
Source: "D:\tmp\CRAMP-Package\Support\*"; DestDir: "{app}\bin"; Flags: ignoreversion

; CRAMP docs
Source: "D:\WRKSPS\cvs\cramp\docs\*.ppt"; DestDir: "{app}\docs"; Flags: ignoreversion

; STAF files
Source: "D:\Applications\AutoTest\STAF\bin\*"; DestDir: "{app}\TOOLS\STAF\bin"; Components: STAF; Flags: ignoreversion recursesubdirs

; PERL
Source: "D:\perl\bin\*"; DestDir: "{app}\TOOLS\PERL\bin"; Components: PERL; Flags: ignoreversion recursesubdirs
Source: "D:\perl\lib\*"; DestDir: "{app}\TOOLS\PERL\lib"; Components: PERL; Flags: ignoreversion recursesubdirs
Source: "D:\perl\site\*"; DestDir: "{app}\TOOLS\PERL\site"; Components: PERL; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\CRAMP"; Filename: "{app}\CRAMP.exe"
; NOTE: The following entry contains an English phrase ("Uninstall").
; You are free to translate it into another language if required.
Name: "{group}\Uninstall CRAMP"; Filename: "{uninstallexe}"
Name: "{userdesktop}\CRAMP"; Filename: "{app}\bin\CRAMP.exe"; Tasks: desktopicon

[Registry]
; Main
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}\bin"; Flags: preservestringtype

; CRAMP related addition
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "CRAMP_LOGPATH"; ValueData: "%TEMP%"; Flags: createvalueifdoesntexist uninsdeletevalue
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "CRAMP_PROFILE_LOGSIZE"; ValueData: "500"; Flags: createvalueifdoesntexist uninsdeletevalue
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "CRAMP_PROFILE_CALLDEPTH"; ValueData: "0"; Flags: createvalueifdoesntexist uninsdeletevalue
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "CRAMP_PROFILE_EXCLUSION"; ValueData: "1"; Flags: createvalueifdoesntexist uninsdeletevalue
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "CRAMP_PROFILE_MAXCALLLIMIT"; ValueData: "0"; Flags: uninsdeletevalue

; STAF related
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "STAF_PATH"; ValueData: "{app}\STAF"; Flags: createvalueifdoesntexist uninsdeletevalue; Components: STAF

; PERL related
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: string; ValueName: "Path"; ValueData: "{olddata};{app}\PERL\bin"; Components: PERL

[Run]
; NOTE: The following entry contains an English phrase ("Launch").
; You are free to translate it into another language if required.
Filename: "{app}\docs\CRAMP.ppt"; Description: "Launch CRAMP docs"; Flags: shellexec nowait postinstall skipifsilent
Filename: "{app}\bin\CRAMP.exe"; Description: "Launch CRAMP"; Flags: nowait postinstall skipifsilent
