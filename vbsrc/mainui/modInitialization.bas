Attribute VB_Name = "modInitialization"
Option Explicit
'***********************************************************
' set raw-tick combo box
'***********************************************************
Public Sub SetRTCombo()
  Dim strRaw As String
  strRaw = "RAW"

  frmMainui.rtCombo.AddItem (frmMainui.rtCombo.Text)
  frmMainui.rtCombo.AddItem (strRaw)
  gstrRawTick = frmMainui.rtCombo.Text
End Sub
'***********************************************************
' set stat-threads-addr combo box
'***********************************************************
Public Sub SetSTACombo()
  Dim strStat As String
  Dim strAddr As String
  strStat = "STAT"
  strAddr = "ADDR"

  frmMainui.staCombo.AddItem (frmMainui.staCombo.Text)
  frmMainui.staCombo.AddItem (strStat)
  frmMainui.staCombo.AddItem (strAddr)
  gstrSlection = frmMainui.staCombo.Text
End Sub
'***********************************************************
' set process id combo box
'***********************************************************
Public Sub SetProcessIDCombo()
  Dim folder As Boolean

  folder = gobjFSO.FolderExists(gstrCLogPath)

  'if "CRAMP_LOGPATH" exists then get the process id
  If folder = True Then
    Call SetPIDCombo(gstrCLogPath, True)
  Else
    MsgBox "Folder " + gstrCLogPath + " Does Not Exists"
  End If
End Sub
'***********************************************************
' get and set variables
'***********************************************************
Public Sub GetEnvironmentVariable()
  gstrSpace = Space(1)
  'get the environment variable "CRAMP_PATH"
  gperlScript = gCRAMPPath + "/bin/profileDB.pl"
  'get the environment variable "CRAMP_LOGPATH"
  gstrCLogPath = Environ("CRAMP_LOGPATH")
  gstrCLogPath = Replace(gstrCLogPath, "\", "/")
  'add a trailing / if there isn't one
  Call SetPath(gstrCLogPath)
  'query.psf file
  giFileName = gstrCLogPath + "query.psf"

  Set gobjFSO = CreateObject("Scripting.FileSystemObject")
  
  'checking for the perl.exe -- in future
  gperlPath = gCRAMPPath + "/TOOLS/PERL/bin/wperl.exe"
  IsFileExistAndSize gperlPath, gIsFileExist, gFileSize
  If gIsFileExist = False And gFileSize = 0 Then
    gperlPath = "wperl.exe"
  End If
  
  'checking for the profileDB.pl
  IsFileExistAndSize gperlScript, gIsFileExist, gFileSize
  If gIsFileExist = False And gFileSize = 0 Then
    MsgBox "ERROR :: profileDB.pl Is Not Found Under " + gperlScript + " Folder"
  End If
  
  'start
  starstopBool = True
End Sub

'***********************************************************
' set thread and address combo box
'***********************************************************
Public Sub SetThreAndAddrCombo()
  Dim MyArray, MyFileStream, ThisFileText, arrFile
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
  IsFileExistAndSize gstrCLogPath + "query.psf", gIsFileExist, gFileSize
  If gIsFileExist <> False And gFileSize <> 0 Then
    IsFileExistAndSize gstrCLogPath + "querynew.psf", gIsFileExist, gFileSize
      If gIsFileExist <> False And gFileSize <> 0 Then
        gobjFSO.DeleteFile gstrCLogPath + "querynew.psf", True
      End If
      gobjFSO.MoveFile gstrCLogPath + "query.psf", gstrCLogPath + "querynew.psf"
  
      gIsFileExist = False
      gFileSize = 0
  End If

  'pid QUERY ALL TICK 0
  frmMainui.queryText.Text = frmMainui.pidCombo.Text + gstrSpace + "QUERY" + gstrSpace _
                           + strAll + gstrSpace + frmMainui.rtCombo.Text + gstrSpace + _
                           frmMainui.limitText.Text
    
  'run perl script to get all the threads
  'RunPerlScript
  RunPerlScriptWithCP

  IsFileExistAndSize giFileName, gIsFileExist, gFileSize
  If gIsFileExist <> False And gFileSize <> 0 Then
    'read the query.psf file line by line
    Set MyFileStream = gobjFSO.OpenTextFile(giFileName, 1, False)
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

    gIsFileExist = False
    gFileSize = 0
  Else
    'through error of query.psf file is not exists or size is zero
    gIsFileExist = False
    gFileSize = 0
    cmbBool = False
    MsgBox "File " + giFileName + " Does Not Exists Or Size Is Zero."
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
  IsFileExistAndSize gstrCLogPath + "query.psf", gIsFileExist, gFileSize
  If gIsFileExist <> False And gFileSize <> 0 Then
    gobjFSO.DeleteFile gstrCLogPath + "query.psf", True
    IsFileExistAndSize gstrCLogPath + "querynew.psf", gIsFileExist, gFileSize
    If gIsFileExist <> False And gFileSize <> 0 Then
      gobjFSO.MoveFile gstrCLogPath + "querynew.psf", gstrCLogPath + "query.psf"
    End If
    gIsFileExist = False
    gFileSize = 0
  End If
End Sub

