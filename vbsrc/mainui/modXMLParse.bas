Attribute VB_Name = "modXMLParse"
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
    
    Set TNode = frmMainui.tvwNodes.Nodes(1).root
    Set elementNode = xmlDoc.createElement("Scenario")
    
    elementNode.setAttribute "Id", TNode.Key
    
    WriteAttributes elementNode, otScenario, TNode.Key
    
    Set RootElementNode = xmlDoc.appendChild(elementNode)
    
    WriteChildrenToXMLFile TNode, RootElementNode
    
    xmlDoc.Save (strFileName)
    
    
End Sub

Public Sub WriteAttributes(ByVal elementNode As IXMLDOMElement, _
                           tblType As ObjectType, _
                           uId As String)
    Dim tblName As String
    Dim cnn As New ADODB.Connection
    Dim rst As New ADODB.Recordset
    
    tblName = ReturnTableName(tblType)
    'Open the connection
    cnn.Open _
        "Provider=Microsoft.Jet.OLEDB.4.0;" _
        & "Data Source=" & gDatabaseName
    
    'Open the recordset
    
    rst.Open "SELECT * FROM " & tblName & _
        " WHERE Id = '" & uId & "'", cnn, adOpenKeyset, adLockOptimistic
        
    For ii = 0 To rst.Fields.Count - 1
        
        elementNode.setAttribute rst.Fields.Item(ii).Name, _
                                rst.Fields.Item(ii).value
        
    Next ii
    
    rst.Close
    cnn.Close
    
End Sub
                    
'************************************************************
'
'************************************************************
Public Sub WriteChildrenToXMLFile(ByVal nodeElement As Node, _
                    ByVal XMLElement As IXMLDOMElement)
    Dim ii As Integer
    Dim childNode As Node
    Dim XMLChildElement As IXMLDOMElement
    Dim XMLNewElementNode As IXMLDOMElement
    Dim tblType As ObjectType
    Dim nodeName As String
    
    For ii = 0 To nodeElement.children - 1
        If ii = 0 Then
            Set childNode = nodeElement.Child
        Else
            Set childNode = childNode.Next
        End If
        
        tblType = nodetype(childNode)
        nodeName = GetNodeName(tblType)
        Set XMLChildElement = _
                XMLElement.ownerDocument.createElement(nodeName)
        
        XMLChildElement.setAttribute "Id", childNode.Key
        
        WriteAttributes XMLChildElement, tblType, childNode.Key
        
        Set XMLNewElementNode = XMLElement.appendChild(XMLChildElement)
        
        WriteChildrenToXMLFile childNode, XMLNewElementNode
    Next
    
End Sub

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
    
    Set root = xmlDoc.documentElement
    
    WriteXMLNodeIntoDB root
    
    Set scenario = frmMainui.tvwNodes.Nodes.Add(, , root.getAttribute("Id"), _
                  root.getAttribute("Name"))
    scenario.EnsureVisible
    frmMainui.tvwNodes.SelectedItem = scenario
    SetActionButtons
    RefreshData
    
    IncreaseGlobalCounters scenario
       
    CreateTreeViewAndDB root, scenario
    
    'SetGeneralFields root
    
End Sub

Public Sub WriteXMLNodeIntoDB(ByVal nodeElement As IXMLDOMElement)
    Dim tblName As String
    Dim cnn As New ADODB.Connection
    Dim rst As New ADODB.Recordset
    Dim tblType As ObjectType
    Dim ChkVal As Boolean
    
    tblName = LCase(nodeElement.nodeName & "Table")
    tblType = GetTableType(tblName)
        
    'Open the connection
    cnn.Open _
        "Provider=Microsoft.Jet.OLEDB.4.0;" _
        & "Data Source=" & gDatabaseName
    
    'Open the recordset
    
    rst.Open "SELECT * FROM " & tblName, _
        cnn, adOpenKeyset, adLockOptimistic
    
    rst.AddNew
    
    Select Case tblType
        Case otScenario
            For ii = 0 To gScenarioAttCounter - 1
                rst.Fields(ScenarioAttribute(ii, 0)).value = _
                                    ScenarioAttribute(ii, 1)
                
            Next ii
        
        Case otGroup
            For ii = 0 To gGroupAttCounter - 1
                rst.Fields(GroupAttributes(ii, 0)).value = _
                                    GroupAttributes(ii, 1)
                
                
            Next ii
        
        Case otTestcase
            For ii = 0 To gTestcaseAttCounter - 1
                rst.Fields(TestcaseAttributes(ii, 0)).value = _
                                    TestcaseAttributes(ii, 1)
                
                
            Next ii
            
    End Select
    
    'Now read the node attributes and update the rst
    'first check for the valid attribute
    For ii = 0 To nodeElement.Attributes.length - 1
        ChkVal = CheckAttribute(tblType, _
                        nodeElement.Attributes.Item(ii).nodeName)
        If ChkVal Then
            rst.Fields(nodeElement.Attributes.Item(ii).nodeName).value = _
                nodeElement.Attributes.Item(ii).nodeValue
        End If
    Next ii
    
    
    rst.Update
    
    rst.Close
    cnn.Close
        
End Sub

Public Function CheckAttribute(tblType As ObjectType, _
                attName As String) As Boolean
    Dim AttPresent As Boolean
    AttPresent = False
    Select Case tblType
        Case otScenario
            For ii = 0 To gScenarioAttCounter - 1
                If ScenarioAttribute(ii, 0) = attName Then
                    AttPresent = True
                    Exit For
                End If
            Next ii
        Case otGroup
            For ii = 0 To gGroupAttCounter - 1
                If GroupAttributes(ii, 0) = attName Then
                    AttPresent = True
                    Exit For
                End If
            Next ii
        Case otTestcase
            For ii = 0 To gTestcaseAttCounter - 1
                If TestcaseAttributes(ii, 0) = attName Then
                    AttPresent = True
                    Exit For
                End If
            Next ii
    End Select
    
    If AttPresent Then
        CheckAttribute = True
    Else
        CheckAttribute = False
    End If
    
End Function


Public Function GetTableType(tblName As String) As ObjectType
    Select Case tblName
        Case LCase("ScenarioTable")
            GetTableType = otScenario
        Case LCase("GroupTable")
            GetTableType = otGroup
        Case LCase("TestcaseTable")
            GetTableType = otTestcase
    End Select
        
End Function
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
                
        Set tvwNode = frmMainui.tvwNodes.Nodes.Add(parentNode, _
                                        tvwChild, sKey, sName)
        tvwNode.EnsureVisible
        
        IncreaseGlobalCounters tvwNode
        
        WriteXMLNodeIntoDB childNode
        
        CreateTreeViewAndDB childNode, tvwNode
        
    Next index
    
End Sub

