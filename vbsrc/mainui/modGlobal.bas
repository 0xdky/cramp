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
Public gstrQueryArg As String
Public gstrSpace As String
Public giFileName As String
Public gstrSlection As String
Public gstrRawTick As String
Public gFileSize As Long
Public gDicCountUpper As Long
Public gDicCountLower As Long
Public gIsFileExist As Boolean
Public starstopBool As Boolean

'****************************************************
' Return the node's object type
'****************************************************
Public Function nodetype(testNode As Node) As ObjectType
    If testNode Is Nothing Then
        nodetype = otNone
    Else
        Select Case Left$(testNode.Key, 1)
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
    gIdList(gIdCounter) = selectedNode.Key
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
        If gIdList(ii) = selectedNode.Key Then
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
        If gIdList(ii) = selectedNode.Key Then
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
    
    nodeName = selectedNode.Key
    
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
    frmMainui.tvwNodes.Nodes.Remove (selectedNode.Key)
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
    uId = nodeElement.Key
    
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
    
    elementNode.setAttribute "Id", TNode.Key
    
    WriteAttributes elementNode, otScenario, TNode.Key
    
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
    
    RetStatus = NodeCanBeAdded(rootNode, selectedNode.Key)
    
End Sub

Public Function NodeCanBeAdded(parentNode As Node, _
                                NodeId As String) As Boolean
    Dim ii As Integer
    Dim childNode As Node
    Dim selectedType As ObjectType
    Dim RetStatus As Boolean
    
    If parentNode.Key = NodeId Then
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
           gIdRef.Add childNode.Text, childNode.Key
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
  If giFileName <> "" Then
    gIsFileExist = gobjFSO.FileExists(giFileName)
      If gIsFileExist <> False Then
        Set FileInfo = gobjFSO.GetFile(giFileName)
        gFileSize = FileInfo.Size
      Else
        gFileSize = 0
      End If
  End If
End Sub
'***********************************************************
' running the perl script
'***********************************************************
Public Sub RunPerlScript()
  Dim hInst As Long
    
  If frmMainui.queryText.Text <> "" Then
    gstrQueryArg = gperlPath + gstrSpace + gperlScript + gstrSpace + frmMainui.queryText.Text
    hInst = Shell(gstrQueryArg, vbNormalFocus)
    gstrQueryArg = frmMainui.queryText.Text
  Else
    MsgBox "ERROR :: Query Argument Is Not Exists"
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
           .addrCombo.Visible = False
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
           .addrCombo.Move 2520, 480
           .limitText.Move 3720, 480
           .appendCheck.Move 4670, 480
           'move lables
           .addLabel.Move 2520, 240
           .limitLabel.Move 3720, 240
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
         queryText = frmMainui.pidCombo.Text + gstrSpace + "QUERY" + gstrSpace _
                     + frmMainui.threadCombo.Text + gstrSpace + frmMainui.rtCombo.Text _
                     + gstrSpace + frmMainui.limitText.Text
         gstrQueryArg = queryText
         If frmMainui.appendCheck.Value = 1 Then
            queryText = queryText + gstrSpace + UCase(frmMainui.appendCheck.Caption)
         End If
    Case "ADDR"
         queryText = frmMainui.pidCombo.Text + gstrSpace + "QUERY" + gstrSpace _
                     + strVal + gstrSpace + frmMainui.addrCombo.Text + gstrSpace _
                     + frmMainui.limitText.Text
         gstrQueryArg = queryText
         If frmMainui.appendCheck.Value = 1 Then
            queryText = queryText + gstrSpace + UCase(frmMainui.appendCheck.Caption)
         End If
    Case "STAT"
         queryText = frmMainui.pidCombo.Text + gstrSpace + "QUERY" + gstrSpace + strVal
         gstrQueryArg = queryText
         If frmMainui.appendCheck.Value = 1 Then
            queryText = queryText + gstrSpace + UCase(frmMainui.appendCheck.Caption)
         End If
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
'***********************************************************
' set array in the respective combo box
'***********************************************************
Public Sub SetValueInComboBox(tmpArry() As String, tmpStr As String, thisCombo As ComboBox)
  Dim aa As Long
  Dim strArray As String
  
  aa = 0
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

'***********************************************************
' set the query.psf file info into the listview
'***********************************************************
Public Sub SetValueInListView()

Dim MyArray, MyFileStream, ThisFileText, arrFile
Dim cur As MousePointerConstants
Dim strQuery As String
Dim ss As Long
Dim aa As Long
Dim kk As Long

ss = 0
aa = 0
kk = 0

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
        
          If UBound(MyArray) > .queryLV.ColumnHeaders.Count - 1 Then
            'insert headers
            .staCombo.Text = "THREADS"
            AddHeaders
            .staCombo.Text = "STAT"
          End If
        
          For ss = 0 To UBound(MyArray)
            strQuery = MyArray(ss)
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
    Set clm = .queryLV.ColumnHeaders.Add(, , "Total ticks")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Max ticks")
  Else
    Set clm = .queryLV.ColumnHeaders.Add(, , "Thread")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Module")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Function")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Address")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Depth")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Exception")
    Set clm = .queryLV.ColumnHeaders.Add(, , "Time(ns)")
    If .staCombo.Text = "ADDR" And frmMainui.limitText.Text = -1 Then
      Set clm = .queryLV.ColumnHeaders.Add(, , "Count")
    Else
      Set clm = .queryLV.ColumnHeaders.Add(, , "Ticks")
    End If
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
End Sub

'***********************************************************
' action on double click in listview
'***********************************************************
Public Sub SetValueFromLV()
  Dim lvValue As String
  
  If frmMainui.staCombo.Text = "ADDR" Then
    'address
    If Not IsNumeric(frmMainui.queryLV.SelectedItem) Then
      If frmMainui.queryLV.ColumnHeaders(3) = "Function" Or _
         frmMainui.queryLV.ColumnHeaders(3) = "Address" Then
        lvValue = frmMainui.queryLV.SelectedItem.SubItems(2)
        frmMainui.addrCombo.Text = lvValue
      End If
    Else
      If frmMainui.queryLV.ColumnHeaders(4) = "Address" Then
        lvValue = frmMainui.queryLV.SelectedItem.SubItems(3)
        frmMainui.addrCombo.Text = lvValue
      End If
    End If
    'set query text
    SetQueryText (frmMainui.staCombo.Text)
  ElseIf frmMainui.staCombo.Text = "THREADS" Then
    'threads
    If frmMainui.queryLV.ColumnHeaders(1) = "Thread" Then
      If IsNumeric(frmMainui.queryLV.SelectedItem) Then
        lvValue = frmMainui.queryLV.SelectedItem
        frmMainui.threadCombo.Text = lvValue
      End If
      'set query text
      SetQueryText (frmMainui.staCombo.Text)
    End If
  End If
End Sub

'***********************************************************
' run perl script through createprocess
'***********************************************************
Public Sub RunPerlScriptWithCP()
   
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
     Command = gperlPath + gstrSpace + gperlScript + gstrSpace + frmMainui.queryText.Text
      gstrQueryArg = frmMainui.queryText.Text
    
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
End Sub

'***********************************************************
' create dictionary
'***********************************************************
Public Sub CreateDictionary()
  Dim strQuery As String
  Dim i As Long
  Dim MyFileStream

  i = 0
  Set MyFileStream = gobjFSO.OpenTextFile(giFileName, 1, False)
  'clean up dictionary
  If gobjDic.Count > 0 Then
    gobjDic.removeAll
  End If
  'cteate dictionary
  Do Until MyFileStream.AtEndOfStream
    strQuery = MyFileStream.ReadLine
    If strQuery <> "" Then
      gobjDic.Add i, strQuery
      i = i + 1
    End If
  Loop
  'Close file
  MyFileStream.Close
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
  
  'set range lable
  frmMainui.rngLabel.Caption = "Visible items : " & Chr(13) & gDicCountLower & " - " _
                               & gDicCountLower + frmMainui.queryLV.ListItems.Count
  'set total lable
  frmMainui.totLabel.Caption = "Total items : " & Chr(13) & gobjDic.Count
End Sub

