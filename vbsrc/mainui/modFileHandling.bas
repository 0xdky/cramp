Attribute VB_Name = "modFileHandling"
' This function will return just the file name from a
' string containing a path and file name.

Public Function ParseFileName(sFileIn As String) As String
    Dim I As Integer

   For I = Len(sFileIn) To 1 Step -1
      If InStr("\", Mid$(sFileIn, I, 1)) Then Exit For
   Next
   ParseFileName = Mid$(sFileIn, I + 1, Len(sFileIn) - I)

End Function


' This function will return the file extension from a
' string containing a path and file name.

Public Function GetFileExt(sFileName As String) As String
    Dim P As Integer

    For P = Len(sFileName) To 1 Step -1
        'Find the last ocurrence of "." in the string
        If InStr(".", Mid$(sFileName, P, 1)) Then Exit For
    Next
    
    GetFileExt = Right$(sFileName, Len(sFileName) - P)

End Function

Public Function GetFileNameWithoutExt(sFileName As String) As String
    Dim FileName As String
    Dim FileExt As String
    
    FileName = ParseFileName(sFileName)
    FileExt = GetFileExt(sFileName)
    
    GetFileNameWithoutExt = Left$(FileName, Len(FileName) - (Len(FileExt) + 1))
End Function
