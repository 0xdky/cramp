Attribute VB_Name = "Win32"
Option Explicit

Public Type PROCESS_INFORMATION
   hProcess As Long
   hThread As Long
   dwProcessId As Long
   dwThreadId As Long
End Type

Public Type STARTUPINFO
   cb As Long
   lpReserved As String
   lpDesktop As String
   lpTitle As String
   dwX As Long
   dwY As Long
   dwXSize As Long
   dwYSize As Long
   dwXCountChars As Long
   dwYCountChars As Long
   dwFillAttribute As Long
   dwFlags As Long
   wShowWindow As Integer
   cbReserved2 As Integer
   lpReserved2 As Long
   hStdInput As Long
   hStdOutput As Long
   hStdError As Long
End Type

Public Declare Function GetTempPath Lib "kernel32.dll" _
   Alias "GetTempPathA" _
   (ByVal nBufferLength As Long, _
   ByVal lpBuffer As String) As Long

Public Declare Function CreateProcess Lib "kernel32" _
   Alias "CreateProcessA" _
   (ByVal lpApplicationName As String, _
   ByVal lpCommandLine As String, _
   lpProcessAttributes As Any, _
   lpThreadAttributes As Any, _
   ByVal bInheritHandles As Long, _
   ByVal dwCreationFlags As Long, _
   lpEnvironment As Any, _
   ByVal lpCurrentDriectory As String, _
   lpStartupInfo As STARTUPINFO, _
   lpProcessInformation As PROCESS_INFORMATION) As Long

Public Declare Function OpenProcess Lib "kernel32.dll" _
   (ByVal dwAccess As Long, _
   ByVal fInherit As Integer, _
   ByVal hObject As Long) As Long

Public Declare Function TerminateProcess Lib "kernel32" _
   (ByVal hProcess As Long, _
   ByVal uExitCode As Long) As Long

Public Declare Function CloseHandle Lib "kernel32" _
   (ByVal hObject As Long) As Long
   
Public Declare Function GetExitCodeProcess Lib "kernel32" _
   (ByVal hObject As Long, ByRef retcode As Long) As Boolean

Public Declare Function WaitForSingleObject Lib "kernel32" _
    (ByVal hObject As Long, ByVal waitTime As Long) As Long
    
Public Declare Function GetShortPathName Lib "kernel32" Alias _
"GetShortPathNameA" (ByVal lpszLongPath As String, _
ByVal lpszShortPath As String, ByVal cchBuffer As Long) As Long

Public Declare Function GetCurrentProcessId Lib "kernel32" () As Long

Public Const REG_SZ As Long = 1
Public Const REG_DWORD As Long = 4

Public Const HKEY_CLASSES_ROOT = &H80000000
Public Const HKEY_CURRENT_USER = &H80000001
Public Const HKEY_LOCAL_MACHINE = &H80000002
Public Const HKEY_USERS = &H80000003

Public Const ERROR_NONE = 0
Public Const ERROR_BADDB = 1
Public Const ERROR_BADKEY = 2
Public Const ERROR_CANTOPEN = 3
Public Const ERROR_CANTREAD = 4
Public Const ERROR_CANTWRITE = 5
Public Const ERROR_OUTOFMEMORY = 6
Public Const ERROR_ARENA_TRASHED = 7
Public Const ERROR_ACCESS_DENIED = 8
Public Const ERROR_INVALID_PARAMETERS = 87
Public Const ERROR_NO_MORE_ITEMS = 259

Public Const KEY_QUERY_VALUE = &H1
Public Const KEY_SET_VALUE = &H2
Public Const KEY_ALL_ACCESS = &H3F

Public Const REG_OPTION_NON_VOLATILE = 0

Declare Function RegCloseKey Lib "advapi32.dll" _
(ByVal hKey As Long) As Long

Declare Function RegCreateKeyEx Lib "advapi32.dll" Alias _
"RegCreateKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, _
ByVal Reserved As Long, ByVal lpClass As String, ByVal dwOptions _
As Long, ByVal samDesired As Long, ByVal lpSecurityAttributes _
As Long, phkResult As Long, lpdwDisposition As Long) As Long

Declare Function RegOpenKeyEx Lib "advapi32.dll" Alias _
"RegOpenKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, _
ByVal ulOptions As Long, ByVal samDesired As Long, phkResult As _
Long) As Long

Declare Function RegQueryValueExString Lib "advapi32.dll" Alias _
"RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As _
String, ByVal lpReserved As Long, lpType As Long, ByVal lpData _
As String, lpcbData As Long) As Long

Declare Function RegQueryValueExLong Lib "advapi32.dll" Alias _
"RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As _
String, ByVal lpReserved As Long, lpType As Long, lpData As _
Long, lpcbData As Long) As Long

Declare Function RegQueryValueExNULL Lib "advapi32.dll" Alias _
"RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As _
String, ByVal lpReserved As Long, lpType As Long, ByVal lpData _
As Long, lpcbData As Long) As Long

Declare Function RegSetValueExString Lib "advapi32.dll" Alias _
"RegSetValueExA" (ByVal hKey As Long, ByVal lpValueName As String, _
ByVal Reserved As Long, ByVal dwType As Long, ByVal lpValue As _
String, ByVal cbData As Long) As Long

Declare Function RegSetValueExLong Lib "advapi32.dll" Alias _
"RegSetValueExA" (ByVal hKey As Long, ByVal lpValueName As String, _
ByVal Reserved As Long, ByVal dwType As Long, lpValue As Long, _
ByVal cbData As Long) As Long

'Windows type used to call the Net API
Public Const MAX_PREFERRED_LENGTH As Long = -1
Public Const NERR_SUCCESS As Long = 0&
Public Const ERROR_MORE_DATA As Long = 234&
Public Const LB_SETTABSTOPS As Long = &H192

'See NetServerEnum demo for complete
'list of server types supported
Public Const SV_TYPE_ALL                 As Long = &HFFFFFFFF
Public Const SV_TYPE_WORKSTATION         As Long = &H1
Public Const SV_TYPE_SERVER              As Long = &H2

Public Const STYPE_ALL       As Long = -1  'note: my const
Public Const STYPE_DISKTREE  As Long = 0
Public Const STYPE_PRINTQ    As Long = 1
Public Const STYPE_DEVICE    As Long = 2
Public Const STYPE_IPC       As Long = 3
Public Const STYPE_SPECIAL   As Long = &H80000000
Public Const ACCESS_READ     As Long = &H1
Public Const ACCESS_WRITE    As Long = &H2
Public Const ACCESS_CREATE   As Long = &H4
Public Const ACCESS_EXEC     As Long = &H8
Public Const ACCESS_DELETE   As Long = &H10
Public Const ACCESS_ATRIB    As Long = &H20
Public Const ACCESS_PERM     As Long = &H40
Public Const ACCESS_ALL      As Long = ACCESS_READ Or _
                                        ACCESS_WRITE Or _
                                        ACCESS_CREATE Or _
                                        ACCESS_EXEC Or _
                                        ACCESS_DELETE Or _
                                        ACCESS_ATRIB Or _
                                        ACCESS_PERM
                                        
'for use on Win NT/2000 only
Public Type SERVER_INFO_100
  sv100_platform_id  As Long
  sv100_name         As Long
End Type

'shi2_current_uses: number of current connections to the resource
'shi2_max_uses    : max concurrent connections resource can accommodate
'shi2_netname     : share name of a resource
'shi2_passwd      : share's password when
'                  (server running with share-level security)
'shi2_path        : local path for the shared resource
'shi2_permissions : shared resource's permissions
'                  (servers running with share-level security)
'shi2_remark      : string containing optional comment about the resource
'shi2_type        : the type of the shared resource
Public Type SHARE_INFO_2
  shi2_netname       As Long
  shi2_type          As Long
  shi2_remark        As Long
  shi2_permissions   As Long
  shi2_max_uses      As Long
  shi2_current_uses  As Long
  shi2_path          As Long
  shi2_passwd        As Long
End Type

Public Declare Function NetServerEnum Lib "netapi32" _
  (ByVal servername As Long, _
   ByVal level As Long, _
   buf As Any, _
   ByVal prefmaxlen As Long, _
   entriesread As Long, _
   totalentries As Long, _
   ByVal servertype As Long, _
   ByVal domain As Long, _
   resume_handle As Long) As Long

Public Declare Function NetShareEnum Lib "netapi32" _
  (ByVal servername As Long, _
   ByVal level As Long, _
   bufptr As Long, _
   ByVal prefmaxlen As Long, _
   entriesread As Long, _
   totalentries As Long, _
   resume_handle As Long) As Long
   
Public Declare Function NetApiBufferFree Lib "netapi32" _
   (ByVal Buffer As Long) As Long
     
Public Declare Sub CopyMemory Lib "kernel32" _
   Alias "RtlMoveMemory" _
  (pTo As Any, uFrom As Any, _
   ByVal lSize As Long)
   
Public Declare Function lstrlenW Lib "kernel32" _
  (ByVal lpString As Long) As Long

Public Declare Function SendMessage Lib "user32" _
   Alias "SendMessageA" _
  (ByVal hwnd As Long, _
   ByVal wMsg As Long, _
   ByVal wParam As Long, _
   lParam As Any) As Long


'***********************************************************
' My Code Starts Here
'***********************************************************
Public Declare Function FindFirstFile Lib "kernel32.dll" Alias "FindFirstFileA" _
                         (ByVal lpFileName As String, lpFindFileData As WIN32_FIND_DATA) As Long

Public Declare Function FindNextFile Lib "kernel32.dll" Alias "FindNextFileA" _
                         (ByVal hFindFile As Long, lpFindFileData As WIN32_FIND_DATA) As Long

Public Declare Function FindClose Lib "kernel32.dll" (ByVal hFindFile As Long) As Long

Public Declare Function GetCursorPos Lib "user32" (lpPoint As POINTCORD) As Long

Public Declare Function GetComputerNameEx Lib "kernel32" Alias "GetComputerNameExA" _
                         (ByVal lpCompName As COMPUTER_NAME_FORMAT, ByVal lpBuffer As String, _
                          nSize As Long) As Long

Public Const MAX_PATH = 260

Public Type FILETIME
        dwLowDateTime As Long
        dwHighDateTime As Long
End Type

Public Type POINTCORD
        X As Long
        Y As Long
End Type

Public Type WIN32_FIND_DATA
        dwFileAttributes As Long
       ftCreationTime As FILETIME
        ftLastAccessTime As FILETIME
       ftLastWriteTime As FILETIME
        nFileSizeHigh As Long
        nFileSizeLow As Long
        dwReserved0 As Long
        dwReserved1 As Long
        cFileName As String * MAX_PATH
        cAlternate As String * 14
End Type

'icon code

Public Const LVM_FIRST = &H1000
Public Const LVM_GETHEADER = (LVM_FIRST + 31)

Public Const HDI_IMAGE = &H20
Public Const HDI_FORMAT = &H4
    
Public Const HDF_BITMAP_ON_RIGHT = &H1000
Public Const HDF_IMAGE = &H800
Public Const HDF_STRING = &H4000
    
Public Const HDM_FIRST = &H1200
Public Const HDM_SETITEM = (HDM_FIRST + 4)
    
Public Const HDF_LEFT As Long = 0
Public Const HDF_RIGHT As Long = 1
Public Const HDF_CENTER As Long = 2
    
Public Enum enumShowHide
    bShow = -1
    bHide = 0
End Enum

Public Type HDITEM
   mask     As Long
   cxy      As Long
   pszText  As String
   hbm      As Long
   cchTextMax As Long
   fmt      As Long
   lParam   As Long
   iImage   As Long
   iOrder   As Long
End Type

Public Enum COMPUTER_NAME_FORMAT
  ComputerNameNetBIOS
  ComputerNameDnsHostname
  ComputerNameDnsDomain
  ComputerNameDnsFullyQualified
  ComputerNamePhysicalNetBIOS
  ComputerNamePhysicalDnsHostname
  ComputerNamePhysicalDnsDomain
  ComputerNamePhysicalDnsFullyQualified
  ComputerNameMax
End Enum

Public Function SetValueEx(ByVal hKey As Long, sValueName As String, _
lType As Long, vValue As Variant) As Long
    Dim lValue As Long
    Dim sValue As String
    Select Case lType
        Case REG_SZ
            sValue = vValue & Chr$(0)
            SetValueEx = RegSetValueExString(hKey, sValueName, 0&, _
                                           lType, sValue, Len(sValue))
        Case REG_DWORD
            lValue = vValue
            SetValueEx = RegSetValueExLong(hKey, sValueName, 0&, _
lType, lValue, 4)
        End Select
End Function

Public Function QueryValueEx(ByVal lhKey As Long, ByVal szValueName As _
String, vValue As Variant) As Long
    Dim cch As Long
    Dim lrc As Long
    Dim lType As Long
    Dim lValue As Long
    Dim sValue As String

    On Error GoTo QueryValueExError

    ' Determine the size and type of data to be read
    lrc = RegQueryValueExNULL(lhKey, szValueName, 0&, lType, 0&, cch)
    If lrc <> ERROR_NONE Then Error 5

    Select Case lType
        ' For strings
        Case REG_SZ:
            sValue = String(cch, 0)

lrc = RegQueryValueExString(lhKey, szValueName, 0&, lType, _
sValue, cch)
            If lrc = ERROR_NONE Then
                vValue = Left$(sValue, cch - 1)
            Else
                vValue = Empty
            End If
        ' For DWORDS
        Case REG_DWORD:
lrc = RegQueryValueExLong(lhKey, szValueName, 0&, lType, _
                            lValue, cch)
            If lrc = ERROR_NONE Then vValue = lValue
        Case Else
            'all other data types not supported
            lrc = -1
    End Select

QueryValueExExit:
    QueryValueEx = lrc
    Exit Function

QueryValueExError:
    Resume QueryValueExExit
End Function

Private Sub CreateNewKey(sNewKeyName As String, lPredefinedKey As Long)
       Dim hNewKey As Long         'handle to the new key
       Dim lRetVal As Long         'result of the RegCreateKeyEx function

       lRetVal = RegCreateKeyEx(lPredefinedKey, sNewKeyName, 0&, _
                 vbNullString, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, _
                 0&, hNewKey, lRetVal)
       RegCloseKey (hNewKey)
   End Sub


Public Sub SetKeyValue(sKeyName As String, sValueName As String, _
   vValueSetting As Variant, lValueType As Long)
       Dim lRetVal As Long         'result of the SetValueEx function
       Dim hKey As Long         'handle of open key

       'open the specified key
       lRetVal = RegOpenKeyEx(HKEY_CURRENT_USER, sKeyName, 0, _
                                 KEY_SET_VALUE, hKey)
       lRetVal = SetValueEx(hKey, sValueName, lValueType, vValueSetting)
       RegCloseKey (hKey)
   End Sub
   
   
'SJM Code for UNC path

Public Function GetConnectionPermissions(ByVal dwPermissions As Long) As String

  'Permissions are only returned a shared
  'resource running with share-level security.
  'A server running user-level security ignores
  'this member, so the function returns
  '"not applicable".
   Dim tmp As String
   
   If (dwPermissions And ACCESS_READ) Then tmp = tmp & "R"
   If (dwPermissions And ACCESS_WRITE) Then tmp = tmp & " W"
   If (dwPermissions And ACCESS_CREATE) Then tmp = tmp & " C"
   If (dwPermissions And ACCESS_DELETE) Then tmp = tmp & " D"
   If (dwPermissions And ACCESS_EXEC) Then tmp = tmp & " E"
   If (dwPermissions And ACCESS_ATRIB) Then tmp = tmp & " A"
   If (dwPermissions And ACCESS_PERM) Then tmp = tmp & " P"

   If Len(tmp) = 0 Then tmp = "n/a"
  
   GetConnectionPermissions = tmp
   
   
End Function


Public Function GetConnectionType(ByVal dwConnectType As Long) As String

  'compare connection type value
   Select Case dwConnectType
      Case STYPE_DISKTREE: GetConnectionType = "disk drive"
      Case STYPE_PRINTQ:   GetConnectionType = "print queue"
      Case STYPE_DEVICE:   GetConnectionType = "communication device"
      Case STYPE_IPC:      GetConnectionType = "ipc"
      Case STYPE_SPECIAL:  GetConnectionType = "administrative"
      Case Else:
         
        'weird case. On my NT2000 machines,
        'I have to do this to identify the
        'IPC$ share type
         Select Case (dwConnectType Xor STYPE_SPECIAL) 'rtns 3 if IPC
            Case STYPE_IPC: GetConnectionType = "ipc"
            Case Else:      GetConnectionType = "undefined"
         End Select
         
   End Select
   
End Function


Public Function GetPointerToByteStringW(ByVal dwData As Long) As String
  
   Dim tmp() As Byte
   Dim tmplen As Long
   
   If dwData <> 0 Then
   
      tmplen = lstrlenW(dwData) * 2
      
      If tmplen <> 0 Then
      
         ReDim tmp(0 To (tmplen - 1)) As Byte
         CopyMemory tmp(0), ByVal dwData, tmplen
         GetPointerToByteStringW = tmp
         
     End If
     
   End If
    
End Function

'SJM Code end

