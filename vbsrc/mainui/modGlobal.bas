Attribute VB_Name = "modGlobal"
Option Explicit
Public ADOXcatalog As New ADOX.Catalog
Public gTEMPDir As String
Public gCRAMPPath As String
Public gIdCounter As Long
Public gIdList(1000) As String
Public gNameList(1000) As String
Public gDatabaseName As String
Public gCurFileName As String
Public gCurScenarioName As String
Public gListViewNode As Node
Public gSaveFlag As Boolean
Public gMRUList(1, 3) As String
Public gMRUListCtr As Integer
Public gGrpIdRef(1000, 1) As String
Public gTcIdRef(1000, 1) As String
Public gIdRef As New Collection

Public Enum ObjectType
    otNone = 0
    otScenario = 1
    otGroup = 2
    otTestcase = 3
End Enum

'***********************************************************
' My Code Starts Here
'***********************************************************
Public gobjFSO As New FileSystemObject
Public gobjDic As New Dictionary
Public gstrCLogPath As String
Public gperlPath As String
Public gperlScript As String
Public gquerySort As String
Public gstrSpace As String
Public giFileName As String
Public currsettingArray() As String
Public currsetArrayStat() As String
Public chbstatusArray() As String
Public pidArray() As udtPID
Public gFileSize As Long
Public gDicCountUpper As Long
Public gDicCountLower As Long
Public gIsFileExist As Boolean

Public Type udtPID
  thrArray() As String
End Type


'****************************************************
' Return the node's object type
'****************************************************
Public Function nodetype(testNode As Node) As ObjectType
    If testNode Is Nothing Then
        nodetype = otNone
    Else
        Select Case Left$(testNode.key, 1)
            Case "s"
                nodetype = otScenario
            Case "g"
                nodetype = otGroup
            Case "t"
                nodetype = otTestcase
        End Select
    End If
End Function

'****************************************************
' Returns NodeName
'****************************************************
Public Function GetNodeName(tblType As ObjectType) As String
    Select Case tblType
        Case otNone
            GetNodeName = ""
        Case otScenario
            GetNodeName = "Scenario"
        Case otGroup
            GetNodeName = "Group"
        Case otTestcase
            GetNodeName = "Testcase"
    End Select

End Function

Public Sub SetVisible()
    frmMainui.cboTrueFalse.Visible = False
    frmMainui.cboIdRef.Visible = False
    frmMainui.txtInput.Visible = False
    frmMainui.cmdBrowse.Visible = False

End Sub

'************************************************************
'
'************************************************************
Public Function GenerateId(tblType As ObjectType) As String
    Dim intId As Integer
    Dim tmpId As String
    Dim ii As Integer
    Dim bSuccess As Boolean

    Do
        bSuccess = True
        intId = Int(Rnd * 1000)

        Select Case tblType
            Case otNone
                GenerateId = ""
            Case otScenario
                tmpId = "s" & intId
            Case otGroup
                tmpId = "g" & intId
            Case otTestcase
                tmpId = "t" & intId
        End Select
        For ii = 0 To gIdCounter - 1
            If gIdList(ii) = tmpId Then
                bSuccess = False
                Exit For
            End If
        Next ii
    Loop Until bSuccess = True

    GenerateId = tmpId

End Function

'************************************************************
'
'************************************************************
Public Function NewRecordName(tblType As ObjectType) As String
    Dim nodeName As String
    Dim ii As Integer
    Dim bSuccess As Boolean
    Dim index As Integer
    Dim tmpName As String

    Select Case tblType
        Case otNone
            nodeName = ""
        Case otScenario
            NewRecordName = "Scenario"
            Exit Function
        Case otGroup
            nodeName = "Group."
        Case otTestcase
            nodeName = "Testcase."
    End Select
    index = 1
    Do
        tmpName = nodeName & index
        bSuccess = True
        For ii = 0 To gIdCounter - 1
            If gNameList(ii) = tmpName Then
                bSuccess = False
                Exit For
            End If
        Next ii
        index = index + 1
    Loop Until bSuccess = True

    NewRecordName = tmpName

End Function

'************************************************************
'
'************************************************************
Public Sub ReinitialiseIds()
    Dim ii, jj As Integer
    For ii = 0 To 1000 - 1
        gIdList(ii) = ""
        gNameList(ii) = ""
        For jj = 0 To 1
            gGrpIdRef(ii, jj) = ""
            gTcIdRef(ii, jj) = ""
        Next jj
    Next ii
    gIdCounter = 0

End Sub

'************************************************************
'
'************************************************************
Public Sub IncreaseGlobalCounters(ByVal selectedNode As Node)
    gIdList(gIdCounter) = selectedNode.key
    gNameList(gIdCounter) = selectedNode.Text
    gIdCounter = gIdCounter + 1

End Sub

'************************************************************
'
'************************************************************
Public Sub UpdateGlobalCounters(ByVal selectedNode As Node)
    Dim ii As Integer

    For ii = 0 To gIdCounter - 1
        If gNameList(ii) = selectedNode.Text Then
            gNameList(ii) = gNameList(gIdCounter - 1)
            gNameList(gIdCounter - 1) = ""
        End If
        If gIdList(ii) = selectedNode.key Then
            gIdList(ii) = gIdList(gIdCounter - 1)
            gIdList(gIdCounter - 1) = ""
        End If
    Next ii
    gIdCounter = gIdCounter - 1

End Sub

'************************************************************
'
'************************************************************
Public Sub DeleteGlobalCounters(ByVal selectedNode As Node)
    Dim ii As Integer

    For ii = 0 To gIdCounter - 1
        If gNameList(ii) = selectedNode.Text Then
            gNameList(ii) = gNameList(gIdCounter - 1)
            gNameList(gIdCounter - 1) = ""
        End If
        If gIdList(ii) = selectedNode.key Then
            gIdList(ii) = gIdList(gIdCounter - 1)
            gIdList(gIdCounter - 1) = ""
        End If
    Next ii
    gIdCounter = gIdCounter - 1

End Sub

'************************************************************
'
'************************************************************
Public Sub SetActionButtons()
    Dim selectedNode As Node
    Dim nodeName As String

    Set selectedNode = frmMainui.tvwNodes.SelectedItem

    If selectedNode Is Nothing Then
        Exit Sub
    End If

    nodeName = selectedNode.key

    Select Case Left$(nodeName, 1)
        Case "s"
            frmMainui.cmdAddGroup.Enabled = True
            frmMainui.cmdAddTc.Enabled = True
            frmMainui.cmdDelete.Enabled = False
            frmMainui.cmdDelete.Caption = "&Delete"
        Case "g"
            frmMainui.cmdAddGroup.Enabled = True
            frmMainui.cmdAddTc.Enabled = True
            frmMainui.cmdDelete.Enabled = True
            frmMainui.cmdDelete.Caption = "&Delete Group"

        Case "t"
            frmMainui.cmdAddGroup.Enabled = False
            frmMainui.cmdAddTc.Enabled = False
            frmMainui.cmdDelete.Enabled = True
            frmMainui.cmdDelete.Caption = "&Delete Testcase"

    End Select

End Sub

Public Sub InitialiseListView()
    Dim colX As ColumnHeader ' Declare variable.

    frmMainui.lvwAttributes.ColumnHeaders.Clear

    frmMainui.lvwAttributes.ColumnHeaders.Add , , _
                        "Property", frmMainui.lvwAttributes.Width / 3
    frmMainui.lvwAttributes.ColumnHeaders.Add , , _
                        "Value", 2 * frmMainui.lvwAttributes.Width / 3 - 100

    frmMainui.lvwAttributes.View = lvwReport


End Sub

Public Sub SetGlobalVariables()
    Dim retVal As Long

    gCRAMPPath = Environ("CRAMP_PATH")
    If (0 = Len(gCRAMPPath)) Then
        gCRAMPPath = App.Path & "\..\"
    Else
        While ("\" = Right$(gCRAMPPath, 1) Or "/" = Right$(gCRAMPPath, 1))
            gCRAMPPath = Left$(gCRAMPPath, Len(gCRAMPPath) - 1)
        Wend
    End If

    gTEMPDir = Space$(256)
    retVal = GetTempPath(Len(gTEMPDir), gTEMPDir)
    If (0 = retVal) Then
        gTEMPDir = gCRAMPPath & "\tmp"
        MkDir gTEMPDir
    Else
        gTEMPDir = Left$(gTEMPDir, retVal)
        While ("\" = Right$(gTEMPDir, 1) Or "/" = Right$(gTEMPDir, 1))
            gTEMPDir = Left$(gTEMPDir, Len(gTEMPDir) - 1)
        Wend
    End If

    gDatabaseName = gTEMPDir & "\CRAMPDB.mdb"

    frmMainui.mnuSave.Enabled = False
    frmMainui.cmdRun.Enabled = False
    gCurFileName = gTEMPDir & "\Scenario1.xml"
    gCurScenarioName = "Scenario1"
    gSaveFlag = False

End Sub

Public Sub CleanAndRestart()

    SetGlobalVariables
    SetVisible
    Randomize
    InitialiseListView
    ReinitialiseIds

    frmMainui.Show
    frmMainui.fraMainUI(0).Move 600, 840
    frmMainui.tvwNodes.Nodes.Clear
    frmMainui.lvwAttributes.ListItems.Clear

End Sub

'************************************************************
'
'************************************************************
Public Sub DeleteNode(ByVal selectedNode As Node)
    Dim parentNode As Node

    'First clear the children names from global lists
    ClearNodeNamesFromGlobalLists selectedNode

    Set parentNode = selectedNode.Parent
    frmMainui.tvwNodes.Nodes.Remove (selectedNode.key)
    frmMainui.tvwNodes.SelectedItem = parentNode
    frmMainui.tvwNodes.SetFocus
    RefreshData

    SetActionButtons

    'Update the global counters
    UpdateGlobalCounters selectedNode

End Sub

'************************************************************
'
'************************************************************
Public Sub ClearNodeNamesFromGlobalLists(ByVal selectedNode As Node)
    Dim ii As Integer
    Dim childNode As Node

    'Delete the children first
    For ii = 0 To selectedNode.children - 1
        If ii = 0 Then
            Set childNode = selectedNode.Child
        Else
            Set childNode = childNode.Next
        End If

        UpdateGlobalCounters childNode
        DeleteRecord childNode
        ClearNodeNamesFromGlobalLists childNode
    Next ii

End Sub

Public Sub DeleteRecord(ByVal nodeElement As Node)
    Dim tblName As String
    Dim tblType As ObjectType
    Dim uId As String
    Dim cnn As New ADODB.Connection
    Dim rst As New ADODB.Recordset

    tblType = nodetype(nodeElement)
    tblName = ReturnTableName(tblType)
    uId = nodeElement.key

    'Open the connection
    cnn.Open _
        "Provider=Microsoft.Jet.OLEDB.4.0;" _
        & "Data Source=" & gDatabaseName

    'Open the recordset

    rst.Open "SELECT * FROM " & tblName & _
        " WHERE Id = '" & uId & "'", cnn, adOpenKeyset, adLockOptimistic

    rst.Delete

    rst.Close
    cnn.Close
End Sub

Public Sub RenameFormWindow()
    If frmMainui.tspMainUI.SelectedItem.index = 2 Then
        frmMainui.Caption = "CRAMP [" & _
        LCase(frmMainui.tspMainUI.SelectedItem.Caption) & _
        "]"
    Else
        frmMainui.Caption = gCurScenarioName & " - CRAMP [" & _
        LCase(frmMainui.tspMainUI.SelectedItem.Caption) & _
        "]"
    End If
End Sub

Public Sub TestVBS()

    Shell ("CScript.exe D:\CRAMP\crampsetting.vbs")

End Sub

Public Sub InitialiseMRUFileList()
    Dim sFileName As String
    Dim sMRUFile As String
    Dim ii, jj As Integer

    gMRUListCtr = 0
    For ii = 0 To 1
        For jj = 0 To 3
        gMRUList(ii, jj) = ""
        Next jj
    Next ii

    sFileName = gCRAMPPath & "\res\MostRecentFiles.txt"

    If Not FileExists(sFileName) Then
        Exit Sub
    End If

    Open sFileName For Input As #1
    ii = 1
    Do Until EOF(1)
        frmMainui.mnuSpace3.Visible = True
        Input #1, sMRUFile

        ' Strip trailing spaces
        If (0 <> Len(sMRUFile)) Then
            While (" " = Right$(sMRUFile, 1))
                sMRUFile = Left$(sMRUFile, Len(sMRUFile) - 1)
            Wend
        End If

        If (0 <> Len(sMRUFile)) Then
            gMRUList(0, gMRUListCtr) = sMRUFile
            gMRUList(1, gMRUListCtr) = "&" & gMRUListCtr + 1 & " " & sMRUFile
            gMRUListCtr = gMRUListCtr + 1
            If gMRUListCtr = 4 Then
                Exit Do
            End If
        End If
    Loop

    Close #1

    UpdateMenuEditor

End Sub

Public Sub UpdateMenuEditor()
    Dim ii As Integer

    For ii = 0 To 3
        frmMainui.mnuMRU(ii).Caption = ""
        frmMainui.mnuMRU(ii).Visible = False
    Next ii

    For ii = 0 To gMRUListCtr - 1
        frmMainui.mnuMRU(ii).Caption = gMRUList(1, ii)
        frmMainui.mnuMRU(ii).Visible = True
    Next ii

End Sub

Public Function CheckSaveStatus() As Boolean
    If gSaveFlag Then
        Dim Msg, Style, Title, Response, MyString
        Msg = "Do you want to save the changes you made to " & _
                    gCurScenarioName & "?"
        Style = vbYesNoCancel + vbExclamation
        Title = "CRAMP"

        Response = MsgBox(Msg, Style, Title)
        Select Case Response
            Case vbYes
                SaveFunction gCurFileName

            Case vbNo

            Case vbCancel
                CheckSaveStatus = False
                Exit Function
        End Select
    End If
    CheckSaveStatus = True
End Function

Public Sub SaveIntoMRUFile()
    Dim sFileName As String
    Dim ii As Integer
    sFileName = gCRAMPPath & "\res\MostRecentFiles.txt"

    If Not FileExists(sFileName) Then
        Exit Sub
    End If

    Open sFileName For Output As #1

    For ii = 0 To gMRUListCtr - 1
        Print #1, gMRUList(0, ii)
    Next ii

    Close #1

End Sub
'************************************************************
'
'************************************************************
Public Sub SaveFunction(strFileName As String)
    Dim xmlDoc As DOMDocument30
    Set xmlDoc = New DOMDocument30
    Dim elementNode, newElementNode As IXMLDOMElement
    Dim RootElementNode As IXMLDOMElement
    Dim TNode As Node
    'On Error GoTo ErrorHandler

    While gIdRef.Count
        gIdRef.Remove 1
    Wend

    Set TNode = frmMainui.tvwNodes.Nodes(1).root
    Set elementNode = xmlDoc.createElement("Scenario")

    elementNode.setAttribute "Id", TNode.key

    WriteAttributes elementNode, otScenario, TNode.key

    Set RootElementNode = xmlDoc.appendChild(elementNode)

    WriteChildrenToXMLFile TNode, RootElementNode

    xmlDoc.Save (strFileName)

    UpdateMRUFileList strFileName
    gSaveFlag = False

End Sub

Public Sub UpdateMRUFileList(strFileName As String)
    Dim ii, jj As Integer
    Dim bFilePresent As Boolean
    bFilePresent = False

    For ii = 0 To gMRUListCtr - 1
        If gMRUList(0, ii) = strFileName Then
            bFilePresent = True
            Exit For
        End If
    Next ii

    If bFilePresent Then
        For jj = ii To 1 Step -1
            gMRUList(0, jj) = gMRUList(0, jj - 1)
            gMRUList(1, jj) = "&" & jj + 1 & " " & gMRUList(0, jj)
        Next jj
        gMRUList(0, 0) = strFileName
        gMRUList(1, 0) = "&1 " & strFileName
    Else
        For jj = 3 To 1 Step -1
            gMRUList(0, jj) = gMRUList(0, jj - 1)
            gMRUList(1, jj) = "&" & jj + 1 & " " & gMRUList(0, jj)
        Next jj
        gMRUList(0, 0) = strFileName
        gMRUList(1, 0) = "&1 " & strFileName
    End If

    gMRUListCtr = 0
    For ii = 0 To 3
        If gMRUList(0, ii) = "" Then
            Exit For
        End If
        gMRUListCtr = gMRUListCtr + 1
    Next ii

    frmMainui.mnuSpace3.Visible = True
    UpdateMenuEditor
End Sub


Public Sub CreateIdRefList()
    Dim selectedNode As Node
    Dim rootNode As Node
    Dim ii As Integer
    Dim RetStatus As Boolean

    Set selectedNode = frmMainui.tvwNodes.SelectedItem
    Set rootNode = selectedNode.root

    While gIdRef.Count
        gIdRef.Remove 1
    Wend

    RetStatus = NodeCanBeAdded(rootNode, selectedNode.key)

End Sub

Public Function NodeCanBeAdded(parentNode As Node, _
                                NodeId As String) As Boolean
    Dim ii As Integer
    Dim childNode As Node
    Dim selectedType As ObjectType
    Dim RetStatus As Boolean

    If parentNode.key = NodeId Then
        NodeCanBeAdded = False
        Exit Function
    End If

    For ii = 0 To parentNode.children - 1
        If ii = 0 Then
            Set childNode = parentNode.Child
        Else
            Set childNode = childNode.Next
        End If

        RetStatus = NodeCanBeAdded(childNode, NodeId)
        If Not RetStatus Then
            NodeCanBeAdded = False
            Exit Function
        End If

        'MsgBox childNode.Text
        'selectedType = nodetype(frmMainui.tvwNodes.SelectedItem)
        If nodetype(frmMainui.tvwNodes.SelectedItem) = _
                nodetype(childNode) Then
           gIdRef.Add childNode.Text, childNode.key
        End If

    Next ii

    NodeCanBeAdded = True
End Function


'Public Sub RegSettingTest()

    'SetKeyValue "Environment", "StringValue", "HelloShirish", REG_SZ

'End Sub


'***********************************************************
' My Code Starts Here
'***********************************************************

'***********************************************************
' checking for the existance and size of the file
'***********************************************************
Public Sub IsFileExistAndSize(giFileName, gIsFileExist, gFileSize)
  Dim FileInfo
  On Error Resume Next
  If giFileName <> "" Then
    gIsFileExist = gobjFSO.FileExists(giFileName)
      If gIsFileExist <> False Then
        Set FileInfo = gobjFSO.GetFile(giFileName)
        If FileInfo.Size > 0 Then
          gFileSize = 101
        Else
          gFileSize = 0
        End If
        'gFileSize = FileInfo.Size
      Else
        gFileSize = 0
      End If
  End If
End Sub
'***********************************************************
' moving the controls
'***********************************************************
Public Sub MoveControls(strVal As String)

  With frmMainui
    Select Case strVal
      Case "THREADS"
           'hide-show controls
           .threadCombo.Visible = True
           .rtCombo.Visible = True
           .addressText.Visible = False
           .limitText.Visible = True
           'hide-show lables
           .threadLabel.Visible = True
           .rtLabel.Visible = True
           .addLabel.Visible = False
           .limitLabel.Visible = True
           'move controls
           .limitText.Move 4680, 480
           .appendCheck.Move 5640, 480
           'move lables
           .limitLabel.Move 4680, 240
      Case "ADDR"
           'hide-show controls
           .threadCombo.Visible = True
           .rtCombo.Visible = False
           .addressText.Visible = True
           .limitText.Visible = True
           'hide-show lables
           .threadLabel.Visible = True
           .rtLabel.Visible = False
           .addLabel.Visible = True
           .limitLabel.Visible = True
           'move controls
           .addressText.Move 3600, 480
           .limitText.Move 4800, 480
           .appendCheck.Move 5740, 480
           'move lables
           .addLabel.Move 3600, 240
           .limitLabel.Move 4800, 240
      Case "STAT"
           'hide-show controls
           .threadCombo.Visible = False
           .rtCombo.Visible = False
           .addressText.Visible = False
           .limitText.Visible = False
           'hide-show lables
           .threadLabel.Visible = False
           .rtLabel.Visible = False
           .addLabel.Visible = False
           .limitLabel.Visible = False
           'move controls
           .appendCheck.Move 2510, 480
    End Select
  End With
End Sub
'***********************************************************
' set query text
'***********************************************************
Public Sub SetQueryText(strVal As String)

Dim queryText As String

Select Case strVal
    Case "THREADS"
      If frmMainui.rtCombo.Text = "TICK" Then
         queryText = frmMainui.pidCombo.Text & gstrSpace & "QUERY" & gstrSpace _
                     & frmMainui.threadCombo.Text & gstrSpace & frmMainui.rtCombo.Text _
                     & gstrSpace & frmMainui.limitText.Text
      Else 'RAW
         If frmMainui.limitText.Text <= 0 Then
           queryText = "-1"
           frmMainui.limitText.Text = queryText
         Else
           queryText = "1" & gstrSpace & frmMainui.limitText.Text
         End If
         queryText = frmMainui.pidCombo.Text & gstrSpace & "QUERY" & gstrSpace _
                     & frmMainui.threadCombo.Text & gstrSpace & frmMainui.rtCombo.Text _
                     & gstrSpace & queryText
                     '& gstrSpace & "1" & gstrSpace & frmMainui.limitText.Text
      End If
         If frmMainui.appendCheck.Value = 1 Then
            queryText = queryText & gstrSpace & UCase(frmMainui.appendCheck.Caption)
         End If
         'if pid combo box is null than disable query button
         If frmMainui.pidCombo.Text = "" And _
            frmMainui.queryCommand.Enabled = True Then
            frmMainui.queryCommand.Enabled = False
         ElseIf frmMainui.pidCombo.Text <> "" And _
            frmMainui.queryCommand.Enabled = False Then
            frmMainui.queryCommand.Enabled = True
         End If
         frmMainui.manuStack.Enabled = True
   Case "ADDR"
         queryText = frmMainui.pidCombo.Text & gstrSpace & "QUERY" & gstrSpace _
                     & frmMainui.threadCombo.Text & gstrSpace & strVal & gstrSpace & frmMainui.addressText.Text & gstrSpace _
                     & frmMainui.limitText.Text
         If frmMainui.appendCheck.Value = 1 Then
            queryText = queryText & gstrSpace & UCase(frmMainui.appendCheck.Caption)
         End If
         'if address text box is null than disable query button
         If frmMainui.addressText.Text = "" And _
            frmMainui.queryCommand.Enabled = True Then
            frmMainui.queryCommand.Enabled = False
         ElseIf frmMainui.addressText.Text <> "" And _
            frmMainui.queryCommand.Enabled = False Then
            frmMainui.queryCommand.Enabled = True
         End If
         frmMainui.manuStack.Enabled = True
    Case "STAT"
         queryText = frmMainui.pidCombo.Text & gstrSpace & "QUERY" & gstrSpace & strVal
         If frmMainui.appendCheck.Value = 1 Then
            queryText = queryText & gstrSpace & UCase(frmMainui.appendCheck.Caption)
         End If
         'if pid combo box is null than disable query button
         If frmMainui.pidCombo.Text = "" And _
            frmMainui.queryCommand.Enabled = True Then
            frmMainui.queryCommand.Enabled = False
         ElseIf frmMainui.pidCombo.Text <> "" And _
            frmMainui.queryCommand.Enabled = False Then
            frmMainui.queryCommand.Enabled = True
         End If
         frmMainui.manuStack.Enabled = False
End Select

'MsgBox queryText
If frmMainui.queryCommand.Enabled = True Then
  frmMainui.queryText.Text = queryText
  queryText = ""
End If
End Sub
'***********************************************************
' checking for the duplicate entry in the array
'***********************************************************
Public Function ChkValueInArray(tmphand As udtPID, tmpStr As String) As Boolean
    Dim iCounter As Integer
    Dim arrValue As String
    
    iCounter = 0
    arrValue = ""
    
    On Error Resume Next
    
    If UBound(tmphand.thrArray) < 0 Then Exit Function
    
    For iCounter = 0 To UBound(tmphand.thrArray)
      arrValue = tmphand.thrArray(iCounter)
      If arrValue = tmpStr Then
        ChkValueInArray = False
        Exit For
      Else
        ChkValueInArray = True
      End If
  Next
End Function
'***********************************************************
' set array in the respective combo box
'***********************************************************
Public Sub SetValueInComboBox(pid As udtPID, thisCombo As ComboBox)
  Dim aa As Long
  Dim strArray As String
  Dim tmpStr As String

  aa = 0
  thisCombo.Clear
  
  On Error Resume Next
  If Not UBound(pid.thrArray) > 0 Then Exit Sub
  
  For aa = 0 To UBound(pid.thrArray)
    strArray = pid.thrArray(aa)
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
  tmpStr = "ALL"
  thisCombo.AddItem (tmpStr)
  thisCombo.ListIndex = 0
  
  aa = 0
End Sub

'***********************************************************
' set the query.psf file info into the listview
'***********************************************************
Public Sub SetValueInListView()

Dim MyArray
Dim strQuery As String
Dim ss As Long
Dim aa As Long
Dim kk As Long

ss = 0
aa = 0
kk = 0

On Error Resume Next
If gobjDic.Count < 0 Then Exit Sub

With frmMainui
  'clean up list view
  .queryLV.ListItems.Clear
  .queryLV.View = lvwReport

  'insert headers
  AddHeaders

  IsFileExistAndSize giFileName, gIsFileExist, gFileSize
  If gIsFileExist <> False And gFileSize <> 0 Then
    If gobjDic.Count > 0 Then
      For kk = gDicCountLower To gDicCountUpper - 1
        If gobjDic.Exists(kk) Then
          'strdic = gobjDic.Item(ss)
          strQuery = gobjDic.Item(kk)
          MyArray = Split(strQuery, "|", -1, 1)

          For ss = 0 To UBound(MyArray)
            strQuery = MyArray(ss)
            'value of ss should not be more than total columns
            If ss > .queryLV.ColumnHeaders.Count - 1 Then Exit For
            If ss = 0 Then
              .queryLV.ListItems.Add = strQuery
            Else
              .queryLV.ListItems(aa + 1).SubItems(ss) = strQuery
            End If
          Next
          aa = aa + 1
        Else
          Exit For
        End If
      Next
      gIsFileExist = False
      gFileSize = 0
    End If
  End If
End With

ss = 0
aa = 0
kk = 0

'set column hide-show
SetNewColumnPosition
End Sub
'***********************************************************
' add headers into the listview
'***********************************************************
Public Sub AddHeaders()
Dim clm As ColumnHeader

With frmMainui
  .queryLV.ColumnHeaders.Clear

  If .staCombo.Text = "STAT" Then
    Set clm = .queryLV.ColumnHeaders.Add(, , "Module")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Function")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Address")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Number")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Ticks/sec")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Total ticks")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Max ticks")
  Else
    Set clm = .queryLV.ColumnHeaders.Add(, , "Position")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Thread")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Module")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Function")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Address")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Depth")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Raw Ticks")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Time(ns)")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Ticks")
  End If
End With
End Sub
'***********************************************************
' start profiling
'***********************************************************
Public Sub DoProfiling(arg As String)
  Dim hInst As Long
  Dim strProCon As String

  strProCon = gCRAMPPath & "/bin/ProfileControl.exe"
  strProCon = Replace(strProCon, "\", "/")
  IsFileExistAndSize strProCon, gIsFileExist, gFileSize
  If gIsFileExist = False And gFileSize = 0 Then
    MsgBox "ERROR :: File " & strProCon & " not found"
    Exit Sub
  End If

  If arg <> "" Then
    If frmMainui.compnameText.Text <> "" _
       And frmMainui.pidText.Text <> "" Then
      strProCon = strProCon & gstrSpace & frmMainui.compnameText.Text & _
                  gstrSpace & frmMainui.pidText.Text + gstrSpace + arg
      hInst = Shell(strProCon, vbNormalFocus)
    End If
  End If

  gIsFileExist = False
  gFileSize = 0
  hInst = 0
End Sub

'***********************************************************
' action on double click in listview
'***********************************************************
Public Sub SetValueFromLV(strType As String)
  Dim ss As Long
  Dim colname As String

  ss = 0
  colname = ""
  
  On Error Resume Next
  
  If strType = "" Then Exit Sub
  
  'initialized second form
  InitLVColHSForm
  
  'check for column width
  Select Case strType
    Case "THREADS"
      If frmLVColHS.threColHSCHB.Value = 0 Then
        MsgBox "ERROR :: Thread column does not exist"
        Exit Sub
      End If
    Case "ADDR"
      If frmLVColHS.addrColHSCHB.Value = 0 Then
        MsgBox "ERROR :: Address column does not exist"
        Exit Sub
      End If
  End Select
    
  With frmMainui
  
    If Not .queryLV.ColumnHeaders.Count > 0 Then Exit Sub
    
    For ss = 1 To .queryLV.ColumnHeaders.Count
      colname = .queryLV.ColumnHeaders.Item(ss).Text
      If colname = "Thread" And .staCombo.Text = "THREADS" Then
        If ss = 1 Then
          If IsNumeric(.queryLV.SelectedItem) Then
            .threadCombo.Text = .queryLV.SelectedItem
          End If
        ElseIf (ss - 1) <> 0 Then
          If IsNumeric(.queryLV.SelectedItem.SubItems(ss - 1)) Then
            .threadCombo.Text = .queryLV.SelectedItem.SubItems(ss - 1)
          End If
        End If
        Exit For
      ElseIf colname = "Address" And .staCombo.Text = "ADDR" Then
        If ss = 1 Then
          .addressText.Text = .queryLV.SelectedItem
        ElseIf (ss - 1) <> 0 Then
          .addressText.Text = .queryLV.SelectedItem.SubItems(ss - 1)
        End If
        Exit For
      End If
    Next
  
    SetQueryText (.staCombo.Text)
  End With
  
  ss = 0
  colname = ""
End Sub

'***********************************************************
' run perl script through createprocess
'***********************************************************
Public Sub RunPerlScriptWithCP(Optional intColNum As Variant, _
                               Optional intOrder As Variant)

    Dim Command As String
    Dim TaskID As Long
    Dim pInfo As PROCESS_INFORMATION
    Dim sInfo As STARTUPINFO
    Dim sNull As String
    Dim lSuccess As Long
    Dim lRetValue As Long
    Dim retVal As Boolean
    Dim Response

    Const SYNCHRONIZE = 1048576
    Const NORMAL_PRIORITY_CLASS = &H20&
    Const INFINITE = -1

    If frmMainui.queryText.Text <> "" Then
     If IsMissing(intColNum) Then
       Command = gperlPath & gstrSpace & gperlScript & gstrSpace & frmMainui.queryText.Text
     Else
       Command = gperlPath & gstrSpace & gquerySort & gstrSpace & intColNum & gstrSpace & intOrder
     End If
      
      sInfo.cb = Len(sInfo)
      lSuccess = CreateProcess(sNull, _
                              Command, _
                              ByVal 0&, _
                              ByVal 0&, _
                              1&, _
                              NORMAL_PRIORITY_CLASS, _
                              ByVal 0&, _
                              sNull, _
                              sInfo, _
                              pInfo)

      lRetValue = WaitForSingleObject(pInfo.hProcess, INFINITE)
      retVal = GetExitCodeProcess(pInfo.hProcess, lRetValue&)

      lRetValue = CloseHandle(pInfo.hThread)
      lRetValue = CloseHandle(pInfo.hProcess)
   Else
     MsgBox "ERROR :: Query Argument Is Not Exists"
   End If
   lSuccess = 0
   lRetValue = 0
End Sub

'***********************************************************
' create dictionary
'***********************************************************
Public Sub CreateDictionary()
  Dim strQuery As String
  Dim I As Long
  Dim MyFileStream

  I = 0
  
  On Error Resume Next
  
  'clean up dictionary
  If gobjDic.Count > 0 Then
    gobjDic.removeAll
  End If
  
  IsFileExistAndSize giFileName, gIsFileExist, gFileSize
  If gIsFileExist <> False And gFileSize <> 0 Then
    Set MyFileStream = gobjFSO.OpenTextFile(giFileName, 1, False)
    'create dictionary
    Do Until MyFileStream.AtEndOfStream
      strQuery = MyFileStream.ReadLine
      If strQuery <> "" Then
        gobjDic.Add I, strQuery
        I = I + 1
      End If
    Loop
    'Close file
    MyFileStream.Close
  Else
    MsgBox "ERROR : File " & giFileName & " not found Or size will be zero. Reason may be wrong query arguments passed."
    'clean up ui
    gDicCountLower = 0
    frmMainui.miniLabel.Caption = gDicCountLower
    gDicCountUpper = 0
    frmMainui.maxLabel.Caption = gDicCountUpper
    frmMainui.totalLabel.Caption = gobjDic.Count
  End If
  
  I = 0
  gIsFileExist = False
  gFileSize = 0
End Sub
'***********************************************************
' hide-show of next and previous button
'***********************************************************
Public Sub HideShowNextPre()
  'hide-show next
  If gobjDic.Count <= gDicCountUpper Then
    frmMainui.nextCommand.Enabled = False
  Else
    frmMainui.nextCommand.Enabled = True
  End If

  If gDicCountLower <> 0 Then
    frmMainui.preCommand.Enabled = True
  Else
    frmMainui.preCommand.Enabled = False
  End If

  'set mini lable
  frmMainui.miniLabel.Caption = gDicCountLower
  'set max lable
  frmMainui.maxLabel.Caption = gDicCountLower + frmMainui.queryLV.ListItems.Count
  'set total lable
  frmMainui.totalLabel.Caption = gobjDic.Count
  
End Sub

'***********************************************************
' set stack in LV
'***********************************************************
Public Sub GetStackForGivenPosition()
  Dim ss As Long
  Dim colname As String
  Dim strPosi As String
  Dim strThre As String

  ss = 0
  colname = ""
  strPosi = ""
  strThre = ""

  On Error Resume Next
  If Not UBound(chbstatusArray) = 12 Then Exit Sub
  
  If chbstatusArray(0) = 0 Then
    MsgBox "ERROR :: Thread column does not exist"
    Exit Sub
  End If
  
  If chbstatusArray(11) = 0 Then
    MsgBox "ERROR :: Position column does not exist"
    Exit Sub
  End If
  
  With frmMainui
    If Not .queryLV.ColumnHeaders.Count > 0 Then Exit Sub
    
    If .staCombo.Text <> "STAT" Then
    
    For ss = 1 To .queryLV.ColumnHeaders.Count
      colname = .queryLV.ColumnHeaders.Item(ss).Text
      Select Case colname
        Case "Position"
          If ss = 1 Then
            If IsNumeric(.queryLV.SelectedItem) Then
              strPosi = .queryLV.SelectedItem
            End If
          ElseIf (ss - 1) <> 0 Then
            If IsNumeric(.queryLV.SelectedItem.SubItems(ss - 1)) Then
              strPosi = .queryLV.SelectedItem.SubItems(ss - 1)
            End If
          End If
        Case "Thread"
          If ss = 1 Then
            If IsNumeric(.queryLV.SelectedItem) Then
              strThre = .queryLV.SelectedItem
            End If
          ElseIf (ss - 1) <> 0 Then
            If IsNumeric(.queryLV.SelectedItem.SubItems(ss - 1)) Then
              strThre = .queryLV.SelectedItem.SubItems(ss - 1)
            End If
          End If
      End Select
      If strPosi <> "" And strThre <> "" Then
        Exit For
      End If
    Next
    End If
  
    If strPosi <> "" And strThre <> "" Then
      If .limitText.Text <= 0 Then .limitText.Text = "10"
      
      .queryText.Text = .pidCombo.Text & gstrSpace & "QUERY" & gstrSpace _
                     & strThre & gstrSpace & "STACK" & gstrSpace & strPosi _
                     & gstrSpace & .limitText.Text
                     '& gstrSpace & "1" & gstrSpace & .limitText.Text
      If .appendCheck.Value = 1 Then
        .queryText.Text = .queryText.Text & gstrSpace & UCase(.appendCheck.Caption)
      End If
      colname = .queryText.Text
                    
      RunPerlScriptWithCP
      CreateDictionary
      gDicCountLower = 0
      gDicCountUpper = .listitemText.Text
      SetValueInListView
      HideShowNextPre
      ShowHideCol
    
      'set thread combo box
      For ss = 0 To .threadCombo.ListCount - 1
        If .threadCombo.list(ss) = strThre Then
          .threadCombo.ListIndex = ss
          Exit For
        End If
      Next
    
      .queryText.Text = colname
    End If
  End With
  
  ss = 0
  colname = ""
  strPosi = ""
  strThre = ""
End Sub
'***********************************************************
' check for digit
'***********************************************************
Public Function ChkForDigit(key As Integer) As Integer
  Dim tKeyAscii As Integer
  tKeyAscii = 0
  
  'check for digit
  If key >= Asc(0) And key <= Asc(9) Then tKeyAscii = key
  'or the backspace key
  If key = 8 Then tKeyAscii = 8
  ChkForDigit = tKeyAscii
End Function
'***********************************************************
' cleaning up globals
'***********************************************************
Public Sub CleanUp()
  'clean up dictionary
  If gobjDic.Count > 0 Then
    gobjDic.removeAll
  End If

  With frmMainui
    'clean up list view
    .queryLV.ListItems.Clear
    .queryLV.ColumnHeaders.Clear
    'clean up combo box
    .pidCombo.Clear
    .staCombo.Clear
    .threadCombo.Clear
    .rtCombo.Clear
    'clean up text box
    .queryText.Text = ""
    .limitText.Text = ""
    .listitemText.Text = ""
    .addressText.Text = ""
    'clean up lable
    .rngLabel.Caption = ""
    .totLabel.Caption = ""
  End With
  
  'set counter to zero
  gFileSize = 0
  gDicCountUpper = 0
  gDicCountLower = 0

  'clean up array
  Erase currsettingArray
  Erase currsetArrayStat
  Erase chbstatusArray
  Erase pidArray
  
  'unload frmlncolhs
  Unload frmLVColHS
  
End Sub
