;;-----------------------------------------------------------------------------
;; File: CRAMP.nsi
;; Desc: CRAMP installer generation script for Null Soft Installer
;; NSI : http://nsis.sourceforge.net/
;; Time-stamp: <03/11/25 13:38:51 dhruva>
;;-----------------------------------------------------------------------------

; HM NIS Edit Wizard helper defines
!define PRODUCT_NAME "CRAMP"
!define PRODUCT_VERSION "1.0"
!define PRODUCT_PUBLISHER "Delmia Solutions Pvt Ltd"
!define PRODUCT_WEB_SITE "http://www.delmia.com/"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\CRAMP.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; MUI 1.67 compatible ------
!include "MUI.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Welcome page
!insertmacro MUI_PAGE_WELCOME
; License page
; !insertmacro MUI_PAGE_LICENSE "${NSISDIR}\License.txt"
; Components page
!insertmacro MUI_PAGE_COMPONENTS
; Directory page
!insertmacro MUI_PAGE_DIRECTORY
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
; Finish page
!define MUI_FINISHPAGE_RUN "$INSTDIR\bin\CRAMP.exe"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\docs\CRAMP.ppt"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

; MUI end ------

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "CRAMP-Setup.exe"
InstallDir "$PROGRAMFILES\CRAMP"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

; Some Global vars
VAR SBAT

Function .onInit
  SetShellVarContext all
FunctionEnd

Section "CRAMP Engine" SEC01
  SetOutPath "$INSTDIR\bin"
  SetOverwrite ifnewer
  File "..\bin\CRAMP.exe"
  File "..\bin\CRAMPEngine.exe"
  File "..\scripts\crampstaf.pl"
  File "..\vbsrc\mainui\Attributes.txt"
  File "..\vbsrc\mainui\MostRecentFiles.txt"
  File "\tmp\CRAMP-Package\Support\*"
  
  SetOutPath "$INSTDIR\docs"
  File "..\docs\CRAMP.ppt"
  
  CreateDirectory "$SMPROGRAMS\CRAMP"
  CreateShortCut "$SMPROGRAMS\CRAMP\CRAMP.lnk" "$INSTDIR\bin\CRAMP.exe"

  CreateDirectory "$SMPROGRAMS\CRAMP\docs"
  CreateShortCut "$SMPROGRAMS\CRAMP\docs\CRAMP.lnk" "$INSTDIR\docs\CRAMP.ppt"

  CreateShortCut "$DESKTOP\CRAMP.lnk" "$INSTDIR\bin\CRAMP.exe"

  WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                    "CRAMP_PATH" $INSTDIR
  WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                    "CRAMP_LOGPATH" $TEMP
SectionEnd

Section "CRAMP Profiler" SEC02
  SetOverwrite ifnewer
  SetOutPath "$INSTDIR\bin"
  File "..\bin\libCRAMP.dll"
  File "..\scripts\profileDB.pl"
  SetOutPath "$INSTDIR\lib"
  File "..\bin\libCRAMP.exp"
  File "..\bin\libCRAMP.lib"
  SetOutPath "$INSTDIR\inc"
  File "..\inc\libCRAMP.h"
  SetOutPath "$INSTDIR\docs"
  File "..\docs\CRAMP.ppt"
  
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
              "CRAMP_PROFILE_LOGSIZE" 500
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
              "CRAMP_PROFILE_CALLDEPTH" 0
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
              "CRAMP_PROFILE_EXCLUSION" 1
  WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
              "CRAMP_PROFILE_MAXCALLLIMIT" 0
  WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                    "CRAMP_LOGPATH" $TEMP
SectionEnd

Section "STAF" SEC03
  SetOverwrite ifnewer
  SetOutPath "$INSTDIR\TOOLS\STAF\bin"
  File /r "\Applications\AutoTest\STAF\bin\*"

  FileOpen $SBAT "$SMSTARTUP\STAFServer.bat" w
  FileWrite $SBAT "@call $\"$INSTDIR\TOOLS\STAF\bin\STAFProc.exe$\""
  FileClose $SBAT

  WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                    "STAF_PATH" "$INSTDIR\TOOLS\STAF"
SectionEnd

Section "PERL" SEC04
  SetOverwrite ifnewer
  SetOutPath "$INSTDIR\TOOLS\PERL\bin"
  File /r "\perl\bin\*"
  SetOutPath "$INSTDIR\TOOLS\PERL\lib"
  File /r "\perl\lib\*"
  SetOutPath "$INSTDIR\TOOLS\PERL\site"
  File /r "\perl\site\*"
SectionEnd

Section -AdditionalIcons
  WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"

  CreateShortCut "$SMPROGRAMS\CRAMP\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
  CreateShortCut "$SMPROGRAMS\CRAMP\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"

  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\bin\CRAMP.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\bin\CRAMP.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  
  SetRebootFlag true
SectionEnd

; Section descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} "CRAMP Win32 test engine"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02} "CRAMP Win32 profiler"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC03} "Software Test Automation Framework"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC04} "PERL - 5.9.0 (+ extra modules)"
!insertmacro MUI_FUNCTION_DESCRIPTION_END


Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully removed from your computer."
FunctionEnd

Function un.onInit
  SetShellVarContext all
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd

Section Uninstall
  Delete "$SMSTARTUP\STAFServer.bat"
  Delete "$DESKTOP\CRAMP.lnk"
  RMDir /r "$SMPROGRAMS\CRAMP"
  RMDir /r "$INSTDIR"

  DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                 "STAF_PATH"
  DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                 "CRAMP_PATH"
  DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                 "CRAMP_LOGPATH"
  DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                 "CRAMP_DEBUG"
  DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                 "CRAMP_PROFILE"
  DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                 "CRAMP_PROFILE_LOGSIZE"
  DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                 "CRAMP_PROFILE_CALLDEPTH"
  DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                 "CRAMP_PROFILE_EXCLUSION"
  DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
                 "CRAMP_PROFILE_MAXCALLLIMIT"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"

  SetAutoClose true
  SetRebootFlag true
SectionEnd
