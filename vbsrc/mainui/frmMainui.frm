VERSION 5.00
Object = "{831FDD16-0C5C-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCOMCTL.OCX"
Object = "{F9043C88-F6F2-101A-A3C9-08002B2F49FB}#1.2#0"; "COMDLG32.OCX"
Begin VB.Form frmMainui 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "CRAMP - Scenario"
   ClientHeight    =   8496
   ClientLeft      =   5328
   ClientTop       =   3060
   ClientWidth     =   8664
   LinkTopic       =   "Form1"
   ScaleHeight     =   8496
   ScaleWidth      =   8664
   Begin VB.Frame fraMainUI 
      Height          =   7308
      Index           =   1
      Left            =   480
      TabIndex        =   2
      Top             =   600
      Visible         =   0   'False
      Width           =   7332
      Begin VB.Frame Frame4 
         Caption         =   "Profiling"
         Height          =   972
         Left            =   240
         TabIndex        =   33
         Top             =   240
         Width           =   6852
         Begin VB.CommandButton stopCommand 
            Caption         =   "Stop"
            Height          =   288
            Left            =   4440
            TabIndex        =   40
            Top             =   480
            Width           =   972
         End
         Begin VB.CommandButton flushproCommand 
            Caption         =   "Flush"
            Height          =   288
            Left            =   5640
            TabIndex        =   39
            Top             =   480
            Width           =   972
         End
         Begin VB.CommandButton startCommand 
            Caption         =   "Start"
            Height          =   288
            Left            =   3240
            TabIndex        =   38
            Top             =   480
            Width           =   972
         End
         Begin VB.TextBox pidText 
            Height          =   288
            Left            =   2040
            TabIndex        =   36
            Top             =   480
            Width           =   972
         End
         Begin VB.TextBox compnameText 
            Height          =   288
            Left            =   120
            TabIndex        =   34
            Top             =   480
            Width           =   1692
         End
         Begin VB.Label procidLabel 
            Caption         =   "Pid"
            Height          =   252
            Left            =   2040
            TabIndex        =   37
            Top             =   240
            Width           =   972
         End
         Begin VB.Label compnameLabel 
            Caption         =   "Profile Host"
            Height          =   252
            Left            =   120
            TabIndex        =   35
            Top             =   240
            Width           =   1692
         End
      End
      Begin VB.Frame Frame3 
         Caption         =   "Result"
         Height          =   3972
         Left            =   240
         TabIndex        =   30
         Top             =   3120
         Width           =   6852
         Begin VB.CommandButton preCommand 
            Caption         =   "Previous"
            Height          =   288
            Left            =   5760
            TabIndex        =   46
            Top             =   240
            Width           =   972
         End
         Begin VB.CommandButton nextCommand 
            Caption         =   "Next"
            Height          =   288
            Left            =   4560
            TabIndex        =   45
            Top             =   240
            Width           =   972
         End
         Begin VB.TextBox listitemText 
            Height          =   288
            Left            =   3360
            TabIndex        =   44
            Top             =   240
            Width           =   972
         End
         Begin MSComctlLib.ListView queryLV 
            Height          =   3132
            Left            =   120
            TabIndex        =   31
            Top             =   720
            Width           =   6612
            _ExtentX        =   11663
            _ExtentY        =   5525
            LabelWrap       =   -1  'True
            HideSelection   =   -1  'True
            AllowReorder    =   -1  'True
            FullRowSelect   =   -1  'True
            _Version        =   393217
            ForeColor       =   -2147483640
            BackColor       =   -2147483643
            BorderStyle     =   1
            Appearance      =   1
            NumItems        =   0
         End
         Begin VB.Label Label1 
            Caption         =   "Item range : "
            Height          =   252
            Left            =   2520
            TabIndex        =   43
            Top             =   240
            Width           =   852
         End
         Begin VB.Label totLabel 
            Caption         =   "Total items :"
            Height          =   492
            Left            =   1440
            TabIndex        =   42
            Top             =   240
            Width           =   972
         End
         Begin VB.Label rngLabel 
            Caption         =   "Visible items : "
            Height          =   492
            Left            =   120
            TabIndex        =   41
            Top             =   240
            Width           =   1452
         End
      End
      Begin VB.Frame Frame2 
         Caption         =   "Query"
         Height          =   700
         Left            =   240
         TabIndex        =   27
         Top             =   2400
         Width           =   6852
         Begin VB.CommandButton runCommand 
            Caption         =   "Run"
            Height          =   288
            Left            =   5640
            TabIndex        =   32
            Top             =   240
            Width           =   972
         End
         Begin VB.CommandButton queryCommand 
            Caption         =   "Query"
            Enabled         =   0   'False
            Height          =   288
            Left            =   4200
            TabIndex        =   29
            Top             =   240
            Width           =   972
         End
         Begin VB.TextBox queryText 
            Enabled         =   0   'False
            Height          =   288
            Left            =   120
            TabIndex        =   28
            Top             =   240
            Width           =   3732
         End
      End
      Begin VB.Frame Frame1 
         Caption         =   "Query Option"
         Height          =   972
         Left            =   240
         TabIndex        =   13
         Top             =   1320
         Width           =   6852
         Begin VB.CheckBox appendCheck 
            Caption         =   "Append"
            Height          =   312
            Left            =   5880
            TabIndex        =   21
            Top             =   840
            Width           =   852
         End
         Begin VB.TextBox limitText 
            Height          =   288
            Left            =   5880
            TabIndex        =   19
            Text            =   "0"
            Top             =   480
            Width           =   852
         End
         Begin VB.ComboBox addrCombo 
            Height          =   288
            Left            =   4680
            TabIndex        =   18
            Top             =   480
            Width           =   1092
         End
         Begin VB.ComboBox rtCombo 
            Height          =   288
            Left            =   3600
            TabIndex        =   17
            Text            =   "TICK"
            Top             =   480
            Width           =   972
         End
         Begin VB.ComboBox threadCombo 
            Height          =   288
            Left            =   2520
            TabIndex        =   16
            Top             =   480
            Width           =   972
         End
         Begin VB.ComboBox staCombo 
            Height          =   288
            Left            =   1200
            TabIndex        =   15
            Text            =   "THREADS"
            Top             =   480
            Width           =   1212
         End
         Begin VB.ComboBox pidCombo 
            Height          =   288
            Left            =   120
            TabIndex        =   14
            Top             =   480
            Width           =   972
         End
         Begin VB.Label limitLabel 
            Caption         =   "Limit"
            Height          =   252
            Left            =   5880
            TabIndex        =   26
            Top             =   240
            Width           =   852
         End
         Begin VB.Label addLabel 
            Caption         =   "Address"
            Height          =   252
            Left            =   4680
            TabIndex        =   25
            Top             =   240
            Width           =   1092
         End
         Begin VB.Label rtLabel 
            Caption         =   "Raw/Tick"
            Height          =   252
            Left            =   3600
            TabIndex        =   24
            Top             =   240
            Width           =   972
         End
         Begin VB.Label threadLabel 
            Caption         =   "Thread"
            Height          =   252
            Left            =   2520
            TabIndex        =   23
            Top             =   240
            Width           =   972
         End
         Begin VB.Label selLabel 
            Caption         =   "Selection"
            Height          =   252
            Left            =   1200
            TabIndex        =   22
            Top             =   240
            Width           =   1212
         End
         Begin VB.Label pidLabel 
            Caption         =   "Pid"
            Height          =   252
            Left            =   120
            TabIndex        =   20
            Top             =   240
            Width           =   972
         End
      End
   End
   Begin VB.Frame fraMainUI 
      Height          =   6900
      Index           =   0
      Left            =   480
      TabIndex        =   1
      Top             =   7800
      Width           =   7450
      Begin VB.ComboBox cboIdRef 
         Height          =   315
         Left            =   6000
         TabIndex        =   12
         Top             =   4320
         Width           =   1215
      End
      Begin VB.CommandButton cmdBrowse 
         Caption         =   "..."
         Height          =   255
         Left            =   6120
         TabIndex        =   11
         Top             =   6360
         Visible         =   0   'False
         Width           =   255
      End
      Begin VB.TextBox txtInput 
         Appearance      =   0  'Flat
         Height          =   285
         Left            =   6000
         TabIndex        =   10
         Top             =   5520
         Visible         =   0   'False
         Width           =   1215
      End
      Begin VB.ComboBox cboTrueFalse 
         Height          =   315
         ItemData        =   "frmMainui.frx":0000
         Left            =   6000
         List            =   "frmMainui.frx":000A
         TabIndex        =   9
         Text            =   "TRUE"
         Top             =   4920
         Visible         =   0   'False
         Width           =   1215
      End
      Begin VB.CommandButton cmdRun 
         Caption         =   "&Run"
         Height          =   495
         Left            =   6000
         TabIndex        =   8
         Top             =   3240
         Width           =   1215
      End
      Begin VB.CommandButton cmdDelete 
         Caption         =   "&Delete"
         Height          =   495
         Left            =   6000
         TabIndex        =   7
         Top             =   2280
         Width           =   1215
      End
      Begin VB.CommandButton cmdAddTc 
         Caption         =   "Add &Testcase"
         Height          =   495
         Left            =   6000
         TabIndex        =   6
         Top             =   1320
         Width           =   1215
      End
      Begin VB.CommandButton cmdAddGroup 
         Caption         =   "Add &Group"
         Height          =   495
         Left            =   6000
         TabIndex        =   5
         Top             =   360
         Width           =   1215
      End
      Begin MSComDlg.CommonDialog dlgSelect 
         Left            =   6720
         Top             =   6240
         _ExtentX        =   847
         _ExtentY        =   847
         _Version        =   393216
      End
      Begin MSComctlLib.ListView lvwAttributes 
         Height          =   2300
         Left            =   240
         TabIndex        =   4
         Top             =   4320
         Width           =   5500
         _ExtentX        =   9716
         _ExtentY        =   4043
         LabelWrap       =   -1  'True
         HideSelection   =   0   'False
         FullRowSelect   =   -1  'True
         GridLines       =   -1  'True
         _Version        =   393217
         ForeColor       =   -2147483640
         BackColor       =   -2147483643
         BorderStyle     =   1
         Appearance      =   1
         NumItems        =   0
      End
      Begin MSComctlLib.TreeView tvwNodes 
         Height          =   3504
         Left            =   240
         TabIndex        =   3
         Top             =   480
         Width           =   5496
         _ExtentX        =   9716
         _ExtentY        =   6160
         _Version        =   393217
         HideSelection   =   0   'False
         Style           =   7
         Appearance      =   1
      End
   End
   Begin MSComctlLib.TabStrip tspMainUI 
      Height          =   8052
      Left            =   240
      TabIndex        =   0
      Top             =   240
      Width           =   8172
      _ExtentX        =   14415
      _ExtentY        =   14203
      _Version        =   393216
      BeginProperty Tabs {1EFB6598-857C-11D1-B16A-00C0F0283628} 
         NumTabs         =   2
         BeginProperty Tab1 {1EFB659A-857C-11D1-B16A-00C0F0283628} 
            Caption         =   "Engine"
            ImageVarType    =   2
         EndProperty
         BeginProperty Tab2 {1EFB659A-857C-11D1-B16A-00C0F0283628} 
            Caption         =   "Profiler"
            ImageVarType    =   2
         EndProperty
      EndProperty
   End
   Begin VB.Menu mnuFile 
      Caption         =   "&File"
      Begin VB.Menu mnuNew 
         Caption         =   "&New"
         Shortcut        =   ^N
      End
      Begin VB.Menu mnuOpen 
         Caption         =   "&Open"
         Shortcut        =   ^O
      End
      Begin VB.Menu mnuSpace 
         Caption         =   "-"
      End
      Begin VB.Menu mnuSave 
         Caption         =   "&Save"
         Shortcut        =   ^S
      End
      Begin VB.Menu mnuSaveAs 
         Caption         =   "Save &As.."
         Shortcut        =   ^A
      End
      Begin VB.Menu mnuSpace2 
         Caption         =   "-"
      End
      Begin VB.Menu mnuMRU 
         Caption         =   ""
         Index           =   0
         Visible         =   0   'False
      End
      Begin VB.Menu mnuMRU 
         Caption         =   ""
         Index           =   1
         Visible         =   0   'False
      End
      Begin VB.Menu mnuMRU 
         Caption         =   ""
         Index           =   2
         Visible         =   0   'False
      End
      Begin VB.Menu mnuMRU 
         Caption         =   ""
         Index           =   3
         Visible         =   0   'False
      End
      Begin VB.Menu mnuSpace3 
         Caption         =   "-"
         Visible         =   0   'False
      End
      Begin VB.Menu mnuExit 
         Caption         =   "E&xit"
         Shortcut        =   ^X
      End
   End
   Begin VB.Menu mnuHelp 
      Caption         =   "&Help"
   End
   Begin VB.Menu mnuLVRigCL 
      Caption         =   "&LVRightCL"
      Visible         =   0   'False
      Begin VB.Menu manuHideShow 
         Caption         =   "HideShowHeaders"
      End
      Begin VB.Menu manuDevider 
         Caption         =   "-"
      End
      Begin VB.Menu manuCurrSetting 
         Caption         =   "Save setting"
      End
   End
End
Attribute VB_Name = "frmMainui"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'***********************************************************
'
'***********************************************************

Option Explicit

Const SYNCHRONIZE = 1048576
Const NORMAL_PRIORITY_CLASS = &H20&
Const INFINITE = -1

Private SelectedIndex As Integer

'***********************************************************
' Sets the IdRef field in attributes
'***********************************************************
Private Sub cboIdRef_Click()
    lvwAttributes.SelectedItem.SubItems(1) = cboIdRef.Text
    lvwAttributes.SetFocus
    cboIdRef.Visible = False
    
End Sub

'***********************************************************
' Sets the True/False in attributes
'***********************************************************
Private Sub cboTrueFalse_Click()
    
    lvwAttributes.SelectedItem.SubItems(1) = cboTrueFalse.Text
    lvwAttributes.SetFocus
    cboTrueFalse.Visible = False
    
End Sub

'***********************************************************
'Adds a group in scenario
'First update the DB with present attributes data in listview
'then adds a new node in treeview
'***********************************************************
Private Sub cmdAddGroup_Click()
    
    WriteIntoDB
    
    AddNodeInTreeView tvwNodes.SelectedItem, otGroup
    
    gSaveFlag = True
    
End Sub

'***********************************************************
'Adds a testcase in scenario
'First update the DB with present attributes data in listview
'then adds a new node in treeview
'***********************************************************
Private Sub cmdAddTc_Click()
    
    WriteIntoDB
    
    AddNodeInTreeView tvwNodes.SelectedItem, otTestcase
    
    gSaveFlag = True
    
End Sub

'***********************************************************
'Sets the EXE path in the testcase attribute
'***********************************************************
Private Sub cmdBrowse_Click()
    Dim ExecPath As String
    Dim strReturnString As String
    Dim retVal As Boolean
    retVal = False
    dlgSelect.Flags = cdlOFNNoChangeDir
    dlgSelect.Filter = "EXE Files (*.exe)|*.exe"
    dlgSelect.CancelError = True
    strReturnString = ""
    
On Local Error GoTo BrowseError
    
    While retVal = False
        dlgSelect.ShowOpen
        ExecPath = dlgSelect.FileName
        
        If ExecPath <> "" Then
            retVal = GetUNCPath(ExecPath, strReturnString)
        End If
        
    Wend
    
    lvwAttributes.SelectedItem.SubItems(1) = strReturnString
    lvwAttributes.SetFocus
    cmdBrowse.Visible = False
    
    Exit Sub
    
BrowseError:
    
    lvwAttributes.SetFocus
    cmdBrowse.Visible = False
    
End Sub

'***********************************************************
'Deletes the selected node from scenario
'***********************************************************
Private Sub cmdDelete_Click()
    Dim selectedNode As Node
    Dim selectedType As ObjectType
    
    Set selectedNode = tvwNodes.SelectedItem
    selectedType = nodetype(selectedNode)
    DeleteNode selectedNode
    DeleteRecord selectedNode
        
    gSaveFlag = True
        
End Sub

'***********************************************************
'Runs the scenario and generates the results.
'First it saves the entire scenario and then runs it.
'***********************************************************
Private Sub cmdRun_Click()
    Dim Command As String
    Dim TaskID As Long
    Dim pInfo As PROCESS_INFORMATION
    Dim sInfo As STARTUPINFO
    Dim sNull As String
    Dim lSuccess As Long
    Dim lRetValue As Long
    Dim retVal As Boolean
    Dim Response
    
    SaveFunction gCurFileName
    
    MousePointer = 11
    
    Command = gCRAMPPath & "\bin\CRAMPEngine.exe " & gCurFileName
    
    sInfo.cb = Len(sInfo)
    lSuccess = CreateProcess(sNull, _
                            Command, _
                            ByVal 0&, _
                            ByVal 0&, _
                            1&, _
                            NORMAL_PRIORITY_CLASS, _
                            ByVal 0&, _
                            sNull, _
                            sInfo, _
                            pInfo)
    
    lRetValue = WaitForSingleObject(pInfo.hProcess, INFINITE)
    retVal = GetExitCodeProcess(pInfo.hProcess, lRetValue&)
    
    If lRetValue = 0 Then
        Response = MsgBox("Scenario Run : Successful!!", , "Status")
    Else
        Response = MsgBox("Scenario Run : Unsuccessful" & Chr(13) & _
                    "Exit code: " & lRetValue, , "Status")
    End If
    
    lRetValue = CloseHandle(pInfo.hThread)
    lRetValue = CloseHandle(pInfo.hProcess)
    
    MousePointer = 99
    
End Sub

'***********************************************************
'When CRAMP application starts it does following things.
'***********************************************************
Private Sub Form_Load()
    
    CleanAndRestart
    
    InitialiseMRUFileList
    
    CreateDatabase
        
    AddNodeInTreeView , otScenario
    
    RenameFormWindow
    
    '***********************************************************
    ' My Code Starts Here
    '***********************************************************
    'get all cramp environment variable
    GetEnvironmentVariable
    'add raw/tick
    SetRTCombo
    'set stat/thread/addr combobox
    SetSTACombo
    'move controls
    MoveControls (staCombo.Text)

End Sub

'***********************************************************
'
'***********************************************************
Private Sub Form_Unload(Cancel As Integer)
    WriteIntoDB
    
    SaveIntoMRUFile
    
    If Not CheckSaveStatus Then
        Cancel = -1
    End If
    
    '***********************************************************
    ' My Code Starts Here
    '***********************************************************
    CleanUp
End Sub

'***********************************************************
'Sets the attributs in the listview
'***********************************************************
Private Sub lvwAttributes_Click()
    Dim CellWidth As Double
    Dim Selection As String
    Dim PX As Double
    Dim PY As Double
    Dim ExecPath As String
    
    'Hide the combo boxes and browse button
    cboTrueFalse.Visible = False
    cboIdRef.Visible = False
    cmdBrowse.Visible = False
    txtInput.Visible = False
    txtInput.Text = ""
    
    CellWidth = lvwAttributes.Width _
                - lvwAttributes.ColumnHeaders(1).Width _
                - 300
                
    PX = lvwAttributes.Left _
        + lvwAttributes.SelectedItem.Left _
        + lvwAttributes.ColumnHeaders(1).Width _
        + 75
        
    PY = lvwAttributes.Top _
        + lvwAttributes.SelectedItem.Top _
        + 50
       
    Selection = lvwAttributes.SelectedItem
    If UCase(Selection) = UCase("ExecPath") Then
        cmdBrowse.Move PX + CellWidth - 300, PY
        cmdBrowse.Visible = True
        SelectedIndex = lvwAttributes.SelectedItem.index
        
        Exit Sub
    ElseIf UCase(Selection) = UCase("IdRef") Then
        CreateIdRefList
        Dim index As Integer
        cboIdRef.Clear
        cboIdRef.Move PX, PY, CellWidth - 150
        cboIdRef.Visible = True
        cboIdRef.Text = lvwAttributes.SelectedItem.SubItems(1)
        For index = 1 To gIdRef.Count
            cboIdRef.AddItem gIdRef.Item(index)
        Next index
        cboIdRef.SetFocus
        SelectedIndex = lvwAttributes.SelectedItem.index
        
        Exit Sub
    
    End If
    
    Selection = lvwAttributes.SelectedItem.SubItems(1)
    Select Case UCase(Selection)
           
        Case "TRUE", "FALSE"
            cboTrueFalse.Move PX, PY, CellWidth - 150
            cboTrueFalse.Visible = True
            cboTrueFalse.Text = Selection
            cboTrueFalse.SetFocus
            SelectedIndex = lvwAttributes.SelectedItem.index
            
            Exit Sub
            
    End Select
      
    txtInput.Text = Selection
    txtInput.Height = lvwAttributes.SelectedItem.Height _
                      - 75
                      
    txtInput.Move PX, PY, CellWidth
    txtInput.Visible = True
    'txtInput.SelText = Selection
    txtInput.SetFocus
    SelectedIndex = lvwAttributes.SelectedItem.index
        
End Sub

'***********************************************************
'When user clicks other than listview, update the DB.
'***********************************************************
Private Sub lvwAttributes_LostFocus()
    
    If cboTrueFalse.Visible Or _
       cboIdRef.Visible Or _
       txtInput.Visible Then
       
       Exit Sub
    End If
    
    WriteIntoDB
    
End Sub

'***********************************************************
'End the CRAMP application
'***********************************************************
Private Sub mnuExit_Click()
    WriteIntoDB
    
    SaveIntoMRUFile
    
    If Not CheckSaveStatus Then
        Exit Sub
    End If
    End
End Sub

'***********************************************************
'Always update the DB incase the user has modified it
'***********************************************************
Private Sub mnuFile_Click()
    
    WriteIntoDB
    
End Sub

'***********************************************************
'Always update the DB incase the user has modified it
'***********************************************************
Private Sub mnuHelp_Click()
    
    WriteIntoDB
    
    Dim pptPath As String
    pptPath = App.Path & "\..\docs\CRAMP.ppt"
    Dim ppt As Object
    Set ppt = CreateObject("PowerPoint.Application.9")
    ppt.Visible = True
    ppt.Presentations.Open pptPath
    ppt.ActivePresentation.SlideShowSettings.Run
    Set ppt = Nothing
    
End Sub

'***********************************************************
'User has clicked on one of most recent used scenario
'First save the existing scenario if it is modified
'then open the clicked scenario
'***********************************************************
Private Sub mnuMRU_Click(index As Integer)
    Dim RetStatus As Boolean
    RetStatus = CheckSaveStatus
    
    Dim sScenarioName As String
    sScenarioName = gMRUList(0, index)
    Dim tmpStr As String
    CleanAndRestart
    
    CreateDatabase
    
    gCurScenarioName = GetFileNameWithoutExt(sScenarioName)
    
    gCurFileName = sScenarioName
    mnuSave.Enabled = True
    LoadScenario gCurFileName
    cmdRun.Enabled = True
    RenameFormWindow
    UpdateMRUFileList gCurFileName
    gSaveFlag = False
 
End Sub

'***********************************************************
'User has clicked on New menu in File menu,
'Save the existing scenario if it is modified
'Clean and restart CRAMP application
'***********************************************************
Private Sub mnuNew_Click()
    
    Dim RetStatus As Boolean
    RetStatus = CheckSaveStatus
    
    CleanAndRestart
    
    CreateDatabase
        
    AddNodeInTreeView , otScenario
    
End Sub

'***********************************************************
'Opens the selected scenario file
'***********************************************************
Private Sub mnuOpen_Click()
    Dim strFileName As String
    
    Dim RetStatus As Boolean
    RetStatus = CheckSaveStatus
    
    dlgSelect.Filter = "XML Files (*.xml)|*.xml"
    dlgSelect.FileName = ""
    dlgSelect.ShowOpen
    'Set the global file name
    If dlgSelect.FileName <> "" Then
        CleanAndRestart
    
        CreateDatabase
    
        gCurScenarioName = Left(dlgSelect.FileTitle, _
                                (Len(dlgSelect.FileTitle) - 4))
        strFileName = dlgSelect.FileName
        gCurFileName = strFileName
        mnuSave.Enabled = True
        LoadScenario strFileName
        cmdRun.Enabled = True
        RenameFormWindow
        UpdateMRUFileList strFileName
        gSaveFlag = False
    End If
    
End Sub

'***********************************************************
'Save the current scenario file
'***********************************************************
Private Sub mnuSave_Click()
        
    SaveFunction gCurFileName
    
End Sub

'***********************************************************
'Save the current scenario with new name
'***********************************************************
Private Sub mnuSaveAs_Click()
    dlgSelect.Flags = cdlOFNOverwritePrompt
    dlgSelect.Filter = "XML Files (*.xml)|*.xml"
    If Not gCurFileName = "" Then
        dlgSelect.FileName = gCurFileName
    Else
        dlgSelect.FileName = ""
    End If
    dlgSelect.ShowSave
    
    If dlgSelect.FileTitle <> "" Then
        gCurScenarioName = Left(dlgSelect.FileTitle, _
                                (Len(dlgSelect.FileTitle) - 4))
        gCurFileName = dlgSelect.FileName
        If Not gCurFileName = "" Then
            SaveFunction gCurFileName
            mnuSave.Enabled = True
            cmdRun.Enabled = True
        End If
        RenameFormWindow
    End If
End Sub

'***********************************************************
'User has changed the tab strip option, set the Application
'header accordingly by calling RenameFormWindow
'***********************************************************
Private Sub tspMainUI_Click()
    Dim ii As Integer
    
    For ii = 0 To fraMainUI.Count - 1
        fraMainUI(ii).Visible = False
    Next ii
    
    fraMainUI(tspMainUI.SelectedItem.index - 1).Visible = True
    fraMainUI(tspMainUI.SelectedItem.index - 1).Move 600, 840
    
    RenameFormWindow
End Sub

'***********************************************************
'
'***********************************************************
Private Sub tvwNodes_NodeClick(ByVal Node As MSComctlLib.Node)
    
    'Hide the combo boxes and browse button
    cmdBrowse.Visible = False
    cboTrueFalse.Visible = False
    cboIdRef.Visible = False
    
    WriteIntoDB
    
    RefreshData
    
    SetActionButtons
    
    gSaveFlag = True
    
End Sub

'***********************************************************
'
'***********************************************************
Private Sub txtInput_LostFocus()
        
    If UCase(lvwAttributes.ListItems(SelectedIndex)) <> UCase("Name") And _
       UCase(lvwAttributes.ListItems(SelectedIndex)) <> UCase("Release") Then
        If IsNumeric(txtInput.Text) Then
            lvwAttributes.ListItems(SelectedIndex).SubItems(1) = txtInput.Text
        End If
    Else
        lvwAttributes.ListItems(SelectedIndex).SubItems(1) = txtInput.Text
    End If
    
    lvwAttributes.SetFocus
    txtInput.Visible = False
    
End Sub

'***********************************************************
' My Code Starts Here
'***********************************************************

'***********************************************************
' set address combo box
'***********************************************************
Private Sub addrCombo_Click()
  'set query text
  SetQueryText (staCombo.Text)
End Sub
'***********************************************************
' append check box control
'***********************************************************
Private Sub appendCheck_Click()
  'set query text
  SetQueryText (staCombo.Text)
End Sub

'***********************************************************
' limit text box lost focus notification
'***********************************************************
Private Sub limitText_LostFocus()
  If Not IsNumeric(limitText.Text) Then
    limitText.Text = 0
  End If
  'set query text
  SetQueryText (staCombo.Text)
End Sub

'***********************************************************
' set process id combo box
'***********************************************************
Private Sub pidCombo_Click()
  Screen.MousePointer = vbHourglass
  'set thread and address combo
  SetThreAndAddrCombo
  'set query text
  SetQueryText (staCombo.Text)
  'run perl script
  RunPerlScriptWithCP
  'store query.psf file into the dictionary
  CreateDictionary
  gDicCountLower = 0
  gDicCountUpper = listitemText.Text
  'set list view
  SetValueInListView
  HideShowNextPre
  'set default setting
  ShowHideCol
  manuCurrSetting.Checked = False
  Screen.MousePointer = vbDefault
End Sub

'***********************************************************
' query command control
'***********************************************************
Private Sub queryCommand_Click()
Screen.MousePointer = vbHourglass
'run perl script
RunPerlScriptWithCP
'store query.psf file into the dictionary
CreateDictionary
gDicCountLower = 0
gDicCountUpper = listitemText.Text
'set query.psf output into the listview
SetValueInListView
HideShowNextPre
'show hide col
ShowHideCol
manuCurrSetting.Checked = False
Screen.MousePointer = vbDefault
End Sub

'***********************************************************
' set raw-tick combo box
'***********************************************************
Private Sub rtCombo_Click()
  'set query text
  SetQueryText (frmMainui.staCombo.Text)
  'set raw-tick string
  gstrRawTick = rtCombo.Text
End Sub
'***********************************************************
' set stat-threads-addr combo box
'***********************************************************
Private Sub staCombo_Click()
  'set query text
  SetQueryText (staCombo.Text)
  'move controls
  MoveControls (staCombo.Text)
  'set selection string
  gstrSlection = staCombo.Text
End Sub

'***********************************************************
' set threads combo box
'***********************************************************
Private Sub threadCombo_Click()
  'set query text
  SetQueryText (frmMainui.staCombo.Text)
End Sub

'***********************************************************
' run command control
'***********************************************************
Private Sub runCommand_Click()
  Screen.MousePointer = vbHourglass
  'set orocess id combobox
  SetProcessIDCombo
  If queryCommand.Enabled = True Then
    'set threads into thread combobox and address in addr combobox
    SetThreAndAddrCombo
    'set query text
    SetQueryText (staCombo.Text)
    'run perl script
    RunPerlScriptWithCP
    'store query.psf file into the dictionary
    CreateDictionary
    gDicCountLower = 0
    gDicCountUpper = listitemText.Text
    'set list view
    SetValueInListView
    HideShowNextPre
    'show hide col
    ShowHideCol
    manuCurrSetting.Checked = False
  End If
  Screen.MousePointer = vbDefault
End Sub

'***********************************************************
' stat-threads-addr lost focus notification
'***********************************************************
Private Sub staCombo_LostFocus()
  Dim strVal As String
  strVal = staCombo.Text

  If staCombo.Text <> "THREADS" Or staCombo.Text <> "STAT" _
     Or staCombo.Text <> "ADDR" Then
     staCombo.Text = gstrSlection
  End If
End Sub

'***********************************************************
' raw-tick lost focus notification
'***********************************************************
Private Sub rtCombo_LostFocus()
  Dim strVal As String
  strVal = staCombo.Text

  If staCombo.Text <> "RAW" Or staCombo.Text <> "TICK" Then
     rtCombo.Text = gstrRawTick
  End If
End Sub

'***********************************************************
' start button click
'***********************************************************
Private Sub startCommand_Click()
  
  If compnameText.Text = "" Then
    MsgBox "ERROR :: Null computer name"
    Exit Sub
  End If
  
  If pidText.Text = "" Then
    MsgBox "ERROR :: Null pid value"
    Exit Sub
  End If
  
  'start profiling
  DoProfiling ("START")
End Sub

'***********************************************************
' stop button click
'***********************************************************
Private Sub stopCommand_Click()
  If compnameText.Text = "" Then
    MsgBox "ERROR :: Null computer name"
    Exit Sub
  End If
  
  If pidText.Text = "" Then
    MsgBox "ERROR :: Null pid value"
    Exit Sub
  End If
  
  'stop profiling
  DoProfiling ("STOP")

End Sub

'***********************************************************
' flush button click
'***********************************************************
Private Sub flushproCommand_Click()
  
  If compnameText.Text = "" Then
    MsgBox "ERROR :: Null computer name"
    Exit Sub
  End If
  
  If pidText.Text = "" Then
    MsgBox "ERROR :: Null pid value"
    Exit Sub
  End If
  
  'flush profiling
  DoProfiling ("FLUSH")
End Sub

'***********************************************************
' listview double click
'***********************************************************
Private Sub queryLV_DblClick()
  If queryLV.ColumnHeaders.Count <> 0 Then
    SetValueFromLV
  End If
End Sub
'***********************************************************
' next button click
'***********************************************************
Private Sub nextCommand_Click()
  Screen.MousePointer = vbHourglass
  gDicCountLower = gDicCountUpper
  gDicCountUpper = gDicCountUpper + listitemText.Text
  SetValueInListView
  HideShowNextPre
  Screen.MousePointer = vbDefault
  'show hide col
  ShowHideCol
  manuCurrSetting.Checked = False
End Sub
'***********************************************************
' previous button click
'***********************************************************
Private Sub preCommand_Click()
  Screen.MousePointer = vbHourglass
  
  If Not (gDicCountLower - listitemText.Text) < 0 Then
    gDicCountLower = gDicCountLower - listitemText.Text
    gDicCountUpper = gDicCountLower + listitemText.Text
  Else
    gDicCountUpper = gDicCountLower
    gDicCountLower = 0
  End If
  
  SetValueInListView
  HideShowNextPre
  Screen.MousePointer = vbDefault
  'show hide col
  ShowHideCol
  manuCurrSetting.Checked = False
End Sub
'***********************************************************
' listitem lost focus
'***********************************************************
Private Sub listitemText_LostFocus()
  If Not IsNumeric(listitemText.Text) Then
    listitemText.Text = 100
  End If
  If listitemText.Text > 2000 Then
    listitemText.Text = 2000
  End If
End Sub

Private Sub queryLV_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
  If queryLV.ColumnHeaders.Count > 0 Then
    'pop up menu when right click in the listview
    If Button = vbRightButton Then
      PopupMenu mnuLVRigCL
    End If
  End If
End Sub

Private Sub manuHideShow_Click()
  Screen.MousePointer = vbHourglass
  'click on the manu hide-show
  InitLVColHSForm
  'set check box sensitivity
  SetCHBSensitivity
  frmLVColHS.Top = frmMainui.Top + 2553
  frmLVColHS.Left = frmMainui.Left - 2892
  frmLVColHS.Visible = True
  manuHideShow.Enabled = False
  'frmMainui.Enabled = False
  Screen.MousePointer = vbDefault
End Sub

Private Sub manuCurrSetting_Click()
  Screen.MousePointer = vbHourglass
  manuCurrSetting.Checked = True
  'set current setting
  StoreUserSetting
  Screen.MousePointer = vbDefault
End Sub

