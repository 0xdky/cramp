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
  Dim ss As Integer
  ss = 0
  
  gstrSpace = Space(1)
  frmMainui.listitemText.Text = 100
  gDicCountLower = 0
  gDicCountUpper = frmMainui.listitemText.Text
  frmMainui.nextCommand.Enabled = False
  frmMainui.preCommand.Enabled = False
  
  ReDim currsettingArray(0)
  ReDim currsetArrayStat(0)
  ReDim chbstatusArray(11)
  
  For ss = 0 To UBound(chbstatusArray)
    chbstatusArray(ss) = 1
  Next
  
  'get the environment variable "CRAMP_PATH"
  gperlScript = gCRAMPPath + "/bin/profileDB.pl"
  gperlScript = Replace(gperlScript, "\", "/")
  'get the environment variable "CRAMP_LOGPATH"
  gstrCLogPath = Environ("CRAMP_LOGPATH")
  gstrCLogPath = Replace(gstrCLogPath, "\", "/")
  'add a trailing / if there isn't one
  Call SetPath(gstrCLogPath)
  'query.psf file
  giFileName = gstrCLogPath + "query.psf"

  Set gobjFSO = CreateObject("Scripting.FileSystemObject")
  Set gobjDic = CreateObject("Scripting.Dictionary")
  
  'checking for the perl.exe -- in future
  gperlPath = gCRAMPPath + "/TOOLS/PERL/bin/wperl.exe"
  gperlPath = Replace(gperlPath, "\", "/")
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
  
  'set setting
  StoredefaultSetting
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
  Dim ss As Long
  
  ReDim threadArray(0)
  ReDim addrArray(0)
  strAll = "ALL"
  ss = 0
  
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
  ss = 0

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

'***********************************************************
' store check box status
'***********************************************************
Public Sub StoreCheckBoxStatus()
  
  'store check box values of columan hide-show form
  ReDim chbstatusArray(11)
  With frmLVColHS
    chbstatusArray(0) = .threColHSCHB.Value
    chbstatusArray(1) = .funcColHSCHB.Value
    chbstatusArray(2) = .addrColHSCHB.Value
    chbstatusArray(3) = .numColHSCHB.Value
    chbstatusArray(4) = .totticksColHSCHB.Value
    chbstatusArray(5) = .maxtickColHSCHB.Value
    chbstatusArray(6) = .modColHSCHB.Value
    chbstatusArray(7) = .depthColHSCHB.Value
    chbstatusArray(8) = .excepColHSCHB.Value
    chbstatusArray(9) = .timeColHSCHB.Value
    chbstatusArray(10) = .countColHSCHB.Value
    chbstatusArray(11) = .ticksColHSCHB.Value
  End With
  
End Sub

'***********************************************************
' initialize second form
'***********************************************************
Public Sub InitLVColHSForm()
  
  'set check box values in columan hide-show form
  If Not UBound(chbstatusArray) > 0 Then Exit Sub
  
  With frmLVColHS
    .threColHSCHB.Value = chbstatusArray(0)
    .funcColHSCHB.Value = chbstatusArray(1)
    .addrColHSCHB.Value = chbstatusArray(2)
    .numColHSCHB.Value = chbstatusArray(3)
    .totticksColHSCHB.Value = chbstatusArray(4)
    .maxtickColHSCHB.Value = chbstatusArray(5)
    .modColHSCHB.Value = chbstatusArray(6)
    .depthColHSCHB.Value = chbstatusArray(7)
    .excepColHSCHB.Value = chbstatusArray(8)
    .timeColHSCHB.Value = chbstatusArray(9)
    .countColHSCHB.Value = chbstatusArray(10)
    .ticksColHSCHB.Value = chbstatusArray(11)
  End With
End Sub
'***********************************************************
' set the sensitivity of check box
'***********************************************************
Public Sub SetCHBSensitivity()

With frmLVColHS
  .modColHSCHB.Enabled = True
  .funcColHSCHB.Enabled = True
  .addrColHSCHB.Enabled = True
  
  .numColHSCHB.Enabled = False
  .totticksColHSCHB.Enabled = False
  .maxtickColHSCHB.Enabled = False
  .threColHSCHB.Enabled = False
  .depthColHSCHB.Enabled = False
  .excepColHSCHB.Enabled = False
  .timeColHSCHB.Enabled = False
  .countColHSCHB.Enabled = False
  .ticksColHSCHB.Enabled = False

  'If frmMainui.staCombo.Text = "STAT" Then
  If frmMainui.queryLV.ColumnHeaders.Count = 6 Then
    .numColHSCHB.Enabled = True
    .totticksColHSCHB.Enabled = True
    .maxtickColHSCHB.Enabled = True
  Else
    .threColHSCHB.Enabled = True
    .depthColHSCHB.Enabled = True
    .excepColHSCHB.Enabled = True
    .timeColHSCHB.Enabled = True
    If frmMainui.staCombo.Text = "ADDR" And frmMainui.limitText.Text = -1 Then
      .countColHSCHB.Enabled = True
    Else
      .ticksColHSCHB.Enabled = True
    End If
  End If
End With

End Sub

'***********************************************************
' set column position as per the setting
'***********************************************************
Public Sub SetNewColumnPosition()
  Dim ss As Long
  Dim aa As Long
  Dim strStored As String
  Dim strColName As String
  
  ss = 0
  aa = 0
  strStored = ""
  strColName = ""
  'On Error Resume Next
  
  If frmMainui.staCombo.Text = "STAT" And _
     frmMainui.queryLV.ColumnHeaders.Count = 6 Then
    If Not UBound(currsetArrayStat) > 0 Then Exit Sub
    For ss = 0 To UBound(currsetArrayStat)
      strStored = currsetArrayStat(ss)
      For aa = 1 To frmMainui.queryLV.ColumnHeaders.Count
        strColName = frmMainui.queryLV.ColumnHeaders.Item(aa).Text
        If strStored = strColName Then
          frmMainui.queryLV.ColumnHeaders.Item(aa).Position = ss + 1
          Exit For
        End If
      Next
    Next
  Else
    If Not UBound(currsettingArray) > 0 Then Exit Sub
    For ss = 0 To UBound(currsettingArray)
      strStored = currsettingArray(ss)
      For aa = 1 To frmMainui.queryLV.ColumnHeaders.Count
        strColName = frmMainui.queryLV.ColumnHeaders.Item(aa).Text
        If strStored = strColName Then
          'frmMainui.queryLV.ColumnHeaders.Item(aa).Position = ss + 1
          If strStored = "Ticks" And ss + 1 > frmMainui.queryLV.ColumnHeaders.Count Then
            frmMainui.queryLV.ColumnHeaders.Item(aa).Position = ss
          Else
            frmMainui.queryLV.ColumnHeaders.Item(aa).Position = ss + 1
          End If
          Exit For
        End If
      Next
    Next
  End If
  
  frmMainui.queryLV.Refresh
  
  ss = 0
  aa = 0
  strStored = ""
  strColName = ""
End Sub
'***********************************************************
' store setting
'***********************************************************
Public Sub StoreUserSetting()
  Dim colHead As Integer
  Dim ss As Integer
  Dim colPosition As Integer

  ss = 0
  colPosition = 0
  
  colHead = frmMainui.queryLV.ColumnHeaders.Count
  If frmMainui.staCombo.Text = "STAT" Then
    ReDim currsetArrayStat(colHead - 1)
      
    For ss = 0 To colHead - 1
      colPosition = frmMainui.queryLV.ColumnHeaders.Item(ss + 1).Position
      currsetArrayStat(colPosition - 1) = frmMainui.queryLV.ColumnHeaders.Item(ss + 1).Text
    Next
  Else
    ReDim currsettingArray(colHead - 1)

    For ss = 0 To colHead - 1
      colPosition = frmMainui.queryLV.ColumnHeaders.Item(ss + 1).Position
      currsettingArray(colPosition - 1) = frmMainui.queryLV.ColumnHeaders.Item(ss + 1).Text
    Next
  End If
  
  ss = 0
  colPosition = 0
End Sub

'***********************************************************
' store default setting at the start up
'***********************************************************
Public Sub StoredefaultSetting()

'for STAT
ReDim currsetArrayStat(5)
currsetArrayStat(0) = "Module"
currsetArrayStat(1) = "Function"
currsetArrayStat(2) = "Address"
currsetArrayStat(3) = "Number"
currsetArrayStat(4) = "Total ticks"
currsetArrayStat(5) = "Max ticks"

'for THREADS and ADDR
ReDim currsettingArray(8)
currsettingArray(0) = "Thread"
currsettingArray(1) = "Module"
currsettingArray(2) = "Function"
currsettingArray(3) = "Address"
currsettingArray(4) = "Depth"
currsettingArray(5) = "Exception"
currsettingArray(6) = "Time(ns)"
currsettingArray(7) = "Count"
currsettingArray(8) = "Ticks"

End Sub

'***********************************************************
' set column to its original position
'***********************************************************
Public Sub RestoreToDefaultSetting()
  Dim ss As Long
  ss = 0
  For ss = 1 To frmMainui.queryLV.ColumnHeaders.Count
    frmMainui.queryLV.ColumnHeaders.Item(ss).Position = ss
  Next
  ss = 0
End Sub

'***********************************************************
' show hide column
'***********************************************************
Public Sub ShowHideCol()
  
  Dim ss As Integer
  Dim chbVal As Integer
  Dim chbHandle As CheckBox
  
  ss = 0
  chbVal = 0
  
  With frmLVColHS
    For ss = 0 To UBound(chbstatusArray)
      chbVal = chbstatusArray(ss)
      If chbVal = 0 Then
        If ss = 0 Then
          ReorderColumnPosition .threColHSCHB.Caption, False
        ElseIf ss = 1 Then
          ReorderColumnPosition .funcColHSCHB.Caption, False
        ElseIf ss = 2 Then
          ReorderColumnPosition .addrColHSCHB.Caption, False
        ElseIf ss = 3 Then
          ReorderColumnPosition .numColHSCHB.Caption, False
        ElseIf ss = 4 Then
          ReorderColumnPosition .totticksColHSCHB.Caption, False
        ElseIf ss = 5 Then
          ReorderColumnPosition .maxtickColHSCHB.Caption, False
        ElseIf ss = 6 Then
          ReorderColumnPosition .modColHSCHB.Caption, False
        ElseIf ss = 7 Then
          ReorderColumnPosition .depthColHSCHB.Caption, False
        ElseIf ss = 8 Then
          ReorderColumnPosition .excepColHSCHB.Caption, False
        ElseIf ss = 9 Then
          ReorderColumnPosition .timeColHSCHB.Caption, False
        ElseIf ss = 10 Then
          ReorderColumnPosition .countColHSCHB.Caption, False
        ElseIf ss = 11 Then
          ReorderColumnPosition .ticksColHSCHB.Caption, False
        End If
    End If
  Next
  End With
  
  ss = 0
  chbVal = 0

End Sub
'***********************************************************
' set column position as per user setting and show hide col
'***********************************************************
Public Sub ReorderColumnPosition(strCol As String, chbVal As Boolean)
  
  Dim ss As Integer
  Dim collocation As Integer
  Dim strVal As String
  Dim found As Boolean
  
  ss = 0
  collocation = 0
  strVal = ""
  found = False
  
  frmMainui.queryLV.Refresh
  
  'set to original column setting
  RestoreToDefaultSetting
  
  'search for the passed string
  For ss = 1 To frmMainui.queryLV.ColumnHeaders.Count
    strVal = frmMainui.queryLV.ColumnHeaders.Item(ss).Text
    If strVal = strCol Then
      collocation = frmMainui.queryLV.ColumnHeaders.Item(ss).Position
      found = True
      Exit For
    End If
  Next

  'hide-show column
  If found = True Then
    If chbVal = True Then
      frmMainui.queryLV.ColumnHeaders(collocation).Width = 1440
    Else
      frmMainui.queryLV.ColumnHeaders(collocation).Width = 0
    End If
  End If

  'reorder column
  SetNewColumnPosition

  frmMainui.queryLV.Refresh
  
  ss = 0
  collocation = 0
  strVal = ""
  found = False

End Sub




