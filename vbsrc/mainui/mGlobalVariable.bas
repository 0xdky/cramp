Attribute VB_Name = "mGlobalVariable"
Option Explicit
Public objFSO As New FileSystemObject
Public MyFileStream, ThisFileText, arrFile
Public strCrampPath As String
Public strCLogPath As String
Public perlPath As String
Public perlScript As String
Public strQuery As String
Public strQueryArg As String
Public strSpace As String
Public iFileName As String
Public strSlection As String
Public strRawTick As String
Public FileSize As Long
Public IsFileExist As Boolean

Public Sub IsFileExistAndSize(iFileName, IsFileExist, FileSize)
  Dim FileInfo
  If iFileName <> "" Then
    IsFileExist = objFSO.FileExists(iFileName)
      If IsFileExist <> False Then
        Set FileInfo = objFSO.GetFile(iFileName)
        FileSize = FileInfo.Size
      Else
        FileSize = 0
      End If
  End If
End Sub

Public Sub TestMethod()
End Sub
Public Sub RunPerlScript()
  Dim hInst As Long
    
  If frmMainui.queryText.Text <> "" Then
    strQueryArg = perlPath + strSpace + perlScript + strSpace + frmMainui.queryText.Text
    hInst = Shell(strQueryArg, vbNormalFocus)
    strQueryArg = frmMainui.queryText.Text
  Else
    MsgBox "ERROR :: Query Argument Is Not Exists"
  End If
End Sub
Public Sub CleanUp()
  'objFSO = Nothing
End Sub
Public Sub MoveControls(strVal As String)

  With frmMainui
    Select Case strVal
      Case "THREADS"
           'hide-show controls
           .threadCombo.Visible = True
           .rtCombo.Visible = True
           .addrCombo.Visible = False
           .limitText.Visible = True
           'hide-show lables
           .threadLabel.Visible = True
           .rtLabel.Visible = True
           .addLabel.Visible = False
           .limitLabel.Visible = True
           'move controls
           .limitText.Move 4800, 600
           .appendCheck.Move 5750, 600
           'move lables
           .limitLabel.Move 4800, 360
      Case "ADDR"
           'hide-show controls
           .threadCombo.Visible = False
           .rtCombo.Visible = False
           .addrCombo.Visible = True
           .limitText.Visible = True
           'hide-show lables
           .threadLabel.Visible = False
           .rtLabel.Visible = False
           .addLabel.Visible = True
           .limitLabel.Visible = True
           'move controls
           .addrCombo.Move 2640, 600
           .limitText.Move 3850, 600
           .appendCheck.Move 4800, 600
           'move lables
           .addLabel.Move 2640, 360
           .limitLabel.Move 3850, 360
      Case "STAT"
           'hide-show controls
           .threadCombo.Visible = False
           .rtCombo.Visible = False
           .addrCombo.Visible = False
           .limitText.Visible = False
           'hide-show lables
           .threadLabel.Visible = False
           .rtLabel.Visible = False
           .addLabel.Visible = False
           .limitLabel.Visible = False
           'move controls
           .appendCheck.Move 2640, 600
    End Select
  End With
End Sub
Public Sub SetQueryText(strVal As String)

Dim queryText As String

Select Case strVal
    Case "THREADS"
         queryText = frmMainui.pidCombo.Text + strSpace + strQuery + strSpace _
                     + frmMainui.threadCombo.Text + strSpace + frmMainui.rtCombo.Text _
                     + strSpace + frmMainui.limitText.Text
         strQueryArg = queryText
         If frmMainui.appendCheck.Value = 1 Then
            queryText = queryText + strSpace + UCase(frmMainui.appendCheck.Caption)
         End If
    Case "ADDR"
         queryText = frmMainui.pidCombo.Text + strSpace + strQuery + strSpace _
                     + strVal + strSpace + frmMainui.addrCombo.Text + strSpace _
                     + frmMainui.limitText.Text
         strQueryArg = queryText
         If frmMainui.appendCheck.Value = 1 Then
            queryText = queryText + strSpace + UCase(frmMainui.appendCheck.Caption)
         End If
    Case "STAT"
         queryText = frmMainui.pidCombo.Text + strSpace + strQuery + strSpace + strVal
         strQueryArg = queryText
         If frmMainui.appendCheck.Value = 1 Then
            queryText = queryText + strSpace + UCase(frmMainui.appendCheck.Caption)
         End If
End Select

'MsgBox queryText
If frmMainui.queryCommand.Enabled = True Then
  frmMainui.queryText.Text = queryText
  queryText = ""
End If
End Sub
Public Function ChkValueInArray(tmpArry() As String, tmpStr As String) As Boolean
    Dim iCounter As Integer
    Dim arrValue As String
    
    For iCounter = 0 To UBound(tmpArry)
      arrValue = tmpArry(iCounter)
      If arrValue = tmpStr Then
        ChkValueInArray = False
        Exit For
      Else
        ChkValueInArray = True
      End If
  Next
End Function
Public Sub SetValueInComboBox(tmpArry() As String, tmpStr As String, thisCombo As ComboBox)
  Dim aa As Integer
  Dim strArray As String
  
  thisCombo.Clear
  For aa = 0 To UBound(tmpArry)
    strArray = tmpArry(aa)
    If strArray <> "" Then
      If aa = 0 Then
        thisCombo.Text = strArray
        thisCombo.AddItem (strArray)
      Else
        thisCombo.AddItem (strArray)
      End If
     End If
  Next
      
  'add ALL at the last into the thread combo box
  If tmpStr = "THREADS" Then
    tmpStr = "ALL"
    thisCombo.Text = tmpStr
    thisCombo.AddItem (tmpStr)
  End If
End Sub

Public Sub SetValueInListView()

Dim MyArray
Dim cur As MousePointerConstants
Dim strQuery As String
Dim ss As Integer
Dim aa As Integer

Screen.MousePointer = vbHourglass
aa = 0

With frmMainui
  'clean up list view
  .queryLV.MultiSelect = True
  .queryLV.ListItems.Clear
  .queryLV.View = lvwReport
    
  'run perl script
  RunPerlScript
    
  'insert headers
  AddHeaders
    
  IsFileExistAndSize iFileName, IsFileExist, FileSize
  If IsFileExist <> False And FileSize <> 0 Then
    'read the query.psf file line by line
    Set MyFileStream = objFSO.OpenTextFile(iFileName, 1, False)
      
    Do Until MyFileStream.AtEndOfStream
      strQuery = MyFileStream.ReadLine
        
      MyArray = Split(strQuery, "|", -1, 1)
      If UBound(MyArray) > .queryLV.ColumnHeaders.Count - 1 Then
        'insert headers
        .staCombo.Text = "THREADS"
        AddHeaders
        .staCombo.Text = "STAT"
      End If
        
      For ss = 0 To UBound(MyArray)
        'storing thread
        strQuery = MyArray(ss)
        If ss = 0 Then
          .queryLV.ListItems.Add = strQuery
        Else
          .queryLV.ListItems(aa + 1).SubItems(ss) = strQuery
        End If
      Next
      aa = aa + 1
    Loop
    'Close file
    MyFileStream.Close
    IsFileExist = False
    FileSize = 0
  End If
End With

Screen.MousePointer = vbDefault

End Sub
Public Sub AddHeaders()
Dim clm As ColumnHeader

With frmMainui
  .queryLV.ColumnHeaders.Clear

  If .staCombo.Text = "STAT" Then
    Set clm = .queryLV.ColumnHeaders.Add(, , "MODULE")
    Set clm = .queryLV.ColumnHeaders.Add(, , "FUNC-NAME")
    Set clm = .queryLV.ColumnHeaders.Add(, , "FUNC-ADDR")
    Set clm = .queryLV.ColumnHeaders.Add(, , "NO-CALLS")
    Set clm = .queryLV.ColumnHeaders.Add(, , "TOT-TICKS")
    Set clm = .queryLV.ColumnHeaders.Add(, , "MAXTIME")
  Else
    Set clm = .queryLV.ColumnHeaders.Add(, , "THREAD")
    Set clm = .queryLV.ColumnHeaders.Add(, , "MODULE")
    Set clm = .queryLV.ColumnHeaders.Add(, , "FUNC-NAME")
    Set clm = .queryLV.ColumnHeaders.Add(, , "FUNC-ADDR")
    Set clm = .queryLV.ColumnHeaders.Add(, , "DEPTH")
    Set clm = .queryLV.ColumnHeaders.Add(, , "RET-STATUS")
    Set clm = .queryLV.ColumnHeaders.Add(, , "TIME(ms)")
    If .staCombo.Text = "ADDR" And frmMainui.limitText.Text = -1 Then
      Set clm = .queryLV.ColumnHeaders.Add(, , "COUNT")
    Else
      Set clm = .queryLV.ColumnHeaders.Add(, , "TICKS")
    End If
  End If
End With
End Sub

