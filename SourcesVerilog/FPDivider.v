`timescale 1ns / 1ps   // NW 23.4.11

module FPDivider(
    input clk, run,
    input [31:0] x,
    input [31:0] y,
    output stall,
    output [31:0] z);

reg [4:0] S;  // state
reg [23:0] R, Q;

wire sign;
wire [7:0] xe, ye;
wire [8:0] e0, e1;
wire [23:0] q0, q1, q2;
wire [24:0] r0, r1, r2, d;

assign sign = x[31]^y[31];
assign xe = x[30:23];
assign ye = y[30:23];
assign e0 = xe - ye;
assign e1 = e0 + 126 + q1[23];

assign r0 = (S == 0) ? {2'b01, x[22:0]} : r2;
assign d = r0 - {2'b1, y[22:0]};
assign r1 = d[24] ? r0 : d;
assign r2 = {R, 1'b0};
assign q0 = (S == 0) ? 0 : Q;
assign q1 = {q0[22:0], ~d[24]};
assign q2 = q1[23] ? q1[23:0] : {q1[22:0], 1'b0};

assign z = (xe == 0) ? 0 :
  (ye == 0) ? {sign, 8'b11111111, 23'b0} :
  (~e1[8]) ? {sign, e1[7:0], q2[22:0]} :
  (~e1[7]) ? {sign, 8'b11111111, q2[22:0]} : 0;
assign stall = run & ~(S == 23);

always @ (posedge(clk)) begin
  R <= r1; Q <= q1;
  S <= run ? S+1 : 0;
end
endmodule
