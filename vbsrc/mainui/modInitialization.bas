Attribute VB_Name = "modInitialization"
Option Explicit
'***********************************************************
' set raw-tick combo box
'***********************************************************
Public Sub SetRTCombo()
  Dim strTickRaw As String
  strTickRaw = "TICK"
  frmMainui.rtCombo.AddItem (strTickRaw)
  strTickRaw = "RAW"
  frmMainui.rtCombo.AddItem (strTickRaw)
  frmMainui.rtCombo.ListIndex = 0
End Sub
'***********************************************************
' set stat-threads-addr combo box
'***********************************************************
Public Sub SetSTACombo()
  Dim strSTA As String
  
  strSTA = "STAT"
  frmMainui.staCombo.AddItem (strSTA)
  strSTA = "THREADS"
  frmMainui.staCombo.AddItem (strSTA)
  'strSTA = "ADDR"
  'frmMainui.staCombo.AddItem (strSTA)

  frmMainui.staCombo.ListIndex = 0
End Sub
'***********************************************************
' set process id combo box
'***********************************************************
Public Sub SetProcessIDCombo()
  Dim folder As Boolean

  folder = gobjFSO.FolderExists(gstrCLogPath)

  'if "CRAMP_LOGPATH" exists then get the process id
  If folder = True Then
    SetPIDCombo (gstrCLogPath)
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
  gPrevQuery = ""
  gSPrevQuery = ""
  frmMainui.backCommand.Enabled = False
  frmMainui.listitemText.Text = 100
  gDicCountLower = 0
  gDicCountUpper = frmMainui.listitemText.Text
  frmMainui.nextCommand.Enabled = False
  frmMainui.preCommand.Enabled = False
  
  ReDim currsettingArray(0)
  ReDim currsetArrayStat(0)
  ReDim chbstatusArray(12)
  
  For ss = 0 To UBound(chbstatusArray)
    chbstatusArray(ss) = 1
  Next
  
  'get the environment variable "CRAMP_PATH"
  gperlScript = gCRAMPPath + "/bin/profileDQ.pl"
  gperlScript = Replace(gperlScript, "\", "/")
  'get the environment variable "CRAMP_LOGPATH"
  gstrCLogPath = Environ("CRAMP_LOGPATH")
  gstrCLogPath = Replace(gstrCLogPath, "\", "/")
  'set sort perl script path
  gquerySort = gCRAMPPath + "/bin/querysort.pl"
  gquerySort = Replace(gquerySort, "\", "/")
  'add a trailing / if there isn't one
  Call SetPath(gstrCLogPath)
  'query.psf file
  giFileName = gstrCLogPath + "query.psf"

  Set gobjFSO = CreateObject("Scripting.FileSystemObject")
  Set gobjDic = CreateObject("Scripting.Dictionary")
  
  'checking for the wperl.exe
  gperlPath = gCRAMPPath + "/TOOLS/PERL/bin/wperl.exe"
  gperlPath = Replace(gperlPath, "\", "/")
  IsFileExistAndSize gperlPath, gIsFileExist, gFileSize
  If gIsFileExist = False And gFileSize = 0 Then
    gperlPath = "wperl.exe"
  End If
  
  'checking for the profileDQ.pl
  IsFileExistAndSize gperlScript, gIsFileExist, gFileSize
  If gIsFileExist = False And gFileSize = 0 Then
    MsgBox "ERROR :: profileDQ.pl Is Not Found Under " & gCRAMPPath & _
                     "\bin" & " Folder"
  End If
  
  'checking for the querysort.pl
  IsFileExistAndSize gquerySort, gIsFileExist, gFileSize
  If gIsFileExist = False And gFileSize = 0 Then
    MsgBox "ERROR :: querysort.pl Is Not Found Under " & gCRAMPPath & _
                     "\bin" & " Folder"
  End If
  
  'set setting
  StoredefaultSetting
  'load frmlvcolhs form
  Load frmLVColHS
  'set check box status
  InitLVColHSForm
  frmLVColHS.Visible = False
    
  gIsFileExist = False
  gFileSize = 0
  
  'check for CRAMP_DEBUG
  If Environ("CRAMP_DEBUG") <> "" Then
    frmMainui.queryText.Enabled = True
  End If
  
  'get computer name
  GetLocalComputerName

End Sub

'***********************************************************
' set thread into udt pid
'***********************************************************
Public Sub GetAllThreads(pidPosition As Long, strPID As String)
  Dim MyArray, MyFileStream, ThisFileText, arrFile
  Dim strLine As String
  Dim strDB As String
  Dim addValue As Boolean
  Dim cmbBool As Boolean
  Dim ss As Long
  Dim pidHand As udtPID
  
  ss = 0
  
  On Error Resume Next
  
  If pidPosition < 0 Then Exit Sub
  If strPID = "" Then Exit Sub
  
  strDB = "cramp#" & strPID & ".db"
  strDB = gstrCLogPath & strDB
  IsFileExistAndSize strDB, gIsFileExist, gFileSize
  If gIsFileExist = False And gFileSize = 0 Then
    Exit Sub
  End If
  
  pidHand = pidArray(pidPosition)
  ReDim pidHand.thrArray(0)
  
  'pid QUERY ALL TICK 0
  frmMainui.queryText.Text = strPID & gstrSpace & "QUERY" & gstrSpace & "THREADS"
    
  'run perl script to get all the threads
  RunPerlScriptWithCP

  IsFileExistAndSize giFileName, gIsFileExist, gFileSize
  If gIsFileExist <> False And gFileSize <> 0 Then
    'read the query.psf file line by line
    Set MyFileStream = gobjFSO.OpenTextFile(giFileName, 1, False)
    cmbBool = False
    Do Until MyFileStream.AtEndOfStream
      strLine = MyFileStream.ReadLine
      'check for duplicate entry
      addValue = ChkValueInArray(pidHand, strLine)
      If addValue = True Then
        pidHand.thrArray(UBound(pidHand.thrArray)) = strLine
        ReDim Preserve pidHand.thrArray(UBound(pidHand.thrArray) + 1)
        cmbBool = True
      End If
    Loop
    
    'Close file
     MyFileStream.Close
     pidArray(pidPosition) = pidHand

    gIsFileExist = False
    gFileSize = 0
  Else
    'through error of query.psf file is not exists or size is zero
    gIsFileExist = False
    gFileSize = 0
    cmbBool = False
    'MsgBox "File " + giFileName + " does not exists Or size is zero."
  End If
  
  ss = 0
  
End Sub

'***********************************************************
' store check box status
'***********************************************************
Public Sub StoreCheckBoxStatus()
  
  'store check box values of columan hide-show form
  ReDim chbstatusArray(12)
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
    chbstatusArray(10) = .ticksColHSCHB.Value
    chbstatusArray(11) = .posiColHSCHB.Value
    chbstatusArray(12) = .tpsecColHSCHB.Value
  End With
  
End Sub

'***********************************************************
' initialize second form
'***********************************************************
Public Sub InitLVColHSForm()
  
  On Error Resume Next
  
  'set check box values in columan hide-show form
  If Not UBound(chbstatusArray) = 12 Then Exit Sub
  
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
    .ticksColHSCHB.Value = chbstatusArray(10)
    .posiColHSCHB.Value = chbstatusArray(11)
    .tpsecColHSCHB.Value = chbstatusArray(12)
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
  .ticksColHSCHB.Enabled = False
  .posiColHSCHB.Enabled = False
  .tpsecColHSCHB.Enabled = False

  'If frmMainui.staCombo.Text = "STAT" Then
  If frmMainui.queryLV.ColumnHeaders.Count = 7 Then
    .numColHSCHB.Enabled = True
    .totticksColHSCHB.Enabled = True
    .maxtickColHSCHB.Enabled = True
    .tpsecColHSCHB.Enabled = True
  Else
    .threColHSCHB.Enabled = True
    .depthColHSCHB.Enabled = True
    .excepColHSCHB.Enabled = True
    .timeColHSCHB.Enabled = True
    .posiColHSCHB.Enabled = True
    .ticksColHSCHB.Enabled = True
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
  
  On Error Resume Next
  
  If frmMainui.staCombo.Text = "STAT" And _
     frmMainui.queryLV.ColumnHeaders.Count = 7 Then
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
  
  On Error Resume Next
  
  colHead = frmMainui.queryLV.ColumnHeaders.Count
  If frmMainui.queryLV.ColumnHeaders.Count = 7 Then 'STAT
    ReDim currsetArrayStat(colHead - 1)
      
    For ss = 0 To colHead - 1
      colPosition = frmMainui.queryLV.ColumnHeaders.Item(ss + 1).Position
      currsetArrayStat(colPosition - 1) = frmMainui.queryLV.ColumnHeaders.Item(ss + 1).Text
    Next
  Else 'THREADS/ADDR
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
ReDim currsetArrayStat(6)
currsetArrayStat(0) = "Module"
currsetArrayStat(1) = "Function"
currsetArrayStat(2) = "Address"
currsetArrayStat(3) = "Number"
currsetArrayStat(4) = "Ticks/sec"
currsetArrayStat(5) = "Total ticks"
currsetArrayStat(6) = "Max ticks"

'for THREADS and ADDR
ReDim currsettingArray(9)
currsettingArray(0) = "Position"
currsettingArray(1) = "Thread"
currsettingArray(2) = "Module"
currsettingArray(3) = "Function"
currsettingArray(4) = "Address"
currsettingArray(5) = "Depth"
currsettingArray(6) = "Raw Ticks"
currsettingArray(7) = "Time(ns)"
currsettingArray(8) = "Count"
currsettingArray(9) = "Ticks"

End Sub

'***********************************************************
' show hide column
'***********************************************************
Public Sub ShowHideCol()
  
  Dim ss As Integer
  Dim chbVal As Integer
  
  ss = 0
  chbVal = 0
  
  On Error Resume Next
  
  If Not UBound(chbstatusArray) = 12 Then Exit Sub
  
  With frmLVColHS
    For ss = 0 To UBound(chbstatusArray)
      chbVal = chbstatusArray(ss)
      If chbVal = 0 Then
        Select Case ss
            Case 0
              ReorderColumnPosition "Thread", False
            Case 1
              ReorderColumnPosition "Function", False
            Case 2
              ReorderColumnPosition "Address", False
            Case 3
              ReorderColumnPosition "Number", False
            Case 4
              ReorderColumnPosition "Total ticks", False
            Case 5
              ReorderColumnPosition "Max ticks", False
            Case 6
              ReorderColumnPosition "Module", False
            Case 7
              ReorderColumnPosition "Depth", False
            Case 8
              ReorderColumnPosition "Raw Ticks", False
            Case 9
              ReorderColumnPosition "Time(ns)", False
            Case 10
              ReorderColumnPosition "Ticks", False
            Case 11
              ReorderColumnPosition "Position", False
            Case 12
              ReorderColumnPosition "Ticks/sec", False
        End Select
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
  Dim strVal As String
  
  ss = 0
  strVal = ""
  
  On Error Resume Next
  
  With frmMainui
    .queryLV.Refresh
  
    'show hide column
    For ss = 1 To .queryLV.ColumnHeaders.Count
      strVal = .queryLV.ColumnHeaders.Item(ss).Text
      If strVal = strCol Then
        If chbVal = True Then
          .queryLV.ColumnHeaders(.queryLV.ColumnHeaders.Item(ss).index).Width = 1440
        Else
          .queryLV.ColumnHeaders(.queryLV.ColumnHeaders.Item(ss).index).Width = 0
        End If
        Exit For
      End If
    Next

    'reorder column
    SetNewColumnPosition

    .queryLV.Refresh
  End With
  
  ss = 0
  strVal = ""

End Sub

'***********************************************************
' set action combo box
'***********************************************************
Public Sub SetActionCB()
  Dim strQueDump As String
  strQueDump = "QUERY"
  frmMainui.actionCombo.AddItem (strQueDump)
  strQueDump = "DUMP"
  frmMainui.actionCombo.AddItem (strQueDump)
  frmMainui.actionCombo.ListIndex = 0
End Sub

'***********************************************************
' set table combo box
'***********************************************************
Public Sub SetTableCB()
  Dim strDump As String
  strDump = "ALL"
  frmMainui.tableCombo.AddItem (strDump)
  strDump = "ADDR"
  frmMainui.tableCombo.AddItem (strDump)
  strDump = "TICK"
  frmMainui.tableCombo.AddItem (strDump)
  strDump = "STAT"
  frmMainui.tableCombo.AddItem (strDump)
  frmMainui.tableCombo.ListIndex = 0
End Sub

'***********************************************************
' set process id combo box
'***********************************************************
Public Function SetPIDCombo(fld As String) As String

   Dim fHandle As Long
   Dim Location As Long
   Dim strLength As Long
   Dim FileName As String
   Dim ProcessID As String
   Dim tmpStr As String
   Dim bRet As Boolean
   Dim addValue As Boolean
   Dim cmbBool As Boolean
   Dim processidArray() As String
   Dim findData As WIN32_FIND_DATA
     
   On Error Resume Next
   ReDim Preserve pidArray(0)
   ReDim Preserve processidArray(0)
   
   addValue = False
   cmbBool = False
   fHandle = 0
   Location = 0
   strLength = 0
   frmMainui.pidCombo.Clear
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
      tmpStr = gstrCLogPath & FileName
      tmpStr = Replace(tmpStr, "\", "/")
      IsFileExistAndSize tmpStr, gIsFileExist, gFileSize
      If gIsFileExist <> False And gFileSize <> 0 Then
       'tmpStr = Right$(FileName, 3)
       tmpStr = Right$(FileName, 4)
       'If tmpStr = ".db" Then
       If tmpStr = ".log" Then
        strLength = Len(FileName)
        Location = InStr(FileName, "#")
        Location = strLength - Location
        ProcessID = Right(FileName, Location)
        Location = InStr(ProcessID, ".")
        strLength = Len(ProcessID)
        'Location = strLength - 3        '3 for .db
        Location = strLength - 4        '4 for .log
        ProcessID = Left(ProcessID, Location)
        addValue = ChkDuplicateValueInArray(processidArray(), ProcessID)
        If IsNumeric(ProcessID) And addValue = True Then
          
          processidArray(UBound(processidArray)) = ProcessID
          ReDim Preserve processidArray(UBound(processidArray) + 1)
        
          Dim X As udtPID
          pidArray(UBound(pidArray)) = X
          If cmbBool = False Then
            frmMainui.pidCombo.Text = ProcessID
          End If
          frmMainui.pidCombo.AddItem (ProcessID)
          GetAllThreads UBound(pidArray), ProcessID
          ReDim Preserve pidArray(UBound(pidArray) + 1)
          cmbBool = True
        End If
      End If
     End If
     gIsFileExist = False
     gFileSize = 0
   Loop
   bRet = FindClose(fHandle)
   
   If cmbBool = True Then
     Dim pidHand As udtPID
     pidHand = pidArray(0)
     SetValueInComboBox pidHand, frmMainui.threadCombo
     frmMainui.pidCombo.ListIndex = 0
     frmMainui.queryCommand.Enabled = True
   Else
     MsgBox "ERROR :: No log files Under " + fld + " Folder"
     frmMainui.queryCommand.Enabled = False
   End If
   
   fHandle = 0
   Location = 0
   strLength = 0
   cmbBool = False
   Erase processidArray
   
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
Public Function StripNulls(OriginalStr As String) As String
   'strip nulls from a string
   If (InStr(OriginalStr, Chr(0)) > 0) Then
      OriginalStr = Left$(OriginalStr, InStr(OriginalStr, Chr(0)) - 1)
   End If
   StripNulls = OriginalStr
End Function

'icon code start - pie
'***********************************************************
' show icon on header
'***********************************************************
Public Sub ShowSortIconInLVHeader(list As MSComctlLib.ListView, _
                                  imgIconNo As Integer)
    
    Dim col As MSComctlLib.ColumnHeader
    Dim lAlignment As Long
    
    'set all column header to off
    For Each col In list.ColumnHeaders
      With col
        lAlignment = GetColHeaderAlignment(col)
        ShowIcon .index, 0, bHide, list, lAlignment
      End With
    Next
    ShowIcon list.SortKey + 1, imgIconNo, bShow, list, lAlignment
End Sub

'***********************************************************
' get column header alignment
'***********************************************************
Public Function GetColHeaderAlignment(col As MSComctlLib.ColumnHeader)
' Get the columns current alignment
    With col
        Select Case .Alignment
            Case lvwColumnRight
                GetColHeaderAlignment = HDF_RIGHT
            Case lvwColumnCenter
                GetColHeaderAlignment = HDF_CENTER
            Case Else
                GetColHeaderAlignment = HDF_LEFT
        End Select
    End With
End Function

'***********************************************************
' show icon
'***********************************************************
Public Sub ShowIcon(colNo As Long, imgIconNo As Integer, bShowIcon As enumShowHide, list As MSComctlLib.ListView, lAlignment As Long)
    Dim lHeader As Long
    Dim HD      As HDITEM
    
    'get a handle if listview header
    lHeader = SendMessage(list.hwnd, LVM_GETHEADER, 0, ByVal 0)
    
    'set structure
    With HD
        .mask = HDI_IMAGE Or HDI_FORMAT
        
        If bShowIcon Then
            .fmt = HDF_STRING Or HDF_IMAGE Or HDF_BITMAP_ON_RIGHT
            .iImage = imgIconNo
        Else
            .fmt = HDF_STRING
        End If
        .fmt = .fmt Or lAlignment
    End With
    
    'modify the header icon
    Call SendMessage(lHeader, HDM_SETITEM, colNo - 1, HD)
   
End Sub

'***********************************************************
' get icon number to display
'***********************************************************
Public Function GetIconNumber(imgNo As Integer) As Integer
  
  If imgNo = lvwAscending Then
      GetIconNumber = lvwDescending
  Else
      GetIconNumber = lvwAscending
  End If

End Function

'***********************************************************
' get current cursor position
'***********************************************************
Public Sub GetCurrCursorPosition(x_cor As Long, y_cor As Long)

  Dim mouse As POINTCORD
  GetCursorPos mouse
  x_cor = mouse.X
  y_cor = mouse.Y

End Sub

'icon code end - pie


'***********************************************************
' checking for the duplicate entry in the array
'***********************************************************
Public Function ChkDuplicateValueInArray(processidArray() As String, tmpStr As String) As Boolean
    Dim iCounter As Integer
    Dim arrValue As String
    
    iCounter = 0
    arrValue = ""
    
    On Error Resume Next
    
    If UBound(processidArray) < 0 Then Exit Function
    
    For iCounter = 0 To UBound(processidArray)
      arrValue = processidArray(iCounter)
      If arrValue = tmpStr Then
        ChkDuplicateValueInArray = False
        Exit For
      Else
        ChkDuplicateValueInArray = True
      End If
  Next
End Function

'***********************************************************
' get the local computer name
'***********************************************************
Public Sub GetLocalComputerName()
    Dim pc_name As String
    pc_name = String(50, Chr(0))
    
    GetComputerNameEx ComputerNamePhysicalDnsFullyQualified, pc_name, 50
    StripNulls pc_name
    pc_name = Trim(pc_name)
    'MsgBox pc_name
    
    If pc_name <> "" Then
      frmMainui.compnameText.Text = pc_name
    End If
    
End Sub



