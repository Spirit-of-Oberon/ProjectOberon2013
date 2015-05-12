module IOBUF8 (input [7:0] I, output [7:0] O, inout [7:0] IO, input [7:0] T);
genvar k;
generate // tri-state buffer for parallel port
  for (k = 0; k < 8; k = k+1)
  begin: gpioblock
    IOBUF gpiobuf (.I(I[k]), .O(O[k]), .IO(IO[k]), .T(T[k]));
  end
endgenerate
endmodule

