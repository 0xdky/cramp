Attribute VB_Name = "mInitialization"
Option Explicit
Public Sub SetRTCombo()
  Dim strTick As String
  strTick = "TICK"

  frmMainui.rtCombo.AddItem (frmMainui.rtCombo.Text)
  frmMainui.rtCombo.AddItem (strTick)
  strRawTick = frmMainui.rtCombo.Text
End Sub
Public Sub SetSTACombo()
  Dim strStat As String
  strStat = "STAT"

  frmMainui.staCombo.AddItem (frmMainui.staCombo.Text)
  frmMainui.staCombo.AddItem (strStat)
  frmMainui.staCombo.AddItem (frmMainui.addrCombo.Text)
  strSlection = frmMainui.staCombo.Text
End Sub

Public Sub SetProcessIDCombo()
  Dim folder As Boolean

  folder = objFSO.FolderExists(strCLogPath)

  'if "CRAMP_LOGPATH" exists then get the process id
  If folder = True Then
    Call SetPIDCombo(strCLogPath, True)
  Else
    MsgBox "Folder " + strCLogPath + " Does Not Exists"
  End If
End Sub
Public Sub GetEnvironmentVariable()
  
  strSpace = Space(1)
  strQuery = "QUERY"
  'get the environment variable "CRAMP_PATH"
  strCrampPath = gCRAMPPath
  perlScript = strCrampPath + "/bin/profileDB.pl"
  'get the environment variable "CRAMP_LOGPATH"
  strCLogPath = Environ("CRAMP_LOGPATH")
  strCLogPath = Replace(strCLogPath, "\", "/")
  Set objFSO = CreateObject("Scripting.FileSystemObject")
  
  'checking for the perl.exe -- in future
  perlPath = strCrampPath + "/TOOLS/PERL/bin/wperl.exe"
  IsFileExistAndSize perlPath, IsFileExist, FileSize
  If IsFileExist = False And FileSize = 0 Then
    perlPath = "wperl.exe"
  End If
  
  'checking for the profileDB.pl
  IsFileExistAndSize perlScript, IsFileExist, FileSize
  If IsFileExist = False And FileSize = 0 Then
    MsgBox "ERROR :: profileDB.pl Is Not Found Under " + perlScript + " Folder"
  End If
End Sub

Public Sub SetThreAndAddrCombo()
  Dim MyArray
  Dim strLine As String
  Dim threadArray() As String
  Dim addrArray() As String
  Dim strAll As String
  Dim addValue As Boolean
  Dim cmbBool As Boolean
  Dim ss As Integer
  
  ReDim threadArray(0)
  ReDim addrArray(0)
  strAll = "ALL"
  
  'move query.psf to querynew.psf
  IsFileExistAndSize strCLogPath + "query.psf", IsFileExist, FileSize
  If IsFileExist <> False And FileSize <> 0 Then
    IsFileExistAndSize strCLogPath + "querynew.psf", IsFileExist, FileSize
      If IsFileExist <> False And FileSize <> 0 Then
        objFSO.DeleteFile strCLogPath + "querynew.psf", True
      End If
      objFSO.MoveFile strCLogPath + "query.psf", strCLogPath + "querynew.psf"
  End If

  '1756 QUERY ALL RAW 0
  frmMainui.queryText.Text = frmMainui.pidCombo.Text + strSpace + strQuery + strSpace _
                           + strAll + strSpace + frmMainui.rtCombo.Text + strSpace + _
                           frmMainui.limitText.Text
  'run perl script to get all the threads
  RunPerlScript
  'read query.psf file
  iFileName = strCLogPath + "query.psf"

  IsFileExistAndSize iFileName, IsFileExist, FileSize
  If IsFileExist <> False And FileSize <> 0 Then
    'read the query.psf file line by line
    Set MyFileStream = objFSO.OpenTextFile(iFileName, 1, False)
    cmbBool = False
    Do Until MyFileStream.AtEndOfStream
      strLine = MyFileStream.ReadLine
    
      MyArray = Split(strLine, "|", -1, 1)
      For ss = 0 To UBound(MyArray)
        If ss = 0 Then
          'storing thread
          strLine = MyArray(ss)
          addValue = ChkValueInArray(threadArray(), strLine)
          If addValue = True Then
             threadArray(UBound(threadArray)) = strLine
             ReDim Preserve threadArray(UBound(threadArray) + 1)
             cmbBool = True
          End If
        ElseIf ss = 3 Then
          'storing address
          strLine = MyArray(ss)
          addValue = ChkValueInArray(addrArray(), strLine)
          If addValue = True Then
             addrArray(UBound(addrArray)) = strLine
             ReDim Preserve addrArray(UBound(addrArray) + 1)
             cmbBool = True
          End If
        End If
      Next
    Loop
    
    'Close file
    MyFileStream.Close

    IsFileExist = False
    FileSize = 0
  Else
    'through error of query.psf file is not exists or size is zero
    IsFileExist = False
    FileSize = 0
    cmbBool = False
    MsgBox "File " + iFileName + " Does Not Exists Or Size Is Zero."
  End If
  
  'set thread array into the thread combobox
  If cmbBool = True Then
    strLine = "THREADS"
    Call SetValueInComboBox(threadArray(), strLine, frmMainui.threadCombo)
    strLine = "ADDR"
    Call SetValueInComboBox(addrArray(), strLine, frmMainui.addrCombo)
  End If
  
  ReDim threadArray(0)
  ReDim addrArray(0)

  'move querynew.psf to query.psf
  IsFileExistAndSize strCLogPath + "query.psf", IsFileExist, FileSize
  If IsFileExist <> False And FileSize <> 0 Then
    objFSO.DeleteFile strCLogPath + "query.psf", True
    IsFileExistAndSize strCLogPath + "querynew.psf", IsFileExist, FileSize
    If IsFileExist <> False And FileSize <> 0 Then
      objFSO.MoveFile strCLogPath + "querynew.psf", strCLogPath + "query.psf"
    End If
  End If

End Sub

