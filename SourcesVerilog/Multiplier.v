`timescale 1ns / 1ps  // NW 3.12.2010

module Multiplier(
  input CLK, run, u,
  output stall,
  input [31:0] x, y,
  output [63:0] z);

reg [4:0] S;    // state
reg [31:0] B, A;  // high and low parts of partial product
wire [32:0] b0, b00, b01;
wire [31:0] b1, a0, a1;

assign stall = run & ~(S == 31);
assign b00 = (S == 0) ? 0 : {B[31], B};
assign b01 = a0[0] ? {y[31] & u, y} : 0;
assign b0 = ((S == 31) & u) ? b00 - b01 : b00 + b01;
assign b1 = b0[32:1];
assign a0 = (S == 0) ? x : A;
assign a1 = {b0[0], a0[31:1]};
assign z = {b1, a1};

always @ (posedge(CLK)) begin
  B <= b1; A <= a1;
  S <= run ? S+1 : 0;
end

endmodule
