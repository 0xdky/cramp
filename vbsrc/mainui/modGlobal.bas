Attribute VB_Name = "modGlobal"
Option Explicit
Public ADOXcatalog As New ADOX.Catalog
Public gIdCounter As Long
Public gIdList(1000) As String
Public gNameList(1000) As String
Public gDatabaseName As String
Public gCurFileName As String
Public gListViewNode As Node
'Public Declare Function GetCurrentDirectory Lib "kernel32" Alias "GetCurrentDirectoryA" (ByVal nBufferLength As Long, ByVal lpBuffer As String) As Long

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
    Dim ii As Integer
    For ii = 0 To 1000 - 1
        gIdList(ii) = ""
        gNameList(ii) = ""
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
            frmMainui.cmdDelete.Caption = "Delete"
        Case "g"
            frmMainui.cmdAddGroup.Enabled = True
            frmMainui.cmdAddTc.Enabled = True
            frmMainui.cmdDelete.Enabled = True
            frmMainui.cmdDelete.Caption = "Delete Group"
        
        Case "t"
            frmMainui.cmdAddGroup.Enabled = False
            frmMainui.cmdAddTc.Enabled = False
            frmMainui.cmdDelete.Enabled = True
            frmMainui.cmdDelete.Caption = "Delete Testcase"
        
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
    
    gDatabaseName = App.Path & "\MainUI.mdb"
    
    frmMainui.mnuSave.Enabled = False
    frmMainui.cmdRun.Enabled = False
    
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
