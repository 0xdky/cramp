Attribute VB_Name = "Database"
Option Explicit
Private GroupAttributes(8, 1) As Variant
Private gGroupAttCounter As Integer
Private TestcaseAttributes(9, 1) As Variant
Private gTestcaseAttCounter As Integer
Private ScenarioAttribute(6, 1) As Variant
Private gScenarioAttCounter As Integer

'************************************************************
' Creates DB.
'************************************************************
Public Sub CreateDatabase()
     
    On Error GoTo errhandler
    ADOXcatalog.Create "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" & _
            gDatabaseName
    
    CreateAndInitialiseTable , otScenario
    
    CreateBlankTable
        
    Exit Sub
    
errhandler:
    If Err.Number = -2147217897 Then
        
        ConnectAndClearDatabase
    End If
    
    Resume Next
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
        If ADOXcatalog.Tables.Count > 6 Then
        If Left$(ADOXcatalog.Tables.Item(ii).Name, 4) <> "MSys" Then
            ADOXcatalog.Tables.Delete (ADOXcatalog.Tables.Item(ii).Name)
            ii = ii - 1
        End If
        End If
    Next
    
End Sub

'************************************************************
'Blank table has no data.
'In New/Open actions this table is set to Data1
'************************************************************
Public Sub CreateBlankTable()
    Dim ii As Integer
   
    For ii = 0 To ADOXcatalog.Tables.Count - 1
        If ADOXcatalog.Tables.Item(ii).Name = "MSysBlank" Then
            'Blank table is already present in DB, exit
            Exit Sub
        End If
    Next
    
    'Create blank table
    CreateNewTable "MSysBlank"
    
End Sub

'************************************************************
'
'************************************************************
Public Sub CreateNewTable(tblName As String)

    Dim NewTable As New ADOX.Table
    
    NewTable.Name = tblName
    NewTable.Columns.Append "Property", adVarWChar, 40
    NewTable.Columns.Append "Value", adVarWChar, 60
    
    'Append table to DB
    ADOXcatalog.Tables.Append NewTable
    
End Sub

'************************************************************
'
'************************************************************
Public Sub CreateAndInitialiseTable(Optional ByVal parentNode As Node, _
                                Optional tblType As ObjectType)
    
    Dim tableName As String
    Dim childNode As Node
    Dim nodeName As String
    Dim parentName As String
    Dim cnn As New ADODB.Connection
    Dim rst As New ADODB.Recordset
    Dim ii As Integer
    
    tableName = GenerateId(tblType)
    nodeName = NewTableName(tblType)
    
    CreateNewTable tableName
    
    Select Case tblType
        Case otScenario
            parentName = ""
        Case otGroup, otTestcase
            parentName = parentNode.Text
    End Select
    
    InitialiseTable nodeName, parentName, tblType
    
    'Open the connection
    cnn.Open _
        "Provider=Microsoft.Jet.OLEDB.4.0;" _
        & "Data Source=" & gDatabaseName
    
    'Open the recordset
    
    rst.Open "SELECT * FROM " & tableName, _
        cnn, adOpenKeyset, adLockOptimistic
        
    Select Case tblType
        Case otScenario
            For ii = 0 To gScenarioAttCounter - 1
                rst.AddNew
                rst!Property = ScenarioAttribute(ii, 0)
                rst!Value = ScenarioAttribute(ii, 1)
                rst.Update
            Next ii
        Case otGroup
            For ii = 0 To gGroupAttCounter - 1
                rst.AddNew
                rst!Property = GroupAttributes(ii, 0)
                rst!Value = GroupAttributes(ii, 1)
                rst.Update
            Next ii
        
        Case otTestcase
            For ii = 0 To gTestcaseAttCounter - 1
                rst.AddNew
                rst!Property = TestcaseAttributes(ii, 0)
                rst!Value = TestcaseAttributes(ii, 1)
                rst.Update
            Next ii
    End Select
                
    rst.Close
    cnn.Close
    
    'Allow some delay to get loaded the DB table
    'Show the hour glass to user
    Wait 7
    
    'Add in the tvwTreeView and refresh
    Select Case tblType
        Case otScenario
            Set childNode = frmCramp.tvwTreeView.Nodes.Add(, , _
                                            tableName, nodeName)
    
        Case otGroup, otTestcase
            Set childNode = frmCramp.tvwTreeView.Nodes.Add(parentNode, tvwChild, _
                                            tableName, nodeName)
    
    End Select
    
    childNode.EnsureVisible
    frmCramp.tvwTreeView.SelectedItem = childNode
    'frmCramp.tvwTreeView.SetFocus
    
    IncreaseGlobalCounters childNode
    
    SetActionButtons
    RefreshData frmCramp.tvwTreeView.SelectedItem
    
End Sub

'************************************************************
'
'************************************************************
Public Sub MakeTableInDB(ByVal nodeElement As IXMLDOMElement)
    
    Dim cnn As New ADODB.Connection
    Dim rst As New ADODB.Recordset
    Dim ii As Integer
    Dim tblName As String
    
    tblName = nodeElement.getAttribute("Id")
    
    CreateNewTable tblName
    
    'Open the connection
    cnn.Open _
        "Provider=Microsoft.Jet.OLEDB.4.0;" _
        & "Data Source=" & gDatabaseName
    
    'Open the recordset
    rst.Open "SELECT * FROM " & tblName, _
        cnn, adOpenKeyset, adLockOptimistic
    
    For ii = 0 To nodeElement.Attributes.length - 1
        If nodeElement.Attributes.Item(ii).nodeName <> "Id" Then
            rst.AddNew
            rst!Property = nodeElement.Attributes.Item(ii).nodeName
            rst!Value = nodeElement.Attributes.Item(ii).nodeValue
            rst.Update
        End If
    Next
    rst.Close
    cnn.Close
    
End Sub

'************************************************************
' Update the DBGrid with the new data table
'************************************************************
Public Sub RefreshData(ByVal tvwNode As Node)
    'Dim xItem As ListItem
    Dim tblName As String
    Dim sql As String
    
    On Error GoTo handler
    'Set the DBName of Data1 to the created one.
    frmCramp.Data1.DatabaseName = gDatabaseName
    
    tblName = tvwNode.Key
    sql = "SELECT * FROM " & tblName
    frmCramp.Data1.RecordSource = sql
    
    'frmCramp.Data1.UpdateControls
    frmCramp.Data1.Refresh
    frmCramp.Data1.Visible = False
    frmCramp.DBGrid1.Visible = True
    frmCramp.DBGrid1.Refresh
    'Set the DBGrid's second column width
    frmCramp.DBGrid1.Columns(1).Width = 2600
    
    Exit Sub
    
handler:
    If Err.Number = 3078 Then
        'MsgBox "3078"
        frmCramp.Data1.Refresh
    End If
    
    Resume Next
    
End Sub

'************************************************************
'
'************************************************************
Public Sub DeleteNode(ByVal selectedNode As Node)
    Dim parentNode As Node
    
    'First clear the children names from global lists
    ClearNodeNamesFromGlobalLists selectedNode
    
    Set parentNode = selectedNode.Parent
    frmCramp.tvwTreeView.Nodes.Remove (selectedNode.Key)
    frmCramp.tvwTreeView.SelectedItem = parentNode
    frmCramp.tvwTreeView.SetFocus
    RefreshData parentNode
    
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
        DeleteTableInDB childNode
        ClearNodeNamesFromGlobalLists childNode
    Next ii
    
End Sub

'************************************************************
'
'************************************************************
Public Sub DeleteTableInDB(ByVal selectedNode As Node)
   Dim ii As Integer
    
   ADOXcatalog.ActiveConnection = "Provider=Microsoft.Jet.OLEDB.4.0;" _
      & "Data Source=" & gDatabaseName
   
   For ii = 0 To ADOXcatalog.Tables.Count - 1
        If ADOXcatalog.Tables.Item(ii).Name = selectedNode.Key Then
            ADOXcatalog.Tables.Delete (ADOXcatalog.Tables.Item(ii).Name)
            Exit For
        End If
   Next ii
    
End Sub

'************************************************************
'
'************************************************************
Public Function InitialiseTable(tblName As String, _
                            parentName As String, tblType As ObjectType)
    
    Select Case tblType
        Case otNone
            
        Case otScenario
            ScenarioAttribute(0, 0) = "Name"
            ScenarioAttribute(0, 1) = tblName
            ScenarioAttribute(1, 0) = "CreatedBy"
            ScenarioAttribute(1, 1) = "ssabnis"
            ScenarioAttribute(2, 0) = "Release"
            ScenarioAttribute(2, 1) = "E5R13SP2"
            ScenarioAttribute(3, 0) = "MaxRunTime"
            ScenarioAttribute(3, 1) = "2000"
            ScenarioAttribute(4, 0) = "Profiling"
            ScenarioAttribute(4, 1) = "No"
            ScenarioAttribute(5, 0) = "MonInterval"
            ScenarioAttribute(5, 1) = "2000"
            
            gScenarioAttCounter = 6
            
        Case otGroup
            GroupAttributes(0, 0) = "Name"
            GroupAttributes(0, 1) = tblName
            GroupAttributes(1, 0) = "Block"
            GroupAttributes(1, 1) = "No"
            GroupAttributes(2, 0) = "MaxRunTime"
            GroupAttributes(2, 1) = 2000
            GroupAttributes(3, 0) = "ReInitializeData"
            GroupAttributes(3, 1) = "No"
            GroupAttributes(4, 0) = "StopOnFirstFailure"
            GroupAttributes(4, 1) = "Yes"
            GroupAttributes(5, 0) = "Profiling"
            GroupAttributes(5, 1) = "No"
            GroupAttributes(6, 0) = "ParentKey"
            GroupAttributes(6, 1) = parentName
            GroupAttributes(7, 0) = "IdRef"
            GroupAttributes(7, 1) = ""
                                    
            gGroupAttCounter = 8
            
        Case otTestcase
            TestcaseAttributes(0, 0) = "Name"
            TestcaseAttributes(0, 1) = tblName
            TestcaseAttributes(1, 0) = "ExePath"
            TestcaseAttributes(1, 1) = "F:\Sample\Generate.exe"
            TestcaseAttributes(2, 0) = "NumRuns"
            TestcaseAttributes(2, 1) = 1
            TestcaseAttributes(3, 0) = "Profiling"
            TestcaseAttributes(3, 1) = "No"
            TestcaseAttributes(4, 0) = "MaxRunTime"
            TestcaseAttributes(4, 1) = 2000
            TestcaseAttributes(5, 0) = "Block"
            TestcaseAttributes(5, 1) = "No"
            TestcaseAttributes(6, 0) = "SubProc"
            TestcaseAttributes(6, 1) = "True"
            TestcaseAttributes(7, 0) = "ParentKey"
            TestcaseAttributes(7, 1) = parentName
            TestcaseAttributes(8, 0) = "IdRef"
            TestcaseAttributes(8, 1) = ""
            
            gTestcaseAttCounter = 9
            
    End Select
    
End Function


