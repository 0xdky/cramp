VERSION 5.00
Object = "{65E121D4-0C60-11D2-A9FC-0000F8754DA1}#2.0#0"; "MSCHRT20.OCX"
Begin VB.Form frmChart 
   Caption         =   "Form1"
   ClientHeight    =   10395
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   11970
   LinkTopic       =   "Form1"
   ScaleHeight     =   10395
   ScaleWidth      =   11970
   StartUpPosition =   3  'Windows Default
   Begin VB.PictureBox picChart 
      Height          =   4695
      Left            =   600
      ScaleHeight     =   4635
      ScaleWidth      =   7155
      TabIndex        =   1
      Top             =   5160
      Width           =   7215
   End
   Begin MSChart20Lib.MSChart MSChart1 
      Height          =   4335
      Left            =   720
      OleObjectBlob   =   "frmChart.frx":0000
      TabIndex        =   0
      Top             =   360
      Width           =   6975
   End
End
Attribute VB_Name = "frmChart"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

'This example shows how to plot multiple X-Y scatter graphs, also
'known as 2D XY, on an unbound MS Chart control.  X-Y scatter graphs
'differ from other types because the associated DataGrid object needs
'2 columns per series, rather than just one.  The first column for
'each series stores the X values, and the second one stores the Y
'values.  Another difference is that if the # of plot points differs
'between multiple series, you have to remove the null points of the
'shorter series.

'Instructions: Add the MSChart control to your toolbox, then add
'it to a form.  For clarity, try to make it at least 8 inches
'wide, by 5 inches tall, on the form.  then, paste this code into
'the code window, and run.

'written by W. Baldwin, 8/2001

'OldRowCount keeps track of how many points have been plotted for
'the previous series, so we can remove null points from all the
'series that are shorter:
Dim OldRowCount As Long
'PenColor determines whether we are drawing in color or Black & White
'Black & White is for black and white printers, and uses different
'line patterns to distinguish series.
'ShowMarker is a flag that determines whether each plot point
'has a marker or not.
Dim PenColor As Boolean, ShowMarker As Boolean
'ChartPoints is the array that will hold the plot data
Dim ChartPoints() As Double
Dim lRow As Long, lRow2 As Long
Dim I As Integer, MsgPrompt As String
Dim XValue As Single, YValue As Single



Private Sub Form_Load()

With MSChart1

    .chartType = VtChChartType2dXY
    '.chartType = VtChChartType3dLine
    '.chartType = VtChChartType2dLine
    .ShowLegend = True
        
    With .Plot.Axis(VtChAxisIdY).AxisTitle
        .VtFont.Size = 12
        .Visible = True
        .Text = "Y Axis text"
    End With
    With .Plot.Axis(VtChAxisIdX).AxisTitle
        .VtFont.Size = 12
        .Visible = True
        .Text = "X Axis text"
    End With

    .Title.VtFont.Size = 12
    .Title = "Example 2D XY Scatter Graph"
    .Legend.Location.LocationType = VtChLocationTypeBottom
    
    .Plot.Axis(VtChAxisIdY).AxisScale.Type = VtChScaleTypeLinear
    
    .Plot.Axis(VtChAxisIdX).AxisScale.Type = VtChScaleTypeLinear
    
    'Tip from KB article Q194221:
    .Plot.UniformAxis = False
    
    .Footnote.Text = "Footnote goes here"
        
End With

PenColor = True 'Draw in color
'ShowMarker = True 'Show plot points

'Execute the plotting routine
CallRoutine

End Sub



Public Sub ChartPlot(Values(), CurSeries As Integer, ByVal ParName As String)

MousePointer = 11

'Create a new array of plot points for this Series
'We will redim the first subscript differently, to show that each
'series can have a different # of plot points:
Dim x As Integer
'Dim CurSeries As Integer
'CurSeries = 1
x = UBound(Values)

ReDim ChartPoints(1 To x, 1 To 2)


'Create the array data:
For lRow = 1 To UBound(ChartPoints, 1)
    
    ChartPoints(lRow, 1) = lRow
    ChartPoints(lRow, 2) = Values(lRow - 1)
    
Next lRow

'We need to increase the ColumnCount.  For X-Y Scatter graphs, we
'need 2 columns for each series.
MSChart1.ColumnCount = CurSeries * 2

With MSChart1

    With .Plot
    
        .Wall.Brush.Style = VtBrushStyleSolid
        .Wall.Brush.FillColor.Set 255, 255, 225
                
    End With
    
    .ColumnLabelCount = CurSeries * 2
    
    'If the current series has more plot points that the previous
    'one, we need to change .RowCount accordingly:
    If UBound(ChartPoints, 1) > OldRowCount& Then
        .RowCount = UBound(ChartPoints, 1)
    End If
    'Both of the next 2 lines seem to do the same thing:
    .Plot.SeriesCollection(CurSeries * 2 - 1).SeriesMarker.Show = ShowMarker
    .Plot.SeriesCollection.Item(CurSeries * 2 - 1).SeriesMarker.Show = ShowMarker

    'Create the plot points for this series from the ChartPoints array:
    For lRow = 1 To UBound(ChartPoints, 1)
         .DataGrid.SetData lRow, CurSeries * 2 - 1, ChartPoints(lRow, 1), False
         .DataGrid.SetData lRow, CurSeries * 2, ChartPoints(lRow, 2), False
    Next
    'Remove null points from *this* series, if it has *fewer*
    'points than the prior ones.  If you don't remove null points,
    'then the graph will add 0,0 points, erroneously.  See MS
    'Knowledge Base article Q177685 for more info:
    For lRow2 = lRow To OldRowCount&
        .DataGrid.SetData lRow2, CurSeries * 2 - 1, 0, True
        .DataGrid.SetData lRow2, CurSeries * 2, 0, True
    Next
    
    'Remove null points from *prior* series, if this series
    'has *more* points  than the prior ones:
    If CurSeries > 1 Then
        For lRow = OldRowCount& + 1 To .RowCount
            For lRow2 = 1 To CurSeries - 1
                .DataGrid.SetData lRow, lRow2 * 2 - 1, 0, True
                .DataGrid.SetData lRow, lRow2 * 2, 0, True
            Next
        Next
    End If
    
    'Store the current RowCount
    OldRowCount& = .RowCount
    
    .Column = CurSeries * 2 - 1
    .ColumnLabel = ParName

    .Refresh
End With

SubExit:
MousePointer = 0

End Sub


Public Sub CallRoutine()
    Dim strFileName As String
    Dim strLine As String
    Dim ii As Integer
    Dim Param1(), Param2(), Param3(), Param4(), Param5()
    
    strFileName = GetCommandLine(2)
    If Not FileExists(strFileName) Then
        Exit Sub
    End If
    Dim VarArray
    Open strFileName For Input As #1
    
    Do Until EOF(1)
        
        Input #1, strLine
        VarArray = Split(strLine, "|", -1, 1)
        Select Case VarArray(0)
            Case "Param-1"
                ReDim Param1(UBound(VarArray))
                For ii = 1 To UBound(VarArray)
                    Param1(ii - 1) = VarArray(ii)
                Next ii
                ChartPlot Param1, 1, VarArray(0)
            Case "Param-2"
                ReDim Param2(UBound(VarArray))
                For ii = 1 To UBound(VarArray)
                    Param2(ii - 1) = VarArray(ii)
                Next ii
                ChartPlot Param2, 2, VarArray(0)
            Case "Param-3"
                ReDim Param3(UBound(VarArray))
                For ii = 1 To UBound(VarArray)
                    Param3(ii - 1) = VarArray(ii)
                Next ii
                ChartPlot Param3, 3, VarArray(0)
            Case "Param-4"
                ReDim Param4(UBound(VarArray))
                For ii = 1 To UBound(VarArray)
                    Param4(ii - 1) = VarArray(ii)
                Next ii
                ChartPlot Param4, 4, VarArray(0)
            Case "Param-5"
                ReDim Param5(UBound(VarArray))
                For ii = 1 To UBound(VarArray)
                    Param5(ii - 1) = VarArray(ii)
                Next ii
                ChartPlot Param5, 5, VarArray(0)
            Case Else
            
        End Select
        
    Loop

    Close #1
    
    MSChart1.EditCopy
    
    picChart.AutoRedraw = True
    picChart.Picture = Clipboard.GetData(vbCFMetafile)
    'Dim strFileName As String
    strFileName = App.Path & "\Chart1.jpeg"
    SavePicture picChart.Image, strFileName
    
    
End Sub

