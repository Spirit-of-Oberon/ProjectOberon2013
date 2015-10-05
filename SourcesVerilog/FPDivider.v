`timescale 1ns / 1ps   // NW 18.9.2015

module FPDivider(
    input clk, run,
    input [31:0] x,
    input [31:0] y,
    output stall,
    output [31:0] z);

reg [4:0] S;  // state
reg [23:0] R;
reg [24:0] Q;

wire sign;
wire [7:0] xe, ye;
wire [8:0] e0, e1;
wire [24:0] r0, r1, d, q0;
wire [23:0] z0;

assign sign = x[31]^y[31];
assign xe = x[30:23];
assign ye = y[30:23];
assign e0 = {1'b0, xe} - {1'b0, ye};
assign e1 = e0 + 126 + Q[24];
assign stall = run & ~(S == 25);

assign r0 = (S == 0) ? {2'b1, x[22:0]} : {R, 1'b0};
assign d = r0 - {2'b1, y[22:0]};
assign r1 = d[24] ? r0 : d;
assign q0 = (S == 0) ? 0 : Q;

assign z0 = Q[24] ? Q[24:1] : Q[23:0];
assign z = (xe == 0) ? 0 :
  (ye == 0) ? {sign, 8'b11111111, 23'b0} :
  (~e1[8]) ? {sign, e1[7:0], z0[22:0]} :
  (~e1[7]) ? {sign, 8'b11111111, z0[22:0]} : 0;

always @ (posedge(clk)) begin
  R <= r1[23:0];
  Q <= {q0[23:0], ~d[24]};
  S <= run ? S+1 : 0;
end
endmodule
