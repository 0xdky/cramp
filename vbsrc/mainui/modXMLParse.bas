Attribute VB_Name = "modXMLParse"


Public Sub WriteAttributes(ByVal elementNode As IXMLDOMElement, _
                           tblType As ObjectType, _
                           uId As String)
    Dim tblName As String
    Dim tmpVal As String
    Dim cnn As New ADODB.Connection
    Dim rst As New ADODB.Recordset
    Dim index As Integer
    Dim IdRefVal, IdRefName As String
    
    tblName = ReturnTableName(tblType)
    'Open the connection
    cnn.Open _
        "Provider=Microsoft.Jet.OLEDB.4.0;" _
        & "Data Source=" & gDatabaseName
    
    'Open the recordset
    
    rst.Open "SELECT * FROM " & tblName & _
        " WHERE Id = '" & uId & "'", cnn, adOpenKeyset, adLockOptimistic
        
    IdRefVal = rst!ID
    IdRefName = rst!Name
    gIdRef.Add IdRefVal, IdRefName
    
    For ii = 0 To rst.Fields.Count - 1
        
        Select Case tblType
        Case otNone
        
        Case otScenario
            elementNode.setAttribute rst.Fields.Item(ii).Name, _
                                rst.Fields.Item(ii).Value
        Case otGroup, otTestcase
            If rst.Fields.Item(ii).Name = "IdRef" And _
                    rst.Fields.Item(ii).Value <> "" Then
                elementNode.setAttribute rst.Fields.Item(ii).Name, _
                        gIdRef(rst.Fields.Item(ii).Value)
            Else
                elementNode.setAttribute rst.Fields.Item(ii).Name, _
                                rst.Fields.Item(ii).Value
            End If
        End Select
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
        
        XMLChildElement.setAttribute "Id", childNode.key
        
        WriteAttributes XMLChildElement, tblType, childNode.key
        
        Set XMLNewElementNode = XMLElement.appendChild(XMLChildElement)
        
        WriteChildrenToXMLFile childNode, XMLNewElementNode
    Next ii
    
End Sub

'************************************************************
'
'************************************************************
Public Sub LoadScenario(strFileName As String)
    Dim xmlDoc As DOMDocument30
    Dim scenario As Node
    Dim root As IXMLDOMElement
    Dim nodeName As String
    While gIdRef.Count
        gIdRef.Remove 1
    Wend
    
    Set xmlDoc = New DOMDocument30
    If Not xmlDoc.Load(strFileName) Then
       MsgBox "Could not load file" & strFileName
       Exit Sub
    End If
    
    Set root = xmlDoc.documentElement
    
    WriteXMLNodeIntoDB root
    nodeName = "Scenario" & "(" & root.getAttribute("Name") & ")"
    Set scenario = frmMainui.tvwNodes.Nodes.Add(, , root.getAttribute("Id"), _
                  nodeName)
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
    IdRefVal = nodeElement.getAttribute("Id")
    IdRefName = nodeElement.getAttribute("Name")
    gIdRef.Add IdRefName, IdRefVal
        
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
                rst.Fields(ScenarioAttribute(ii, 0)).Value = _
                                    ScenarioAttribute(ii, 1)
            Next ii
        
        Case otGroup
            For ii = 0 To gGroupAttCounter - 1
                rst.Fields(GroupAttributes(ii, 0)).Value = _
                                    GroupAttributes(ii, 1)
            Next ii
        
        Case otTestcase
            For ii = 0 To gTestcaseAttCounter - 1
                rst.Fields(TestcaseAttributes(ii, 0)).Value = _
                                    TestcaseAttributes(ii, 1)
            Next ii
            
    End Select
    
    'Now read the node attributes and update the rst
    'first check for the valid attribute
    For ii = 0 To nodeElement.Attributes.length - 1
        ChkVal = CheckAttribute(tblType, _
                        nodeElement.Attributes.Item(ii).nodeName)
        If ChkVal Then
            If nodeElement.Attributes.Item(ii).nodeName = "IdRef" And _
                nodeElement.Attributes.Item(ii).nodeValue <> "" Then
                rst.Fields(nodeElement.Attributes.Item(ii).nodeName).Value = _
                    gIdRef(nodeElement.Attributes.Item(ii).nodeValue)
            Else
                rst.Fields(nodeElement.Attributes.Item(ii).nodeName).Value = _
                nodeElement.Attributes.Item(ii).nodeValue
            End If
            
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
    Dim IdRefVal, IdRefName As String
    Dim nodeName As String
    
    If nodeElement Is Nothing Then
        Exit Sub
    End If
    
    For index = 0 To nodeElement.childNodes.length - 1
        Set childNode = nodeElement.childNodes.Item(index)
        nodeName = childNode.nodeName & "(" & _
                  childNode.getAttribute("Name") & ")"
        sName = childNode.getAttribute("Name")
        sKey = childNode.getAttribute("Id")
        
            
        Set tvwNode = frmMainui.tvwNodes.Nodes.Add(parentNode, _
                                        tvwChild, sKey, nodeName)
        tvwNode.EnsureVisible
        
        IncreaseGlobalCounters tvwNode
        
        WriteXMLNodeIntoDB childNode
        
        CreateTreeViewAndDB childNode, tvwNode
        
    Next index
    
End Sub

