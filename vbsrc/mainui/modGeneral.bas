Attribute VB_Name = "modGeneral"
Option Explicit

Public gCurScListFileName As String
Public gCurScListName As String

'To get/set the scenario/scenario list
Public Enum ScType
    stFile = 1
    stList = 2
End Enum





'***********************************************************
' Returns the Scenario Type
'***********************************************************
Public Function GetScType() As ScType
    If frmMainui.fraMainUI(2).Visible Then
        GetScType = stList
    Else
        GetScType = stFile
    End If
    
End Function

'***********************************************************
' Shows the Scenario List page
'***********************************************************
Public Sub ShowListFrame()

    'Hide the current frame and show the desired one
    Dim ii As Integer
    
    For ii = 0 To frmMainui.fraMainUI.Count - 1
        frmMainui.fraMainUI(ii).Visible = False
    Next ii
    
    frmMainui.fraMainUI(2).Visible = True
    frmMainui.fraMainUI(2).Move 600, 840
    
    'Set the action buttons
    CleanListFrame
    
End Sub

'***********************************************************
'
'***********************************************************
Public Sub CleanListFrame()
    'Set the global variables
    gCurScListFileName = gTEMPDir & "\ScenarioList1.txt"
    gCurScListName = "ScenarioList1"
    
    'Set the save flagto false
    gSaveFlag = False

    'clear the list view
    frmMainui.lstScenarios.Clear
    
    'Set the action buttons
    frmMainui.cmdAddList.Enabled = True
    frmMainui.cmdRemoveList.Enabled = False
    frmMainui.cmdRunList.Enabled = False
    
End Sub

'***********************************************************
' Adds UNC xml file path in list
'***********************************************************
Public Sub AddScenarioInList()
    'Throw dlg box and get UNC scenario name
    'add it in lvwScenarios
    Dim strScName As String, strReturnString As String
    Dim boolRetVal As Boolean
    boolRetVal = False
    frmMainui.dlgList.Flags = cdlOFNNoChangeDir
    frmMainui.dlgList.Filter = "XML Files (*.xml)|*.xml"
    frmMainui.dlgList.CancelError = True
        
On Local Error GoTo AddScListError:
    While boolRetVal = False
        frmMainui.dlgList.ShowOpen
        
        strScName = frmMainui.dlgList.FileName
        strReturnString = ""
        If strScName <> "" Then
            boolRetVal = GetUNCPath(strScName, strReturnString)
        End If
        AddInScList strReturnString
    Wend
    
AddScListError:
    
End Sub

'***********************************************************
'
'***********************************************************
Public Sub AddInScList(strScName As String)

    frmMainui.lstScenarios.AddItem (strScName)
    gSaveFlag = True
        
End Sub

'************************************************************
' Save the scenario list file
'************************************************************
Public Sub SaveScList(strFileName As String)
    
    Dim ii As Integer
    Open strFileName For Output As #1

    For ii = 0 To frmMainui.lstScenarios.ListCount - 1
        Print #1, frmMainui.lstScenarios.list(ii)
    Next ii

    Close #1
    UpdateMRUFileList strFileName
    gSaveFlag = False
    frmMainui.cmdRunList.Enabled = True

End Sub

'***********************************************************
'
'***********************************************************
Public Function ScListSaveAs() As Boolean

    frmMainui.dlgSelect.Flags = cdlOFNOverwritePrompt
    frmMainui.dlgSelect.Filter = "TXT Files (*.txt)|*.txt"
    If Not gCurScListFileName = "" Then
        frmMainui.dlgSelect.FileName = gCurScListName
    Else
        frmMainui.dlgSelect.FileName = ""
    End If
    frmMainui.dlgSelect.ShowSave
    
    If frmMainui.dlgSelect.FileTitle <> "" Then
        gCurScListName = Left(frmMainui.dlgSelect.FileTitle, _
                                (Len(frmMainui.dlgSelect.FileTitle) - 4))
        gCurScListFileName = frmMainui.dlgSelect.FileName
        If Not gCurScListName = "" Then
            SaveScList gCurScListFileName
            frmMainui.mnuSave.Enabled = True
            frmMainui.cmdRun.Enabled = True
        End If
        RenameFormWindow
        ScListSaveAs = True
    Else
        ScListSaveAs = False
    End If
    
End Function

'***********************************************************
' Checks the save status of scenario list file
'***********************************************************
Public Function CheckScListSaveStatus() As Boolean
    If gSaveFlag Then
        Dim Msg, Style, Title, Response, MyString
        Msg = "Do you want to save the changes you made to " & _
                    gCurScListName & "?"
        Style = vbYesNoCancel + vbExclamation
        Title = "CRAMP"

        Response = MsgBox(Msg, Style, Title)
        Select Case Response
            Case vbYes
                If frmMainui.mnuSave.Enabled Then
                    SaveScList gCurScListFileName
                ElseIf Not ScListSaveAs Then
                    CheckScListSaveStatus = False
                    Exit Function
                End If
                    
            Case vbNo

            Case vbCancel
                CheckScListSaveStatus = False
                Exit Function
        End Select
    End If
    CheckScListSaveStatus = True
End Function

'***********************************************************
'
'***********************************************************
Public Sub OpenScList()
    
    frmMainui.dlgList.Filter = "TXT Files (*.txt)|*.txt"
    frmMainui.dlgList.FileName = ""
    frmMainui.dlgList.ShowOpen
    'Set the global file name
    If frmMainui.dlgList.FileName <> "" Then
        ShowListFrame
        gCurScListName = Left(frmMainui.dlgList.FileTitle, _
                                (Len(frmMainui.dlgList.FileTitle) - 4))
        gCurScListFileName = frmMainui.dlgList.FileName
        LoadScenarioListFrame gCurScListFileName
    End If
End Sub

'***********************************************************
'
'***********************************************************
Public Sub WriteInToListBox(strFileName As String)
    Dim ii As Integer
    Dim strName As String
    Open strFileName For Input As #1
    
    Do Until EOF(1)
        Input #1, strName
        frmMainui.lstScenarios.AddItem (strName)
    Loop
    
    Close #1
    
    frmMainui.lstScenarios.Refresh
    
End Sub

'***********************************************************
'
'***********************************************************
Public Sub LoadScenarioListFrame(strFileName As String)
    frmMainui.mnuSave.Enabled = True
    frmMainui.cmdRunList.Enabled = True
    RenameFormWindow
    WriteInToListBox strFileName
    UpdateMRUFileList strFileName
    gSaveFlag = False
End Sub

'***********************************************************
'
'***********************************************************
Public Sub MoveDownListItem()
    Dim intCurIdx As Integer
    Dim strTmp As String
    
    intCurIdx = frmMainui.lstScenarios.ListIndex
    
    If intCurIdx = frmMainui.lstScenarios.ListCount - 1 Then
        Exit Sub
    End If
    
    strTmp = frmMainui.lstScenarios.list(intCurIdx)
    frmMainui.lstScenarios.list(intCurIdx) = frmMainui.lstScenarios.list(intCurIdx + 1)
    frmMainui.lstScenarios.list(intCurIdx + 1) = strTmp
    
    frmMainui.lstScenarios.Selected(intCurIdx + 1) = True
    frmMainui.lstScenarios.Refresh
    gSaveFlag = True
    
End Sub

'***********************************************************
'
'***********************************************************
Public Sub MoveUpListItem()
    Dim intCurIdx As Integer
    Dim strTmp As String
    
    intCurIdx = frmMainui.lstScenarios.ListIndex
    
    If intCurIdx = 0 Then
        Exit Sub
    End If
    
    strTmp = frmMainui.lstScenarios.list(intCurIdx)
    frmMainui.lstScenarios.list(intCurIdx) = frmMainui.lstScenarios.list(intCurIdx - 1)
    frmMainui.lstScenarios.list(intCurIdx - 1) = strTmp
    
    frmMainui.lstScenarios.Selected(intCurIdx - 1) = True
    frmMainui.lstScenarios.Refresh
    gSaveFlag = True
    
End Sub

'***********************************************************
'
'***********************************************************
Public Sub InitialiseVarListView()
    Dim colX As ColumnHeader ' Declare variable.
    
    frmMainui.lvwVariables.ListItems.Clear
    
    frmMainui.lvwVariables.ColumnHeaders.Clear

    frmMainui.lvwVariables.ColumnHeaders.Add , , _
                        "Variable", frmMainui.lvwVariables.Width / 3
    frmMainui.lvwVariables.ColumnHeaders.Add , , _
                        "Value", 2 * frmMainui.lvwVariables.Width / 3 - 100

    frmMainui.lvwVariables.View = lvwReport

End Sub

'***********************************************************
'
'***********************************************************
Public Sub ShowSettingsPage()
    
    InitialiseVarListView
    FillVarListView
    
End Sub

'***********************************************************
'
'***********************************************************
Public Sub FillVarListView()
    'CRAMP Variables
    Dim sCRAMP_LOGPATH As String
    Dim sCRAMP_PATH As String
    Dim sCRAMP_PROFILE_CALLDEPTH As String
    Dim sCRAMP_PROFILE_LOGSIZE As String
    Dim sCRAMP_PROFILE_MAXCALLLIMIT As String
    Dim sCRAMP_PROFILE_INCLUSION As String
    
On Local Error GoTo FillVarError

    'Get the environment variables
    sCRAMP_LOGPATH = Environ("CRAMP_LOGPATH")
    sCRAMP_PATH = Environ("CRAMP_PATH")
    sCRAMP_PROFILE_CALLDEPTH = Environ("CRAMP_PROFILE_CALLDEPTH")
    sCRAMP_PROFILE_LOGSIZE = Environ("CRAMP_PROFILE_LOGSIZE")
    sCRAMP_PROFILE_MAXCALLLIMIT = Environ("CRAMP_PROFILE_MAXCALLLIMIT")
    sCRAMP_PROFILE_INCLUSION = Environ("CRAMP_PROFILE_INCLUSION")
    
    Dim itmX As ListItem
    frmMainui.lvwVariables.ListItems.Clear
    
    'Fill the listview
    If sCRAMP_LOGPATH <> "" Then
        Set itmX = frmMainui.lvwVariables.ListItems.Add(, , "CRAMP_LOGPATH")
        itmX.SubItems(1) = sCRAMP_LOGPATH
    End If
    
    If sCRAMP_PATH <> "" Then
        Set itmX = frmMainui.lvwVariables.ListItems.Add(, , "CRAMP_PATH")
        itmX.SubItems(1) = sCRAMP_PATH
    End If
    
    If sCRAMP_PROFILE_CALLDEPTH <> "" Then
        Set itmX = frmMainui.lvwVariables.ListItems.Add(, , "CRAMP_PROFILE_CALLDEPTH")
        itmX.SubItems(1) = sCRAMP_PROFILE_CALLDEPTH
    End If
    
    If sCRAMP_PROFILE_LOGSIZE <> "" Then
        Set itmX = frmMainui.lvwVariables.ListItems.Add(, , "CRAMP_PROFILE_LOGSIZE")
        itmX.SubItems(1) = sCRAMP_PROFILE_LOGSIZE
    End If
    
    If sCRAMP_PROFILE_MAXCALLLIMIT <> "" Then
        Set itmX = frmMainui.lvwVariables.ListItems.Add(, , "CRAMP_PROFILE_MAXCALLLIMIT")
        itmX.SubItems(1) = sCRAMP_PROFILE_MAXCALLLIMIT
    End If
    
    If sCRAMP_PROFILE_INCLUSION <> "" Then
        Set itmX = frmMainui.lvwVariables.ListItems.Add(, , "CRAMP_PROFILE_INCLUSION")
        itmX.SubItems(1) = sCRAMP_PROFILE_INCLUSION
    End If
    
    frmMainui.lvwVariables.SetFocus
    
FillVarError:
    
    Resume Next
    
End Sub
