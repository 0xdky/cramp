Attribute VB_Name = "modGlobal"
Option Explicit
Public ADOXcatalog As New ADOX.Catalog
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
    Dim CurDirectory As String
    Dim TmpDir As String

    gCRAMPPath = Environ("CRAMP_PATH")
    If (0 = Len(gCRAMPPath)) Then
        gCRAMPPath = App.Path & "\..\"
    End If

    TmpDir = Environ("CRAMP_LOGPATH")
    If (0 = Len(TmpDir)) Then
        TmpDir = gCRAMPPath & "\tmp"
        MkDir TmpDir
    End If
    
    gDatabaseName = TmpDir & "\CRAMPDB.mdb"
    
    frmMainui.mnuSave.Enabled = False
    frmMainui.cmdRun.Enabled = False
    gCurFileName = App.Path & "\Scenario1.xml"
    gCurScenarioName = "Scenario1"
    gSaveFlag = True
    
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
    frmMainui.Caption = gCurScenarioName & " - CRAMP [" & _
    LCase(frmMainui.fraMainUI(frmMainui.tspMainUI.SelectedItem.index - 1).Caption) & _
    "]"
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
    
    sFileName = App.Path & "\..\res\MostRecentFiles.txt"
    
    If Not FileExists(sFileName) Then
        Exit Sub
    End If
    
    Open sFileName For Input As #1
    ii = 1
    Do Until EOF(1)
        frmMainui.mnuSpace3.Visible = True
        Input #1, sMRUFile
        gMRUList(0, gMRUListCtr) = sMRUFile
        gMRUList(1, gMRUListCtr) = "&" & gMRUListCtr + 1 & " " & sMRUFile
        gMRUListCtr = gMRUListCtr + 1
        If gMRUListCtr = 4 Then
            Exit Do
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

Public Sub CheckSaveStatus()
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
                Exit Sub
        End Select
    End If
End Sub

Public Sub SaveIntoMRUFile()
    Dim sFileName As String
    Dim ii As Integer
    sFileName = App.Path & "\res\MostRecentFiles.txt"
    
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
