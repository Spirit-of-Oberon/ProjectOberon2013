`timescale 1ns / 1ps  // NW 27.2.2011  floating-point for RISC2
module FPMultiplier(
  input clk, run,
  input [31:0] x, y,
  output stall,
  output [31:0] z);

reg [4:0] S;  // state
reg [23:0] B2, A2;

wire sign;
wire [7:0] xe, ye;
wire [8:0] e0, e1;
wire [24:0] B0;
wire [23:0] B00, B01, B1, A1, A0;
wire [23:0] z0;

assign sign = x[31] ^ y[31];
assign xe = x[30:23];
assign ye = y[30:23];
assign e0 = xe + ye;

assign B00 = (S == 0) ? 0 : B2;
assign B01 = A0[0] ? {1'b1, y[22:0]} : 0;
assign B0 = B00 + B01;
assign B1 = B0[24:1];
assign A0 = (S == 0) ? {1'b1, x[22:0]} : A2;
assign A1 = {B0[0], A0[23:1]};

assign e1 = e0 - 127 + B1[23];
assign z0 = B1[23] ? B1 : {B1[22:0], A1[23]};
assign z = (xe == 0) | (ye == 0) ? 0 :
    (~e1[8]) ? {sign, e1[7:0], z0[22:0]} :
    (~e1[7]) ? {sign, 8'b11111111, z0[22:0]} : 0;
assign stall = run & ~(S == 23);

always @ (posedge(clk)) begin
    B2 <= B1; A2 <= A1;
    S <= run ? S+1 : 0;
end
endmodule
