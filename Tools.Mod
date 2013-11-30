MODULE Tools;   (*NW 7.10.2013*)
  IMPORT SYSTEM, Kernel, Files, Modules, Input, Texts, Viewers, MenuViewers, TextFrames, Oberon;
  VAR T: Texts.Text; V: MenuViewers.Viewer; W: Texts.Writer;

  PROCEDURE OpenViewer(T: Texts.Text; title: ARRAY OF CHAR);
    VAR X, Y: INTEGER;
  BEGIN 
    Oberon.AllocateUserViewer(0, X, Y);
    V := MenuViewers.New(
        TextFrames.NewMenu(title, "System.Close  System.Copy  System.Grow  Edit.Search  Edit.Store"),
        TextFrames.NewText(T, 0), TextFrames.menuH, X, Y)
  END OpenViewer;

  PROCEDURE Clear*;  (*used to clear output*)
    VAR buf: Texts.Buffer;
  BEGIN NEW(buf); Texts.OpenBuf(buf); Texts.Delete(T, 0, T.len, buf)
  END Clear;

  PROCEDURE Recall*;
    VAR M: Viewers.ViewerMsg;
  BEGIN
    IF (V # NIL) & (V.state = 0) THEN
      Viewers.Open(V, V.X, V.Y + V.H); M.id := Viewers.restore; V.handle(V, M)
    END
  END Recall;

  PROCEDURE Inspect*;
    VAR m, n, adr, data: INTEGER;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN
      adr := S.i DIV 20H * 20H; Texts.Scan(S);
      IF S.class = Texts.Int THEN n := S.i ELSE n := 8 END ;
      REPEAT DEC(n); Texts.WriteLn(W); Texts.WriteHex(W, adr); Texts.Write(W, 9X); m := 8;
        REPEAT SYSTEM.GET(adr, data); INC(adr, 4); Texts.WriteHex(W, data); DEC(m)
        UNTIL m = 0
      UNTIL n = 0;
      Texts.WriteLn(W); Texts.Append(T, W.buf)
    END
  END Inspect;

  PROCEDURE Sector*;
    VAR k, m, n, secno: INTEGER;
      S: Texts.Scanner;
      buf: ARRAY 256 OF INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN
      secno := S.i; Texts.Scan(S);
      IF S.class = Texts.Int THEN n := S.i ELSE n := 8 END ;
      Kernel.GetSector(secno*29, buf); Texts.WriteString(W, "Sector "); Texts.WriteInt(W, S.i, 4);
      k := 0;
      REPEAT DEC(n); m := 8; Texts.WriteLn(W); Texts.WriteHex(W, k*4); Texts.Write(W, 9X);
        REPEAT Texts.WriteHex(W, buf[k]); INC(k); DEC(m) UNTIL m = 0;
      UNTIL n = 0;
      Texts.WriteLn(W); Texts.Append(T, W.buf)
    END
  END Sector;

  PROCEDURE ShowFile*;
    VAR x, n: INTEGER;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF F # NIL THEN
        n := 0; Files.Set(R, F, 0); Files.ReadInt(R, x);
        WHILE ~R.eof DO
          IF n MOD 20H = 0 THEN Texts.WriteLn(W); Texts.WriteHex(W, n); Texts.Write(W, 9X) END ;
          Texts.WriteHex(W, x); INC(n, 4); Files.ReadInt(R, x)
        END ;
        Texts.WriteHex(W, x)
      ELSE Texts.WriteString(W, " not found")
      END ;
      Texts.WriteLn(W); Texts.Append(T, W.buf)
    END
  END ShowFile;

  PROCEDURE ShowFiles*;
    VAR f, adr: INTEGER; ch: CHAR; M: Modules.Module;
  BEGIN Modules.Load("Files", M); SYSTEM.GET(M.data + 90H, f);
    WHILE f # 0 DO
      Texts.WriteHex(W, f); Texts.Write(W, 9X); adr := f + 28; SYSTEM.GET(adr, ch);
      WHILE ch # 0X DO Texts.Write(W, ch); INC(adr); SYSTEM.GET(adr, ch) END ;
      Texts.WriteLn(W); SYSTEM.GET(f, f)
    END ;
    Texts.Append(T, W.buf)
  END ShowFiles;

  PROCEDURE Convert*;   (*convert file to txt-format*)
    VAR i: INTEGER; ch: CHAR;
      T: Texts.Text; R: Texts.Reader;  (*input*)
      F: Files.File; Q: Files.Rider;   (*output*)
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      NEW(T); Texts.Open(T, S.s);
      IF T.len > 0 THEN
        Texts.WriteString(W, "converting "); Texts.WriteString(W, S.s); Texts.OpenReader(R, T, 0); i := 0;
        WHILE S.s[i] > 0X DO INC(i) END ;
        S.s[i] := "."; S.s[i+1] := "t"; S.s[i+2] := "x"; S.s[i+3] := "t"; S.s[i+4] := 0X;
        Texts.WriteString(W, " to  "); Texts.WriteString(W, S.s); F := Files.New(S.s);
        IF F # NIL THEN
          Files.Set(Q, F, 0); Texts.Read(R, ch);
          WHILE ~R.eot DO
            IF ch = 0DX THEN Files.Write(Q, 0DX); Files.Write(Q, 0AX) ELSE Files.Write(Q, ch) END ;
            Texts.Read(R, ch)
          END ;
          Files.Register(F); Texts.WriteString(W, " done")
        END
      ELSE Texts.WriteString(W, " not found")
      END ;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END Convert;

  PROCEDURE GCoff*;
  BEGIN Oberon.Collect(-1)
  END GCoff;

  PROCEDURE Id*;
  BEGIN Texts.WriteHex(W, SYSTEM.H(1)); Texts.WriteLn(W); Texts.Append(T, W.buf)
  END Id;

BEGIN Texts.OpenWriter(W); T := TextFrames.Text(""); OpenViewer(T, "Tools.Text")
END Tools.

