''-----------------------------------------------------------------------------
'' File  : crampsetting.vbs
'' Desc  : Registry settings for CRAMP
''-----------------------------------------------------------------------------
'' mm-dd-yyyy  History                                                     user
'' 11-05-2003  Cre                                                          dky
''-----------------------------------------------------------------------------
DIM WshShell,bKey
SET WshShell=WScript.CreateObject("WScript.Shell")

WshShell.RegWrite "HKCU\Environment\CRAMP_DEBUG",0,"REG_SZ"
WshShell.RegWrite "HKCU\Environment\CRAMP_PROFILE",0,"REG_SZ"
WshShell.RegWrite "HKCU\Environment\CRAMP_PROFILE_STAT",0,"REG_SZ"
WshShell.RegWrite "HKCU\Environment\CRAMP_PROFILE_INCLUSION",0,"REG_SZ"

WshShell.RegDelete "HKCU\Environment\CRAMP_DEBUG"
WshShell.RegDelete "HKCU\Environment\CRAMP_PROFILE"
WshShell.RegDelete "HKCU\Environment\CRAMP_PROFILE_STAT"
WshShell.RegDelete "HKCU\Environment\CRAMP_PROFILE_INCLUSION"

' Set the temp folder for logs
bKey=WshShell.RegRead("HKCU\Environment\TEMP")
WshShell.RegWrite "HKCU\Environment\CRAMP_LOGPATH",bKey,"REG_SZ"

' Set the local computer as mail slot client
bKey="HKCU\Software\Microsoft\Windows Media\WMSDK\General\COMPUTERNAME"
bKey=WshShell.RegRead(bKey)
WshShell.RegWrite "HKCU\Environment\CRAMP_CLIENT",bKey,"REG_SZ"

WshShell.RegWrite "HKCU\Environment\CRAMP_PROFILE_LOGSIZE",500,"REG_SZ"
WshShell.RegWrite "HKCU\Environment\CRAMP_PROFILE_CALLDEPTH",0,"REG_SZ"
WshShell.RegWrite "HKCU\Environment\CRAMP_PROFILE_EXCLUSION",1,"REG_SZ"
WshShell.RegWrite "HKCU\Environment\CRAMP_PROFILE_MAXCALLLIMIT",0,"REG_SZ"

' For uninstallation
' WshShell.RegDelete "HKCU\Environment\CRAMP_DEBUG"
' WshShell.RegDelete "HKCU\Environment\CRAMP_PROFILE"
' WshShell.RegDelete "HKCU\Environment\CRAMP_LOGPATH"
' WshShell.RegDelete "HKCU\Environment\CRAMP_PROFILE_CALLDEPTH"
' WshShell.RegDelete "HKCU\Environment\CRAMP_PROFILE_MAXCALLLIMIT"
' WshShell.RegDelete "HKCU\Environment\CRAMP_PROFILE_EXCLUSION"
' WshShell.RegDelete "HKCU\Environment\CRAMP_PROFILE_INCLUSION"
' WshShell.RegDelete "HKCU\Environment\CRAMP_PROFILE_LOGSIZE"
' WshShell.RegDelete "HKCU\Environment\CRAMP_PROFILE_STAT"
' WshShell.RegDelete "HKCU\Environment\CRAMP_CLIENT"

WScript.Echo "Successfully updated default registry settings for CRAMP"
