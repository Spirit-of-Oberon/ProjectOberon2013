ORP.Compile @\s  ORL.Link M0  ORL.StartV24  ORL.Load  ORL.Flush
TestTRM.SR  0~

MODULE M0;
  IMPORT RS232, SYSTEM;
  VAR x, y: REAL; k: INTEGER;

  PROCEDURE sqrt0*(x: REAL): REAL;
    CONST c1 = 0.70710680;   (* 1/sqrt(2) *)
      c2 = 0.590162067;
    VAR s: REAL; e: INTEGER;
  BEGIN 
    IF x > 0.0 THEN
      UNPK(x, e);
      s := c2*(x+c1);
      s := s + (x/s);
      s := 0.25*s + x/s;
      s := 0.5 * (s + x/s);
      IF ODD(e) THEN e := e+1; s := c1*s END ;
      PACK(s, e DIV 2)
    ELSIF x = 0.0 THEN s := 0.0
    ELSE (*trap*)
    END ;
    RETURN s
  END sqrt0;

  PROCEDURE sqrt1*(x: REAL): REAL;
    CONST c1 = 0.34321980;
      c2 = 0.89969072;
      c3 = -0.36404088;
      c4 = 0.50000084;
      c5 =  0.70710680;   (* 1/sqrt(2) *)
    VAR s: REAL; e: INTEGER;
  BEGIN 
    IF x > 0.0 THEN
      UNPK(x, e); x := x * 0.5; INC(e);
      s := c1*x + c2 + c3/(c4 + x);
      s := (x/s + s) * 0.5;
      IF ODD(e) THEN e := e+1; s := c5*s END ;
      PACK(s, e DIV 2)
    ELSE s := 0.0
    END ;
    RETURN s
  END sqrt1;

BEGIN SYSTEM.PUT(-60, 1);
  REPEAT RS232.RecInt(k); k := 0; x := 1.0;
    REPEAT RS232.SendReal(x); y := sqrt0(x); RS232.SendReal(y); RS232.SendReal(y*y - x);
      y := sqrt1(x); RS232.SendReal(y); RS232.SendReal(y*y- x); RS232.Line; x := x + 0.1; INC(k)
    UNTIL k = 11;
    RS232.End
  UNTIL FALSE
END M0.

  1.0000000E+00  1.0000000E+00  0.0000000E+00  1.0000000E+00  0.0000000E+00
  1.0999999E+00  1.0488088E+00  0.0000000E+00  1.0488088E+00  0.0000000E+00
  1.1999998E+00  1.0954450E+00  0.0000000E+00  1.0954450E+00  0.0000000E+00
  1.2999997E+00  1.1401753E+00  0.0000000E+00  1.1401752E+00 -2.3841858E-07
  1.3999996E+00  1.1832157E+00 -2.3841858E-07  1.1832159E+00  1.1920929E-07
  1.4999995E+00  1.2247447E+00  0.0000000E+00  1.2247447E+00  0.0000000E+00
  1.5999994E+00  1.2649108E+00 -1.1920929E-07  1.2649108E+00 -1.1920929E-07
  1.6999993E+00  1.3038403E+00  1.1920929E-07  1.3038403E+00  1.1920929E-07
  1.7999992E+00  1.3416405E+00 -1.1920929E-07  1.3416405E+00 -1.1920929E-07
  1.8999991E+00  1.3784046E+00  1.1920929E-07  1.3784045E+00 -2.3841858E-07
  1.9999990E+00  1.4142132E+00 -2.3841858E-07  1.4142133E+00  1.1920929E-07
