Attribute VB_Name = "XMLParse"
'****************************************************
' Return the node's object type
'****************************************************
Public Function nodetype(test_node As Node) As ObjectType
    If test_node Is Nothing Then
        nodetype = otNone
    Else
        Select Case Left$(test_node.Key, 1)
            Case "c"
                nodetype = otScenario
            Case "g"
                nodetype = otGroup
            Case "t"
                nodetype = otTestcase
        End Select
    End If
End Function

'************************************************************
'
'************************************************************
Public Sub LoadScenario(strFileName As String)
    Dim xmlDoc As DOMDocument30
    Dim scenario As Node
    Dim root As IXMLDOMElement
    
    Set xmlDoc = New DOMDocument30
    If Not xmlDoc.Load(strFileName) Then
       MsgBox "Could not load file" & strFileName
       Exit Sub
    End If
    
    ConnectAndClearDatabase
    
    frmCramp.tvwTreeView.Nodes.Clear
    
    Set root = xmlDoc.documentElement
    
    'Update the scenario table with attributes
    MakeTableInDB root
    Wait 7
    
    Set scenario = frmCramp.tvwTreeView.Nodes.Add(, , root.getAttribute("Id"), _
                  root.getAttribute("Name"))
    scenario.EnsureVisible
    frmCramp.tvwTreeView.SelectedItem = scenario
    SetActionButtons
    RefreshData frmCramp.tvwTreeView.SelectedItem
    
    IncreaseGlobalCounters scenario
       
    CreateTreeViewAndDB root, scenario
    
    SetGeneralFields root
    
End Sub

'****************************************************
' Fills tree view structure with nodes
'****************************************************
Public Sub CreateTreeViewAndDB(ByVal nodeElement As IXMLDOMElement, _
                            ByVal parentNode As Node)

    Dim sName As String
    Dim sKey As String
    Dim childNode As IXMLDOMElement
    Dim tvwNode As Node
    Dim index As Integer
        
    If nodeElement Is Nothing Then
        Exit Sub
    End If
    
    For index = 0 To nodeElement.childNodes.length - 1
        Set childNode = nodeElement.childNodes.Item(index)
        sName = childNode.getAttribute("Name")
        sKey = childNode.getAttribute("Id")
                
        Set tvwNode = frmCramp.tvwTreeView.Nodes.Add(parentNode, tvwChild, sKey, sName)
        tvwNode.EnsureVisible
        IncreaseGlobalCounters tvwNode
        
        MakeTableInDB childNode
        
        CreateTreeViewAndDB childNode, tvwNode
        
    Next index
    
End Sub

'************************************************************
'
'************************************************************
Public Sub SaveFunction(strFileName As String)
    Dim xmlDoc As DOMDocument30
    Set xmlDoc = New DOMDocument30
    Dim ElementNode, newElementNode As IXMLDOMElement
    Dim RootElementNode As IXMLDOMElement
    Dim TNode As Node
    
    'On Error GoTo ErrorHandler
    
    Set TNode = frmCramp.tvwTreeView.Nodes(1).root
    Set ElementNode = xmlDoc.createElement("Scenario")
    
    ElementNode.setAttribute "Id", TNode.Key
    
    FillScenarioElement ElementNode, TNode.Key
    
    Set RootElementNode = xmlDoc.appendChild(ElementNode)
    WriteToXMLFile TNode, RootElementNode
    xmlDoc.save (gstrFileName)
    
'ErrorHandler:
    'If Err.Number = 71 Then
        'Exit Sub
    'End If
End Sub

'****************************************************
' Returns NodeName
'****************************************************
Public Function GetNodeName(test_node As Node) As String
    Dim selected_type As ObjectType
    selected_type = nodetype(test_node)
    
    If test_node Is Nothing Then
        GetNodeName = "Node"
    ElseIf selected_type = otTestcase Then
        GetNodeName = "Testcase"
    ElseIf selected_type = otScenario Then
        GetNodeName = "Scenario"
    End If
End Function

'************************************************************
'
'************************************************************
Public Sub SetGeneralFields(ByVal scenario As IXMLDOMElement)
    If scenario Is Nothing Then
        Exit Sub
    End If
        
End Sub

'************************************************************
'
'************************************************************
Public Sub FillScenarioElement(ByVal scenarioElement As IXMLDOMElement, _
                                tblName As String)
    'childNode.getAttribute("Name")
    Dim cnn As New ADODB.Connection
    Dim rst As New ADODB.Recordset
    Dim ii As Integer
    
    'Open the connection
    cnn.Open _
        "Provider=Microsoft.Jet.OLEDB.4.0;" _
        & "Data Source=" & gDatabaseName
    
    'Open the recordset
    rst.Open "SELECT * FROM " & tblName, _
        cnn, adOpenKeyset, adLockOptimistic
    
    rst.MoveFirst
    ii = 0
    While Not rst.EOF
        scenarioElement.setAttribute rst!Property, rst!Value
        'MsgBox rst!Property & rst!Value
        rst.MoveNext
    Wend
    
    rst.Close
    cnn.Close
End Sub

'************************************************************
'
'************************************************************
Public Sub FillElementAttributes(ByVal XMLElement As IXMLDOMElement, _
                            strElementName As String)
    'childNode.getAttribute("Name")
    Dim cnn As New ADODB.Connection
    Dim rst As New ADODB.Recordset
    Dim ii As Integer
    
    'Open the connection
    cnn.Open _
        "Provider=Microsoft.Jet.OLEDB.4.0;" _
        & "Data Source=" & gDatabaseName
    
    'Open the recordset
    rst.Open "SELECT * FROM " & strElementName, _
        cnn, adOpenKeyset, adLockOptimistic
    
    rst.MoveFirst
    ii = 0
    While Not rst.EOF
        XMLElement.setAttribute rst!Property, rst!Value
        rst.MoveNext
    Wend
    
    rst.Close
    cnn.Close
End Sub

'************************************************************
'
'************************************************************
Public Sub WriteToXMLFile(ByVal nodeElement As Node, _
                    ByVal XMLElement As IXMLDOMElement)
    Dim ii As Integer
    Dim childNode As Node
    Dim XMLChildElement As IXMLDOMElement
    Dim XMLNewElementNode As IXMLDOMElement
    
    For ii = 0 To nodeElement.children - 1
        If ii = 0 Then
            Set childNode = nodeElement.Child
        Else
            Set childNode = childNode.Next
        End If
        
        Set XMLChildElement = _
                XMLElement.ownerDocument.createElement(childNode.Key)
        
        XMLChildElement.setAttribute "Id", childNode.Key
        
        FillElementAttributes XMLChildElement, childNode.Key
        
        Set XMLNewElementNode = XMLElement.appendChild(XMLChildElement)
        
        WriteToXMLFile childNode, XMLNewElementNode
    Next
    
End Sub

