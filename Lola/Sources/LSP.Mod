MODULE LSP;  (*display data structure;  NW 28.8.2015*)
  IMPORT Texts, Oberon, LSB;

  VAR W: Texts.Writer;
    C: ARRAY 64, 6 OF CHAR;

  PROCEDURE PrintType(typ: LSB.Type);
    VAR obj: LSB.Object;
  BEGIN
    IF typ IS LSB.ArrayType THEN
      Texts.Write(W, "["); Texts.WriteInt(W, typ.len, 1); Texts.Write(W, "]"); PrintType(typ(LSB.ArrayType).eltyp)
    ELSIF typ IS LSB.UnitType THEN
      Texts.WriteString(W, "UnitType "); obj := typ(LSB.UnitType).firstobj;
    ELSE Texts.WriteString(W, "BIT")
    END ;
    Texts.Append(Oberon.Log, W.buf)
  END PrintType;

  PROCEDURE PrintTree(x: LSB.Item; n: INTEGER);
    VAR i: INTEGER;
  BEGIN
    IF x # NIL THEN  i := n;
      IF x IS LSB.Object THEN
        WHILE i > 0 DO Texts.Write(W, 9X); DEC(i) END ;
        Texts.WriteString(W, x(LSB.Object).name); Texts.WriteLn(W)
      ELSE
        PrintTree(x.a, n+1);
        WHILE i > 0 DO Texts.Write(W, 9X); DEC(i) END ;
        IF x.tag = LSB.lit THEN Texts. WriteInt(W, x.val, 1) ELSE Texts.WriteString(W, C[x.tag]); END ;
        Texts.WriteLn(W);
        PrintTree(x.b, n+1)
      END
    END
  END PrintTree;

  PROCEDURE PrintObj(obj: LSB.Object; n: INTEGER);
    VAR apar: LSB.Item; obj1: LSB.Object;
  BEGIN
    IF n > 0 THEN Texts.Write(W, 9X) END ;
    Texts.WriteString(W, C[obj.tag]); Texts.Write(W, " "); Texts.WriteString(W, obj.name); Texts.Append(Oberon.Log, W.buf);
    IF obj.tag = LSB.const THEN Texts.WriteString(W, " = "); PrintTree(obj.b, 1); Texts.WriteLn(W)
    ELSIF obj.tag = LSB.typ THEN
      IF obj.type IS LSB.UnitType THEN  (*formal param list*)
        obj1 := obj.type(LSB.UnitType).firstobj;
        Texts.WriteString(W, " BEGIN "); Texts.WriteLn(W);
        WHILE (obj1 # NIL) & (obj1 # LSB.root) DO PrintObj(obj1, 0); obj1 := obj1.next END ;
        Texts.WriteString(W, "END"); Texts.WriteLn(W)
      ELSE PrintType(obj.type)
      END
    ELSE (*var*) Texts.WriteString(W, ": ");
      IF obj.type IS LSB.UnitType THEN
        Texts.WriteString(W, obj.type.typobj.name);
        apar := obj.b; Texts.WriteString(W, " [");  (*actual param list*)
        WHILE apar # NIL DO PrintTree(apar.b, 1); apar := apar.a END ;
        Texts.Write(W, "]"); Texts.WriteLn(W)
      ELSE PrintType(obj.type);
        Texts.WriteString(W, " #"); Texts.WriteInt(W, obj.val, 1);
        IF obj.a # NIL THEN
           IF obj.val = 0 THEN Texts.WriteString(W, " CLK") ELSIF obj.val = 1 THEN (*indexed*) Texts.WriteString(W, " DEMUX") END ;
           PrintTree(obj.a, 1)
        END ;
        IF obj.b # NIL THEN Texts.WriteString(W, " := "); Texts.WriteLn(W); PrintTree(obj.b, 1)
        ELSE Texts.WriteLn(W)
        END
      END
    END ;
    Texts.Append(Oberon.Log, W.buf)
  END PrintObj;

  PROCEDURE List*;
    VAR obj: LSB.Object;
  BEGIN obj := LSB.top;
    Texts.WriteString(W, "listing "); Texts.WriteString(W, LSB.modname); Texts.WriteLn(W);
    WHILE (obj # LSB.root) & (obj # NIL) DO PrintObj(obj, 0); obj := obj.next END ;
    Texts.Append(Oberon.Log, W.buf)
  END List;

BEGIN Texts.OpenWriter(W);
  C[LSB.const] := "CONST"; C[LSB.typ] := "TYPE"; C[LSB.var] := "VAR";
  C[LSB.lit] := "LIT"; C[LSB.sel] := "MUX"; C[LSB.range] := ": "; C[LSB.cons] := ", "; C[LSB.repl] := "**";
  C[LSB.or] := "| "; C[LSB.xor] := "^ "; C[LSB.and] := "& ";  C[LSB.not] := "~ ";
  C[LSB.add] := "+ "; C[LSB.sub] := "- "; C[LSB.mul] := "* "; C[LSB.div] := "/ ";
  C[LSB.eql] := "= "; C[LSB.neq] := "# "; C[LSB.lss] := "< "; C[LSB.geq] := ">="; C[LSB.leq] := "<="; C[LSB.gtr] := "> ";
  C[LSB.then] := " -> "; C[LSB.else] := " :: "; C[LSB.ts] := "TS "; C[LSB.next] := "--"
END LSP.
