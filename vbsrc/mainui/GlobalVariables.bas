Attribute VB_Name = "GlobalVariables"
Option Explicit

Public ADOXcatalog As New ADOX.Catalog
'Public cnn As New ADODB.Connection

Public CurrentTab As Integer
'Public gboolSaveAsFlag As Boolean
Public gstrFileName As String
Public gDatabaseName As String

Public Enum ObjectType
    otNone = 0
    otScenario = 1
    otGroup = 2
    otTestcase = 3
End Enum

Public gIdCounter As Long
Public gIdList(1000) As String
Public gNameList(1000) As String

'************************************************************
'
'************************************************************
Public Function NewTableName(tblType As ObjectType) As String
    Dim nodeName As String
    Dim ii As Integer
    Dim bSuccess As Boolean
    Dim index As Integer
    Dim tmpName As String
    
    Select Case tblType
        Case otNone
            nodeName = ""
        Case otScenario
            NewTableName = "Scenario"
            Exit Function
        Case otGroup
            nodeName = "Group#"
        Case otTestcase
            nodeName = "Testcase#"
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
    
    NewTableName = tmpName
    
End Function

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
                gNameList(0) = tmpId
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
Public Sub IncreaseGlobalCounters(ByVal selectedNode As Node)
    gIdList(gIdCounter) = selectedNode.Key
    gNameList(gIdCounter) = selectedNode.Text
    gIdCounter = gIdCounter + 1
    
End Sub

'************************************************************
'
'************************************************************
Public Sub SetActionButtons()
    Dim selectedNode As Node
    Dim nodeName As String
    
    Set selectedNode = frmCramp.tvwTreeView.SelectedItem
    nodeName = selectedNode.Key
    
    Select Case Left$(nodeName, 1)
        Case "s"
            frmCramp.cmdAddGroup.Enabled = True
            frmCramp.cmdAddTestcase.Enabled = True
            frmCramp.cmdDelete.Enabled = False
            frmCramp.cmdDelete.Caption = "Delete"
        Case "g"
            frmCramp.cmdAddGroup.Enabled = True
            frmCramp.cmdAddTestcase.Enabled = True
            frmCramp.cmdDelete.Enabled = True
            frmCramp.cmdDelete.Caption = "Delete Group"
        
        Case "t"
            frmCramp.cmdAddGroup.Enabled = False
            frmCramp.cmdAddTestcase.Enabled = False
            frmCramp.cmdDelete.Enabled = True
            frmCramp.cmdDelete.Caption = "Delete Testcase"
        
    End Select
    
End Sub

'************************************************************
'
'************************************************************
Public Sub Wait(sngDelay As Single)

     Dim sngFinish
     'sngFinish is the timer value that will be true even
     'Near midnight
    
     frmCramp.MousePointer = 11
     
     sngFinish = (Timer + sngDelay) Mod 86400

     Do
          DoEvents
     Loop While Timer < sngFinish
     
     frmCramp.MousePointer = 99

End Sub

Public Sub IdRefSettings()
    
    If gSetIdRef = True Then
        frmCramp.cmdAddGroup.Enabled = False
        frmCramp.cmdAddTestcase.Enabled = False
        frmCramp.cmdDelete.Enabled = False
        frmCramp.cmdRun.Enabled = False
    Else
        frmCramp.cmdAddGroup.Enabled = True
        frmCramp.cmdAddTestcase.Enabled = True
        frmCramp.cmdDelete.Enabled = True
        frmCramp.cmdRun.Enabled = True
    End If
    
End Sub
