;;-----------------------------------------------------------------------------
;; File: CRAMP.nsi
;; Desc: CRAMP installer generation script for Null Soft Installer
;; NSI : http://nsis.sourceforge.net/
;; Time-stamp: <2004-02-25 16:41:03 dky>
;;-----------------------------------------------------------------------------
;; mm-dd-yyyy  History                                                     user
;; 11-26-2003  Cre                                                          dky
;;-----------------------------------------------------------------------------

; HM NIS Edit Wizard helper defines
!define PRODUCT_NAME "CRAMP"
!define PRODUCT_PUBLISHER "Delmia Solutions Pvt Ltd"
!define PRODUCT_WEB_SITE "http://www.delmia.com/"
!define PRODUCT_DIR_REGKEY "Software\DELMIA\${PRODUCT_NAME}"
!define PRODUCT_UNINST_KEY \
        "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define ENV_KEY "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

; MUI 1.67 compatible ------
!include "MUI.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "../vbsrc/mainui/cramp.ico"
!define MUI_UNICON "../vbsrc/mainui/cramp.ico"

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
OutFile "..\bin\CRAMP-${PRODUCT_VERSION}.exe"
InstallDir "$PROGRAMFILES\CRAMP"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

;--------------------------------
; Setup file Version Information
;--------------------------------
VIProductVersion "${PRODUCT_VERSION}.0"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" ${PRODUCT_NAME}
VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "Profiler and Test tools"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "Delmia Gmbh"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalTrademarks" "Delmia Gmbh"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "© Delmia Corp"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "CRAMP"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${PRODUCT_VERSION}.0"
;--------------------------------

Function .onInit
  SetShellVarContext all
  ClearErrors
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "PERM" "1"
  ifErrors relog cont
relog:
   MessageBox MB_ICONINFORMATION|MB_OK \
              "Insufficient previlages! Login as administrator and retry"
   Abort
cont:
FunctionEnd

Section "!CRAMP Engine" SEC01
  SetOverwrite ifnewer

  SetOutPath "$INSTDIR\bin"
  File "..\bin\CRAMP.exe"
  File "..\bin\CRAMPEngine.exe"
  File "..\bin\ProfileControl.exe"
  File "\Applications\xerces\bin\xerces-c_2_3_0.dll"
  File "..\scripts\crampstaf.pl"
  File "\tmp\CRAMP-Package\Support\*"

  SetOutPath "$INSTDIR\res"
  File "..\res\Attributes.txt"
  File "..\res\MostRecentFiles.txt"

  SetOutPath "$INSTDIR\docs"
  File "..\docs\CRAMP.ppt"
  File "..\docs\DPEBaseClass.ppt"
  File "..\docs\CAAV5ItfDoc.ppt"

  CreateShortCut "$DESKTOP\CRAMP.lnk" "$INSTDIR\bin\CRAMP.exe"

  CreateDirectory "$SMPROGRAMS\CRAMP"
  CreateShortCut "$SMPROGRAMS\CRAMP\CRAMP.lnk" "$INSTDIR\bin\CRAMP.exe"

  CreateDirectory "$SMPROGRAMS\CRAMP\docs"
  CreateShortCut "$SMPROGRAMS\CRAMP\docs\CRAMP.lnk" "$INSTDIR\docs\CRAMP.ppt"
  CreateShortCut "$SMPROGRAMS\CRAMP\docs\Test Baseclass.lnk" \
                 "$INSTDIR\docs\DPEBaseClass.ppt"
  CreateShortCut "$SMPROGRAMS\CRAMP\docs\CAA Interfaces.lnk" \
                 "$INSTDIR\docs\CAAV5ItfDoc.ppt"

  push $R0
  push $R1
  GetFullPathName /SHORT $R0 $INSTDIR
  GetFullPathName /SHORT $R1 $TEMP

  WriteRegExpandStr HKLM "${ENV_KEY}" "CRAMP_PATH" $R0
  WriteRegExpandStr HKLM "${ENV_KEY}" "CRAMP_LOGPATH" $R1

  pop $R1
  pop $R0
SectionEnd

Section "CRAMP Profiler" SEC02
  SetOverwrite ifnewer

  SetOutPath "$INSTDIR\bin"
  File "..\bin\libCRAMP.dll"
  File "..\scripts\profileDB.pl"
  File "..\scripts\profileDQ.pl"
  File "..\scripts\querysort.pl"

  SetOutPath "$INSTDIR\lib"
  File "..\bin\libCRAMP.exp"
  File "..\bin\libCRAMP.lib"

  SetOutPath "$INSTDIR\inc"
  File "..\inc\libCRAMP.h"
  File "..\src\DPEBaseClass.h"

  SetOutPath "$INSTDIR\src"
  File "..\src\DPEBaseClass.cpp"
  File "..\test\DPEBaseClassTest.cpp"

  SetOutPath "$INSTDIR\docs"
  File "..\docs\CRAMP.ppt"

  push $R0
  FileOpen $R0 $SMPROGRAMS\CRAMP\docs\CRAMP.lnk r
  ifErrors CreateLink FileExist

FileExist:
  FileClose $R0
  goto RegEntry

CreateLink:
  CreateDirectory "$SMPROGRAMS\CRAMP\docs"
  CreateShortCut "$SMPROGRAMS\CRAMP\docs\CRAMP.lnk" "$INSTDIR\docs\CRAMP.ppt"
  goto RegEntry

RegEntry:
  WriteRegStr HKLM "${ENV_KEY}" "CRAMP_PROFILE_LOGSIZE" 500
  WriteRegStr HKLM "${ENV_KEY}" "CRAMP_PROFILE_CALLDEPTH" 0
  WriteRegStr HKLM "${ENV_KEY}" "CRAMP_PROFILE_MAXCALLLIMIT" 0

  pop $R0
SectionEnd

Section "STAF" SEC03
  SetOverwrite ifnewer
  SetOutPath "$INSTDIR\TOOLS\STAF\bin"
  File /r "\Applications\AutoTest\STAF\bin\*"

  CreateDirectory "$SMPROGRAMS\CRAMP"
  CreateShortCut "$SMPROGRAMS\CRAMP\STAF Server.lnk" \
                 "$INSTDIR\TOOLS\STAF\bin\STAFProc.exe" "" \
                 "$INSTDIR\TOOLS\STAF\bin\STAFProc.ico" "" \
                 SW_SHOWMINIMIZED "" "STAF RPC server"

  push $R0
  GetFullPathName /SHORT $R0 $INSTDIR
  WriteRegExpandStr HKLM "${ENV_KEY}" "STAF_PATH" "$R0\TOOLS\STAF"
  WriteRegExpandStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Run" \
                    "STAF Server" "%STAF_PATH%\bin\STAFProc.exe"


  FileOpen $R0 $INSTDIR\TOOLS\STAF\bin\stafpool.cfg w
  ifErrors StafError

  push $R1
  ReadRegStr $R1 HKLM \
             "SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" \
             ComputerName
  StrCpy $R1 "$R1$\n"
  FileWrite $R0 $R1
  pop $R1
  FileClose $R0

StafError:
  pop $R0

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
  WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" \
              "URL" "${PRODUCT_WEB_SITE}"

  CreateShortCut "$SMPROGRAMS\CRAMP\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
  CreateShortCut "$SMPROGRAMS\CRAMP\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"

  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\bin\CRAMP.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "Version" ${PRODUCT_VERSION}

  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
              "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
              "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
              "DisplayIcon" "$INSTDIR\bin\CRAMP.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
              "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
              "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
              "Publisher" "${PRODUCT_PUBLISHER}"

  # To refresh the environment variables
  SetRebootFlag true
SectionEnd

; Section descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} "CRAMP Win32 test engine"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02} "CRAMP Win32 profiler"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC03} \
                                    "Software Test Automation Framework"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC04} "PERL - 5.9.0 (+ extra modules)"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Function un.onUninstSuccess
  HideWindow
  IfRebootFlag end
  MessageBox MB_ICONINFORMATION|MB_OK \
             "$(^Name) was successfully removed from your computer."
end:
FunctionEnd

Function un.onInit
  SetShellVarContext all
  ClearErrors
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "PERM" "0"
  ifErrors relog cont
relog:
   MessageBox MB_ICONINFORMATION|MB_OK \
              "Insufficient previlages! Login as administrator and retry"
   Abort
cont:
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 \
             "Are you sure you want to completely uninstall $(^Name)?" IDYES +2
  Abort
FunctionEnd

Section Uninstall
  Delete /REBOOTOK "$DESKTOP\CRAMP.lnk"
  Delete /REBOOTOK "$INSTDIR\bin\*"
  Delete /REBOOTOK "$INSTDIR\TOOLS\STAF\bin\*"
  Delete /REBOOTOK "$INSTDIR\TOOLS\PERL\bin\*"

  RMDir  /r "$SMPROGRAMS\CRAMP"
  RMDir  /r "$INSTDIR"

  RMDir  /REBOOTOK "$SMPROGRAMS\CRAMP"
  RMDir  /REBOOTOK "$INSTDIR"

  DeleteRegValue HKLM "${ENV_KEY}" "STAF_PATH"
  DeleteRegValue HKLM "${ENV_KEY}" "CRAMP_PATH"
  DeleteRegValue HKLM "${ENV_KEY}" "CRAMP_LOGPATH"
  DeleteRegValue HKLM "${ENV_KEY}" "CRAMP_DEBUG"
  DeleteRegValue HKLM "${ENV_KEY}" "CRAMP_PROFILE"
  DeleteRegValue HKLM "${ENV_KEY}" "CRAMP_PROFILE_LOGSIZE"
  DeleteRegValue HKLM "${ENV_KEY}" "CRAMP_PROFILE_CALLDEPTH"
  DeleteRegValue HKLM "${ENV_KEY}" "CRAMP_PROFILE_MAXCALLLIMIT"
  DeleteRegValue HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Run" \
                 "STAF Server"
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegValue HKLM "${PRODUCT_DIR_REGKEY}" "PERM"
  DeleteRegValue HKLM "${PRODUCT_DIR_REGKEY}" "Version"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"

  IfRebootFlag RestartMsg end

RestartMsg:
  MessageBox MB_ICONINFORMATION|MB_SETFOREGROUND|MB_YESNO|MB_DEFBUTTON2 \
             "Reboot to complete $(^Name) uninstallation?" IDYES boot IDNO end
boot:
  Reboot
end:
  SetAutoClose true
SectionEnd
