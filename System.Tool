System.Open ^  System.Recall  System.Watch  System.Collect
Edit.Open ^  Edit.Recall
Edit.ChangeFont Syntax10i.Scn.Fnt
Edit.ChangeFont Syntax10b.Scn.Fnt

System.Directory ^
  *.Tool  *.Text  *.Scn.Fnt  *.Mod  *.Bak  *.smb  *.rsc

ORP.Compile */s
System.Free ~
System.Open Draw.Tool
System.CopyFiles ~
System.RenameFiles ~
System.DeleteFiles ~

System.ShowModules  System.ShowCommands ^ 

PCLink1.Run
Hilbert.Draw  Sierpinski,Draw  Blink.Run  Stars.Open

Tools.Inspect 0
Tools.Sector 1
Tools.ShowFile 
Tools.Recall  Tools.Clear
Tools.ShowFiles  Tools.GCoff  Tools.Read  Tools.Write 
