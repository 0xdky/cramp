Attribute VB_Name = "modDatabase"
Option Explicit
Public GroupAttributes(8, 1) As Variant
Public gGroupAttCounter As Integer
Public TestcaseAttributes(9, 1) As Variant
Public gTestcaseAttCounter As Integer
Public ScenarioAttribute(5, 1) As Variant
Public gScenarioAttCounter As Integer

Public Sub CreateDatabase()
    
    On Error GoTo ErrorHandler
    ADOXcatalog.Create "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" & _
            gDatabaseName
    
    CreateTablesInDB
    
    Exit Sub
    
ErrorHandler:
    If Err.Number = -2147217897 Then
        
        'Database already exists
        ConnectAndClearDatabase
        
    End If
    
    Resume Next
    
End Sub

'************************************************************
'
'************************************************************
Private Sub CreateTablesInDB()
    
    InitialiseTableAttributes
    
    Dim tblScenario As New ADOX.Table
    Dim tblGroup As New ADOX.Table
    Dim tblTestcase As New ADOX.Table
    Dim ii As Integer
    
    tblScenario.Name = LCase("ScenarioTable")
    For ii = 0 To gScenarioAttCounter - 1
        tblScenario.Columns.Append ScenarioAttribute(ii, 0), adVarWChar, 40
    Next ii
    
    tblGroup.Name = LCase("GroupTable")
    For ii = 0 To gGroupAttCounter - 1
        tblGroup.Columns.Append GroupAttributes(ii, 0), adVarWChar, 40
    Next ii
    
    tblTestcase.Name = LCase("TestcaseTable")
    For ii = 0 To gTestcaseAttCounter - 1
        If TestcaseAttributes(ii, 0) = "ExecPath" Then
            tblTestcase.Columns.Append TestcaseAttributes(ii, 0), adVarWChar, 200
        Else
            tblTestcase.Columns.Append TestcaseAttributes(ii, 0), adVarWChar, 40
        End If
    Next ii
    
    'Append table to DB
    ADOXcatalog.Tables.Append tblScenario
    ADOXcatalog.Tables.Append tblGroup
    ADOXcatalog.Tables.Append tblTestcase
    
End Sub

'************************************************************
' If the DB is already present, connect to it
' and clear all the user created tables.
'************************************************************
Public Sub ConnectAndClearDatabase()
   Dim ii As Integer
   
   ADOXcatalog.ActiveConnection = "Provider=Microsoft.Jet.OLEDB.4.0;" _
      & "Data Source=" & gDatabaseName
   
   For ii = 0 To ADOXcatalog.Tables.Count - 1
        If ADOXcatalog.Tables.Count > 5 Then
        If Left$(ADOXcatalog.Tables.Item(ii).Name, 4) <> "MSys" Then
            ADOXcatalog.Tables.Delete (ADOXcatalog.Tables.Item(ii).Name)
            ii = ii - 1
        End If
        End If
    Next
    
End Sub
'************************************************************
'
'************************************************************
Public Sub AddNodeInTreeView(Optional ByVal parentNode As Node, _
                                Optional tblType As ObjectType)
    
    Dim tableName As String
    Dim childNode As Node
    Dim nodeName As String
    Dim parentName As String
    Dim ii As Integer
    Dim uId As String
    
    tableName = ReturnTableName(tblType)
    nodeName = NewRecordName(tblType)
    uId = GenerateId(tblType)
    
    Select Case tblType
        Case otScenario
            parentName = ""
        Case otGroup
            parentName = parentNode.Text
            GroupAttributes(1, 1) = nodeName
        Case otTestcase
            parentName = parentNode.Text
            TestcaseAttributes(1, 1) = nodeName
    End Select
    
    'Add in the tvwNodes and refresh
    Select Case tblType
        Case otScenario
            
            Set childNode = frmMainui.tvwNodes.Nodes.Add(, , _
                                            uId, nodeName)
    
        Case otGroup, otTestcase
            Set childNode = frmMainui.tvwNodes.Nodes.Add(parentNode, _
                                        tvwChild, uId, nodeName)
    
    End Select
    
    childNode.EnsureVisible
    frmMainui.tvwNodes.SelectedItem = childNode
    
    IncreaseGlobalCounters childNode
    
    SetActionButtons
    
    ShowProperties tblType
    
    'Set the gListViewNode
    Set gListViewNode = childNode
    
End Sub

Public Sub ShowProperties(tblType As ObjectType)
    
    Dim itmX As ListItem
    Dim ii As Integer

    'Clear the lstTable first
    frmMainui.lvwAttributes.ListItems.Clear
    
    Select Case tblType
        Case otScenario
            For ii = 0 To gScenarioAttCounter - 1
                If ScenarioAttribute(ii, 0) <> "Id" Then
                Set itmX = frmMainui.lvwAttributes.ListItems.Add(, , _
                                        ScenarioAttribute(ii, 0))
                itmX.SubItems(1) = ScenarioAttribute(ii, 1)
                End If
                
            Next ii
        
        Case otGroup
            For ii = 0 To gGroupAttCounter - 1
                If GroupAttributes(ii, 0) <> "Id" And _
                    GroupAttributes(ii, 0) <> "ParentKey" Then
                Set itmX = frmMainui.lvwAttributes.ListItems.Add(, , _
                                        GroupAttributes(ii, 0))
                itmX.SubItems(1) = GroupAttributes(ii, 1)
                End If
                
            Next ii
        
        Case otTestcase
            For ii = 0 To gTestcaseAttCounter - 1
                If TestcaseAttributes(ii, 0) <> "Id" And _
                    TestcaseAttributes(ii, 0) <> "ParentKey" Then
                Set itmX = frmMainui.lvwAttributes.ListItems.Add(, , _
                                        TestcaseAttributes(ii, 0))
                itmX.SubItems(1) = TestcaseAttributes(ii, 1)
                End If
                
            Next ii
            
    End Select
    
    'Set frmMainui.lvwAttributes.SelectedItem = _
    '                    frmMainui.lvwAttributes.ListItems(1)
    frmMainui.lvwAttributes.SetFocus
    
    
End Sub

'************************************************************
'
'************************************************************
Private Function InitialiseTableAttributes()
    
    'Scenario table
    ScenarioAttribute(0, 0) = "Id"
    ScenarioAttribute(0, 1) = "s001"
    ScenarioAttribute(1, 0) = "Name"
    ScenarioAttribute(1, 1) = "Scenario"
    ScenarioAttribute(2, 0) = "Block"
    ScenarioAttribute(2, 1) = "TRUE"
    ScenarioAttribute(3, 0) = "MaxRunTime"
    ScenarioAttribute(3, 1) = "0"
    ScenarioAttribute(4, 0) = "MonInterval"
    ScenarioAttribute(4, 1) = "2000"
    ScenarioAttribute(5, 0) = "Release"
    ScenarioAttribute(5, 1) = "E5R13SP2"
    
    gScenarioAttCounter = 6
    
    'Group table
    GroupAttributes(0, 0) = "Id"
    GroupAttributes(0, 1) = "g001"
    GroupAttributes(1, 0) = "Name"
    GroupAttributes(1, 1) = "Group"
    GroupAttributes(2, 0) = "Block"
    GroupAttributes(2, 1) = "FALSE"
    GroupAttributes(3, 0) = "IdRef"
    GroupAttributes(3, 1) = ""
    GroupAttributes(4, 0) = "MaxRunTime"
    GroupAttributes(4, 1) = "0"
    GroupAttributes(5, 0) = "ReInitializeData"
    GroupAttributes(5, 1) = "FALSE"
    GroupAttributes(6, 0) = "StopOnFirstFailure"
    GroupAttributes(6, 1) = "TRUE"
    GroupAttributes(7, 0) = "ParentKey"
    GroupAttributes(7, 1) = ""
                           
    gGroupAttCounter = 8
    
    'Testcases table
    TestcaseAttributes(0, 0) = "Id"
    TestcaseAttributes(0, 1) = "t001"
    TestcaseAttributes(1, 0) = "Name"
    TestcaseAttributes(1, 1) = "Testcase"
    TestcaseAttributes(2, 0) = "Block"
    TestcaseAttributes(2, 1) = "FALSE"
    TestcaseAttributes(3, 0) = "ExecPath"
    TestcaseAttributes(3, 1) = ""
    TestcaseAttributes(4, 0) = "IdRef"
    TestcaseAttributes(4, 1) = ""
    TestcaseAttributes(5, 0) = "MaxRunTime"
    TestcaseAttributes(5, 1) = "0"
    TestcaseAttributes(6, 0) = "NumRuns"
    TestcaseAttributes(6, 1) = "1"
    TestcaseAttributes(7, 0) = "SubProc"
    TestcaseAttributes(7, 1) = "FALSE"
    TestcaseAttributes(8, 0) = "ParentKey"
    TestcaseAttributes(8, 1) = ""
    
    gTestcaseAttCounter = 9
    
End Function

Public Function ReturnTableName(tblType As ObjectType) As String

    Select Case tblType
        Case otNone
            ReturnTableName = ""
        Case otScenario
            ReturnTableName = LCase("ScenarioTable")
        Case otGroup
            ReturnTableName = LCase("GroupTable")
        Case otTestcase
            ReturnTableName = LCase("TestcaseTable")
    End Select
        
End Function

Public Sub WriteIntoDB()
    Dim cnn As New ADODB.Connection
    Dim rst As New ADODB.Recordset
    Dim selectedNode As Node
    Dim tblType As ObjectType
    Dim tblName As String
    Dim ii As Integer
    
    Set selectedNode = gListViewNode
    tblType = nodetype(selectedNode)
    tblName = ReturnTableName(tblType)
    
    'Open the connection
    cnn.Open _
        "Provider=Microsoft.Jet.OLEDB.4.0;" _
        & "Data Source=" & gDatabaseName
    
    'Open the recordset
    
    rst.Open "SELECT * FROM " & tblName, _
        cnn, adOpenKeyset, adLockOptimistic
    
    'rst.MoveFirst
    
    While Not rst.EOF
        If rst.Fields("Id").value = selectedNode.Key Then
            'Recordset exists, modify it
            For ii = 1 To frmMainui.lvwAttributes.ListItems.Count
                rst.Fields(frmMainui.lvwAttributes.ListItems(ii).Text).value = _
                        frmMainui.lvwAttributes.ListItems(ii).SubItems(1)
            Next ii
            rst.Update
            rst.Close
     
            cnn.Close
            Exit Sub
            
        End If
        rst.MoveNext
    Wend
    
    
    'Recordset doesn't exist, add new
    rst.AddNew
    
    For ii = 1 To frmMainui.lvwAttributes.ListItems.Count
        rst.Fields(frmMainui.lvwAttributes.ListItems(ii).Text).value = _
                frmMainui.lvwAttributes.ListItems(ii).SubItems(1)
    Next ii
    
    rst.Fields("Id").value = selectedNode.Key
    Select Case tblType
        Case otScenario
            
        Case otGroup, otTestcase
            rst.Fields("ParentKey").value = selectedNode.Parent.Text
    End Select
    
    rst.Update
    rst.Close
    cnn.Close
    
End Sub

Public Sub RefreshData()
    Dim cnn As New ADODB.Connection
    Dim rst As New ADODB.Recordset
    Dim selectedNode As Node
    Dim tblType As ObjectType
    Dim tblName As String
    Dim ii As Integer
    Dim itmX As ListItem
    
    Set selectedNode = frmMainui.tvwNodes.SelectedItem
    tblType = nodetype(selectedNode)
    tblName = ReturnTableName(tblType)
    
    'Open the connection
    cnn.Open _
        "Provider=Microsoft.Jet.OLEDB.4.0;" _
        & "Data Source=" & gDatabaseName
    
    'Open the recordset
    
    rst.Open "SELECT * FROM " & tblName, _
        cnn, adOpenForwardOnly, adLockReadOnly
    
    Do
        If rst.Fields("Id").value = selectedNode.Key Then
            'Clear the lstTable first
            frmMainui.lvwAttributes.ListItems.Clear
    
            For ii = 0 To rst.Fields.Count - 1
                If rst.Fields.Item(ii).Name <> "Id" And _
                    rst.Fields.Item(ii).Name <> "ParentKey" Then
                Set itmX = frmMainui.lvwAttributes.ListItems.Add(, , _
                                    rst.Fields.Item(ii).Name)
                itmX.SubItems(1) = rst.Fields.Item(ii).value
                End If
                
            Next ii
            
            Exit Do
            
        End If
        rst.MoveNext
    Loop Until rst.EOF
    
    rst.Close
    cnn.Close
    
    'Set the gListViewNode
    Set gListViewNode = frmMainui.tvwNodes.SelectedItem
    
    
End Sub
