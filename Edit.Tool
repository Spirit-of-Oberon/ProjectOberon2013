Edit.Recall
Edit.Search  Edit.Locate
Edit.Print Pluto *
Edit.Print Pluto ~
Edit.Print Pluto */m b 150 450 1650 2250/m h 150 2750 1560
System.SetFont Syntax12.Scn.Fnt

Edit.ChangeFont ^
  Syntax10.Scn.Fnt  Syntax12.Scn.Fnt  Syntax14.Scn.Fnt
  Syntax10i.Scn.Fnt  Syntax12i.Scn.Fnt  Syntax14i.Scn.Fnt
  Syntax10b.Scn.Fnt  Syntax12b.Scn.Fnt  Syntax14b.Scn.Fnt
  Syntax10m.Scn.Fnt  Syntax12m.Scn.Fnt  Syntax14m.Scn.Fnt

Edit.ChangeOffset ^  96  64  32  16  0 -16 -32 -64 -96
Edit.ChangeColor ^  0 1 2  3 4 5 6 7 8 9 10 11 12 13 14 15
Edit.ChangeBackgroundColor ^
Edit.Set ^  Edit.Get ^
  left 80  width 1490  left default  width default
  lead 20  lead 34  lead 51  lead 68  lead Syntax12.Scn.Fnt
  line 34  line 42  line 51  line 68  line default
  line Syntax12.Scn.Fnt  line Syntax14.Scn.Fnt
  grid on  grid off

  adjust left  adjust right  adjust center  adjust block
  tabs 80 160 240 320 400 ~
  tabs * 100
  break before  break normal

EditTools.GetAttr *
  listet alle im markierten Text verwendeten Kombinationen von
  Fontattributen auf.

EditTools.SearchAttr font Syntax12b.Scn.Fnt
  sucht im markierten Text, beginnend ab der Caretposition,
  nach dem naechsten Zeichen in Syntax12b.Scn.Fnt

EditTools.ChangeSize ? => 8
EditTools.ChangeSize ? => 10
EditTools.ChangeSize ? => 12
EditTools.ChangeSize ? => 14
EditTools.ChangeSize ? => 16
EditTools.ChangeSize ? => 20
EditTools.ChangeSize ? => 24
____________________________________________________________
EditTools.ChangeFamily ? => Syntax
EditTools.ChangeFamily ? => Syndor
EditTools.ChangeFamily ? => Courier
EditTools.ChangeFamily ? => Times
____________________________________________________________
EditTools.ChangeStyle ? => .    normal
EditTools.ChangeStyle ? => b   bold
EditTools.ChangeStyle ? => m  medium
EditTools.ChangeStyle ? => i    italics
____________________________________________________________
Edit.ChangeOffset 0
Edit.ChangeOffset 32    superscript
Edit.ChangeOffset -32    subscript

FoldElems.Insert
GraphicElems.Insert
MenuElems.Insert
PopupElems.Insert menuName
StampElems.Insert
StyleElems.Insert styleName
TableElems.Insert
