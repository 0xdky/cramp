Attribute VB_Name = "mProcessID"
Option Explicit

Private Declare Function FindFirstFile Lib "kernel32.dll" Alias "FindFirstFileA" _
                         (ByVal lpFileName As String, lpFindFileData As WIN32_FIND_DATA) As Long

Private Declare Function FindNextFile Lib "kernel32.dll" Alias "FindNextFileA" _
                         (ByVal hFindFile As Long, lpFindFileData As WIN32_FIND_DATA) As Long

Private Declare Function FindClose Lib "kernel32.dll" (ByVal hFindFile As Long) As Long

Private Const FILE_ATTRIBUTE_DIRECTORY = &H10
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
   
   Dim fso
   
   On Error Resume Next
   If redArray = True Then
     ReDim Preserve pidArray(0)
   End If
   
   addValue = False
   cmbBool = False
   SetPath fld 'add a trailing / if there isn't one
   
   fHandle = FindFirstFile(fld & "*", findData) 'find the first file/folder in the root path
   
   'get rid of the nulls
   FileName = findData.cFileName
   FileName = StripNulls(FileName)
   
   'loop until there's nothing left
   Do While Len(FileName) <> 0
      'if this is a subfolder, drop into it
      'If (findData.dwFileAttributes And FILE_ATTRIBUTE_DIRECTORY) = FILE_ATTRIBUTE_DIRECTORY And FileName <> "." And FileName <> ".." Then
         'look me, we're recursing!
      '   SetPIDCombo = SetPIDCombo + SetPIDCombo(fld & "\" & FileName, False)
      'End If
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
Private Function SetPath(instring As String) As String
   'appends a forward slash to a path if needed
   If Right$(instring, 1) <> "/" Then
      instring = instring & "/"
   End If
   SetPath = instring
End Function

Private Function StripNulls(OriginalStr As String) As String
   'strip nulls from a string
   If (InStr(OriginalStr, Chr(0)) > 0) Then
      OriginalStr = Left$(OriginalStr, InStr(OriginalStr, Chr(0)) - 1)
   End If
   StripNulls = OriginalStr
End Function


