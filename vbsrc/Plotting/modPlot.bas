Attribute VB_Name = "modPlot"
Public Sub Main()
    Dim strFileName As String
    
    Load frmChart
    frmChart.Visible = False
    Unload frmChart
    End
    
End Sub

Public Function GetCommandLine(Optional MaxArgs) As String
   'Declare variables.
   Dim C, CmdLine, CmdLnLen, InArg, i, NumArgs
   'See if MaxArgs was provided.
   If IsMissing(MaxArgs) Then MaxArgs = 10
   'Make array of the correct size.
   ReDim ArgArray(MaxArgs)
   NumArgs = 0: InArg = False
   'Get command line arguments.
   CmdLine = Command()
   CmdLnLen = Len(CmdLine)
   
   GetCommandLine = CmdLine
   
End Function


