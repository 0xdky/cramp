Attribute VB_Name = "modDatabase"
Option Explicit
Public GroupAttributes(8, 1) As Variant
Public gGroupAttCounter As Integer
Public TestcaseAttributes(9, 1) As Variant
Public gTestcaseAttCounter As Integer
Public ScenarioAttribute(5, 1) As Variant
Public gScenarioAttCounter As Integer

'***********************************************************
'
'***********************************************************
Public Sub CreateDatabase()
    
    On Local Error GoTo CreateDBErrorHandler
    ADOXcatalog.Create "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" & _
            gDatabaseName
    
    CreateTablesInDB
    
    Exit Sub
    
CreateDBErrorHandler:
    
    If Err.Number = -2147217897 Then
        
        'Database already exists
        ConnectAndClearDatabase
        
    End If
    
    Resume Next
    
End Sub

'***********************************************************
'
'***********************************************************
Private Sub CreateTablesInDB()
    Dim tblScenario As New ADOX.Table
    Dim tblGroup As New ADOX.Table
    Dim tblTestcase As New ADOX.Table
    Dim ii As Integer
    
    Dim sFileName As String
    Dim sTableAttribute As String
    Dim sProperty As String
    Dim sValue As String
    Dim sValType As String
    Dim eType As DataTypeEnum
    
    gScenarioAttCounter = 0
    gGroupAttCounter = 0
    gTestcaseAttCounter = 0
    
    tblScenario.Name = LCase("ScenarioTable")
    tblGroup.Name = LCase("GroupTable")
    tblTestcase.Name = LCase("TestcaseTable")
    
On Local Error Resume Next
    
    sFileName = gCRAMPPath & "\res\Attributes.txt"
    
    If Not FileExists(sFileName) Then
        MsgBox "File " & sFileName & " does not exist", vbExclamation
        End
    End If
    
    Open sFileName For Input As #1
    Do Until EOF(1)
        Input #1, sTableAttribute, sProperty, sValue, sValType
        eType = adVarWChar
        Select Case sValType
            Case "Text"
                eType = adVarWChar
            Case "Number"
                eType = adDouble
            Case "Integer"
                eType = adInteger
            Case "Boolean"
                eType = adBoolean
        End Select
        
        Select Case sTableAttribute
            Case "Scenario"
                ScenarioAttribute(gScenarioAttCounter, 0) = sProperty
                ScenarioAttribute(gScenarioAttCounter, 1) = sValue
                tblScenario.Columns.Append sProperty, eType, 40
                gScenarioAttCounter = gScenarioAttCounter + 1
            Case "Group"
                GroupAttributes(gGroupAttCounter, 0) = sProperty
                GroupAttributes(gGroupAttCounter, 1) = sValue
                tblGroup.Columns.Append sProperty, eType, 40
                gGroupAttCounter = gGroupAttCounter + 1
            Case "Testcase"
                TestcaseAttributes(gTestcaseAttCounter, 0) = sProperty
                TestcaseAttributes(gTestcaseAttCounter, 1) = sValue
                If sProperty = "ExecPath" Then
                    tblTestcase.Columns.Append sProperty, eType, 200
                Else
                    tblTestcase.Columns.Append sProperty, eType, 40
                End If
                gTestcaseAttCounter = gTestcaseAttCounter + 1
        End Select
    Loop
    
    Close #1
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
    
    'Add in the tvwNodes
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
    
    Set gListViewNode = childNode
    
End Sub

'***********************************************************
'
'***********************************************************
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
                If GroupAttributes(ii, 0) <> "Id" Then
                Set itmX = frmMainui.lvwAttributes.ListItems.Add(, , _
                                        GroupAttributes(ii, 0))
                itmX.SubItems(1) = GroupAttributes(ii, 1)
                End If
                
            Next ii
        
        Case otTestcase
            For ii = 0 To gTestcaseAttCounter - 1
                If TestcaseAttributes(ii, 0) <> "Id" Then
                Set itmX = frmMainui.lvwAttributes.ListItems.Add(, , _
                                        TestcaseAttributes(ii, 0))
                itmX.SubItems(1) = TestcaseAttributes(ii, 1)
                End If
                
            Next ii
            
    End Select
    
    frmMainui.lvwAttributes.SetFocus
    
End Sub

'***********************************************************
'
'***********************************************************
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
    
    While Not rst.EOF
        If rst.Fields("Id").Value = selectedNode.Key Then
            'Recordset exists, modify it
            For ii = 1 To frmMainui.lvwAttributes.ListItems.Count
                rst.Fields(frmMainui.lvwAttributes.ListItems(ii).Text).Value = _
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
        rst.Fields(frmMainui.lvwAttributes.ListItems(ii).Text).Value = _
                frmMainui.lvwAttributes.ListItems(ii).SubItems(1)
    Next ii
    
    rst.Fields("Id").Value = selectedNode.Key
    
    rst.Update
    rst.Close
    cnn.Close
    
End Sub

'***********************************************************
'
'***********************************************************
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
        If rst.Fields("Id").Value = selectedNode.Key Then
            'Clear the lstTable first
            frmMainui.lvwAttributes.ListItems.Clear
    
            For ii = 0 To rst.Fields.Count - 1
                If rst.Fields.Item(ii).Name <> "Id" Then
                Set itmX = frmMainui.lvwAttributes.ListItems.Add(, , _
                                    rst.Fields.Item(ii).Name)
                itmX.SubItems(1) = rst.Fields.Item(ii).Value
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
