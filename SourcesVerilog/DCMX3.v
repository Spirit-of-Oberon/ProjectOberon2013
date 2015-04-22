module DCMX3 (input CLKIN, output CLKFX);
(* LOC = "DCM_X1Y1" *) DCM #(.CLKFX_MULTIPLY(3), .CLK_FEEDBACK("NONE"))
  dcm(.CLKIN(CLKIN), .CLKFX(CLKFX));
endmodule
