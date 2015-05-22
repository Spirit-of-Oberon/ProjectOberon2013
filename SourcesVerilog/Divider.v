`timescale 1ns / 1ps  // NW 31.10.10 / 1.5.15

module Divider(
  input clk, run,
  output stall,
  input [31:0] x, y,  // y > 0
  output [31:0] quot, rem);

reg [4:0] S;  // state
reg [31:0] R, Q;
wire neg;
wire [31:0] x0, r0, r1, r2, q0, q1, d;

assign stall = run & ~(S == 31);
assign neg = x[31];
assign x0 = neg ? ~x + y : x;  // -x + (y-1);
assign r0 = (S == 0) ? 0 : R;
assign d = r1 - y;
assign r1 = {r0[30:0], q0[31]};
assign r2 = d[31] ? r1 : d;
assign q0 = (S == 0) ? x0 : Q;
assign q1 = {q0[30:0], ~d[31]};
assign rem = neg ? ~r2 + y : r2;  // (y-1) - r2;
assign quot = neg ? -q1 : q1;

always @ (posedge(clk)) begin
  R <= r2; Q <= q1;
  S <= run ? S+1 : 0;
end

endmodule
