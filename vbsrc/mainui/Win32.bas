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

'***********************************************************
' My Code Starts Here
'***********************************************************
Private Declare Function FindFirstFile Lib "kernel32.dll" Alias "FindFirstFileA" _
                         (ByVal lpFileName As String, lpFindFileData As WIN32_FIND_DATA) As Long

Private Declare Function FindNextFile Lib "kernel32.dll" Alias "FindNextFileA" _
                         (ByVal hFindFile As Long, lpFindFileData As WIN32_FIND_DATA) As Long

Private Declare Function FindClose Lib "kernel32.dll" (ByVal hFindFile As Long) As Long

Private Const MAX_PATH = 260

Private Type FILETIME
        dwLowDateTime As Long
        dwHighDateTime As Long
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


Private Sub SetKeyValue(sKeyName As String, sValueName As String, _
   vValueSetting As Variant, lValueType As Long)
       Dim lRetVal As Long         'result of the SetValueEx function
       Dim hKey As Long         'handle of open key

       'open the specified key
       lRetVal = RegOpenKeyEx(HKEY_CURRENT_USER, sKeyName, 0, _
                                 KEY_SET_VALUE, hKey)
       lRetVal = SetValueEx(hKey, sValueName, lValueType, vValueSetting)
       RegCloseKey (hKey)
   End Sub

'***********************************************************
' My Code Starts Here
'***********************************************************

'***********************************************************
' set process id combo box
'***********************************************************
Public Function SetPIDCombo(fld As String, redArray As Boolean) As String

   Dim fHandle As Long
   Dim Location As Integer
   Dim strlength As Integer
   Dim FileName As String
   Dim ProcessID As String
   Dim pidArray() As String
   Dim tmpStr As String
   Dim bRet As Boolean
   Dim addValue As Boolean
   Dim cmbBool As Boolean
   Dim findData As WIN32_FIND_DATA
     
   On Error Resume Next
   If redArray = True Then
     ReDim Preserve pidArray(0)
   End If
   
   addValue = False
   cmbBool = False
   'add a trailing / if there isn't one
   SetPath fld
   'find the first file/folder in the root path
   fHandle = FindFirstFile(fld & "*", findData)
   
   'get rid of the nulls
   FileName = findData.cFileName
   FileName = StripNulls(FileName)
   
   'loop until there's nothing left
   Do While Len(FileName) <> 0
      'get the next one
      bRet = FindNextFile(fHandle, findData)
      'nothing left in this folder so get out
      If bRet = False Then
         Exit Do
      End If
      'get rid of the nulls
      FileName = findData.cFileName
      FileName = StripNulls(FileName)
      tmpStr = Right$(FileName, 3)
      If tmpStr = ".db" Then
        strlength = Len(FileName)
        Location = InStr(FileName, "#")
        Location = strlength - Location
        ProcessID = Right(FileName, Location)
        Location = InStr(ProcessID, ".")
        strlength = Len(ProcessID)
        Location = strlength - Location + 2
        ProcessID = Left(ProcessID, Location)
        addValue = ChkValueInArray(pidArray(), ProcessID)
        If addValue = True Then
          pidArray(UBound(pidArray)) = ProcessID
          ReDim Preserve pidArray(UBound(pidArray) + 1)
          cmbBool = True
        End If
      End If
   Loop
   bRet = FindClose(fHandle)
   
   If cmbBool = True Then
     ProcessID = "PID"
     Call SetValueInComboBox(pidArray(), ProcessID, frmMainui.pidCombo)
     frmMainui.queryCommand.Enabled = True
   Else
     MsgBox "ERROR :: No DataBase Under " + fld + " Folder"
     frmMainui.queryCommand.Enabled = False
   End If
End Function
'***********************************************************
' add / at the end of the path if it is not there
'***********************************************************
Public Function SetPath(instring As String) As String
   'appends a forward slash to a path if needed
   If Right$(instring, 1) <> "/" Then
      instring = instring & "/"
   End If
   SetPath = instring
End Function

'***********************************************************
' strip nulls from the string
'***********************************************************
Private Function StripNulls(OriginalStr As String) As String
   'strip nulls from a string
   If (InStr(OriginalStr, Chr(0)) > 0) Then
      OriginalStr = Left$(OriginalStr, InStr(OriginalStr, Chr(0)) - 1)
   End If
   StripNulls = OriginalStr
End Function


