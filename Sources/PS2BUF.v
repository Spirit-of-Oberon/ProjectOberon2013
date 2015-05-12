//PS/2 2-wire open-collector interface from tri-state buffers PDR 26.11.14
//if T[x]=0, drive the IO[x] line with a 0; if I[x]=1, be tri-state (PULLUP in ucf)
module PS2BUF (output [1:0] O, inout [1:0] IO, input [1:0] T);
  IOBUF buf0 (.I(0), .O(O[0]), .IO(IO[0]), .T(T[0]));
  IOBUF buf1 (.I(0), .O(O[1]), .IO(IO[1]), .T(T[1]));    
endmodule
