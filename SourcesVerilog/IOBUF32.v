module IOBUF32 (input [31:0] I, output [31:0] O, inout [31:0] IO, input T);
genvar k;
generate // tri-state buffer for SRAM
  for (k = 0; k < 32; k = k+1)
  begin: bufblock
    IOBUF SRbuf (.I(I[k]), .O(O[k]), .IO(IO[k]), .T(T));
  end
endgenerate
endmodule
