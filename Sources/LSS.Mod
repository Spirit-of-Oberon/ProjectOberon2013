MODULE LSS; (* NW 16.10.93 / 12.4.2015*)
  IMPORT Texts, Oberon;
  
  CONST IdLen* = 32; NofKeys = 10;
    (*symbols*) null = 0;
    arrow* = 1; times* = 2; div* = 3; and* = 4; plus* = 5; minus* = 6; or* = 7; xor* = 8;  not* = 9;
    eql* = 10; neq* = 11; lss* = 12; leq* = 13; gtr* = 14; geq* = 15;
    at* = 16; apo* = 17; period* = 18; comma* = 19; colon* = 20; rparen* = 21; rbrak* = 22; rbrace* = 23; 
    then* = 24; lparen* = 26; lbrak* = 27; lbrace* = 28; repl* = 29; becomes* = 30;
    ident* = 31; integer* = 32; reg* = 35; semicolon* = 40; end* = 41;
    const* = 51; type* = 52; var* = 53; out* = 54; inout* = 55; in* = 56;
    begin* = 57; module* = 58; eof = 59;

  TYPE Ident* = ARRAY IdLen OF CHAR;

  VAR val*: LONGINT;
    id*: Ident;
    error*: BOOLEAN;

    ch: CHAR;
    errpos: LONGINT;
    R: Texts.Reader;
    W: Texts.Writer;
    key: ARRAY NofKeys OF Ident;
    symno: ARRAY NofKeys OF INTEGER;

  PROCEDURE Mark*(msg: ARRAY OF CHAR);
    VAR p: LONGINT;
  BEGIN p := Texts.Pos(R);
    IF p > errpos+2 THEN
      Texts.WriteString(W, "  pos "); Texts.WriteInt(W, p, 1);
      Texts.WriteString(W, "  err:  "); Texts.WriteString(W, msg);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END ;
    errpos := p; error := TRUE
  END Mark;
  
  PROCEDURE identifier(VAR sym: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 0;
    REPEAT
      IF i < IdLen THEN id[i] := ch; INC(i) END ;
      Texts.Read(R, ch)
    UNTIL (ch < "0") OR (ch > "9") & (ch < "A") OR (ch > "Z") & (ch < "a") OR (ch > "z");
    IF ch = "'" THEN
      IF i < IdLen THEN id[i] := ch; INC(i) END ;
      Texts.Read(R, ch)
    END ;
    IF i = IdLen THEN Mark("ident too long"); id[IdLen-1] := 0X
    ELSE id[i] := 0X
    END ;
    i := 0;
    WHILE (i < NofKeys) & (id # key[i]) DO INC(i) END ;
    IF i < NofKeys THEN sym := symno[i] ELSE sym := ident END
  END identifier;

  PROCEDURE Number(VAR sym: INTEGER);
    VAR i, k, h, n: INTEGER;
      d: ARRAY 16 OF INTEGER;
  BEGIN sym := integer; i := 0; k := 0; n := 0;
    REPEAT
      IF n < 16 THEN d[n] := ORD(ch)-30H; INC(n) ELSE Mark("too many digits"); n := 0 END ;
      Texts.Read(R, ch)
    UNTIL (ch < "0") OR (ch > "9") & (ch < "A") OR (ch > "F");
    IF ch = "H" THEN (*hex*)
      REPEAT h := d[i];
        IF h >= 10 THEN h := h-7 END ;
        k := k*10H + h; INC(i) (*no overflow check*)
      UNTIL i = n;
      Texts.Read(R, ch)
    ELSE
      REPEAT k := k*10 + d[i]; INC(i) UNTIL i = n
    END ;
    val := k
  END Number;

  PROCEDURE comment;
  BEGIN Texts.Read(R, ch);
    REPEAT
      WHILE ~R.eot & (ch # "*") DO
        IF ch = "(" THEN Texts.Read(R, ch);
          IF ch = "*" THEN comment END
        ELSE Texts.Read(R, ch)
        END
      END ;
      WHILE ch = "*" DO Texts.Read(R, ch) END
    UNTIL (ch = ")") OR R.eot;
    IF ~R.eot THEN Texts.Read(R, ch) ELSE Mark("comment not terminated") END
  END comment;

  PROCEDURE Get*(VAR sym: INTEGER);
  BEGIN
    REPEAT
      WHILE ~R.eot & (ch <= " ") DO Texts.Read(R, ch) END;
      IF R.eot THEN sym := eof
      ELSIF ch < "A" THEN 
        IF ch < "0" THEN
          IF ch = "!" THEN Texts.Read(R, ch); sym := repl
          ELSIF ch = "#" THEN Texts.Read(R, ch); sym := neq
          ELSIF ch = "$" THEN Texts.Read(R, ch); sym := null
          ELSIF ch = "&" THEN Texts.Read(R, ch); sym := and
          ELSIF ch = "'" THEN Texts.Read(R, ch); sym := apo
          ELSIF ch = "(" THEN Texts.Read(R, ch); 
            IF ch = "*" THEN sym := null; comment ELSE sym := lparen END
          ELSIF ch = ")" THEN Texts.Read(R, ch); sym := rparen
          ELSIF ch = "*" THEN Texts.Read(R, ch); sym := times
          ELSIF ch = "+" THEN Texts.Read(R, ch); sym := plus
          ELSIF ch = "," THEN Texts.Read(R, ch); sym := comma
          ELSIF ch = "-" THEN Texts.Read(R, ch);
            IF ch = ">" THEN Texts.Read(R, ch); sym := then ELSE sym := minus END
          ELSIF ch = "." THEN Texts.Read(R, ch); sym := period
          ELSIF ch = "/" THEN Texts.Read(R, ch); sym := div
          ELSE sym := null
          END
        ELSIF ch <= "9" THEN Number(sym)
        ELSIF ch = ":" THEN Texts.Read(R, ch);
          IF ch = "=" THEN Texts.Read(R, ch); sym := becomes ELSE sym := colon END
        ELSIF ch = ";" THEN Texts.Read(R, ch); sym := semicolon
        ELSIF ch = "<" THEN Texts.Read(R, ch);
          IF ch = "=" THEN Texts.Read(R, ch); sym := leq ELSE sym := lss END
        ELSIF ch = "=" THEN Texts.Read(R, ch); sym := eql
        ELSIF ch = ">" THEN Texts.Read(R, ch);
          IF ch = "=" THEN Texts.Read(R, ch); sym := geq ELSE sym := gtr END
        ELSIF ch = "?" THEN Texts.Read(R, ch); sym := then
        ELSIF ch = "@" THEN Texts.Read(R, ch); sym := at
        ELSE sym := null
        END
      ELSIF ch <= "Z" THEN identifier(sym)
      ELSIF ch < "a" THEN
        IF ch = "[" THEN Texts.Read(R, ch); sym := lbrak
        ELSIF ch = "]" THEN Texts.Read(R, ch); sym := rbrak
        ELSIF ch = "^" THEN Texts.Read(R, ch); sym := xor
        ELSE sym := null
        END
      ELSIF ch <= "z" THEN identifier(sym)
      ELSIF ch <= "{" THEN Texts.Read(R, ch); sym := lbrace
      ELSIF ch <= "|" THEN Texts.Read(R, ch); sym := or
      ELSIF ch <= "}" THEN Texts.Read(R, ch); sym := rbrace
      ELSIF ch <= "~" THEN Texts.Read(R, ch); sym := not
      ELSE sym := null
      END
    UNTIL sym # null
  END Get;

  PROCEDURE Init*(T: Texts.Text; pos: LONGINT);
  BEGIN error := FALSE; errpos := pos; Texts.OpenReader(R, T, pos); Texts.Read(R, ch)
  END Init;
  
BEGIN Texts.OpenWriter(W);
  key[ 0] := "BEGIN"; symno[0] := begin;
  key[ 1] := "CONST"; symno[1] := const;
  key[ 2] := "END"; symno[2] := end;
  key[3] := "IN"; symno[3] := in;
  key[4] := "INOUT"; symno[4] := inout;
  key[5] := "MODULE"; symno[5] := module;
  key[6] := "OUT"; symno[6] := out;
  key[7] := "REG"; symno[7] := reg;
  key[8] := "TYPE"; symno[8] := type;
  key[9] := "VAR"; symno[9] := var;
END LSS.
