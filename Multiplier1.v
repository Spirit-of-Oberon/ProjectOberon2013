`timescale 1ns / 1ps  // NW 29.4.2011
module Multiplier1(
  input clk, run, u,
  output stall,
  input [31:0] x, y,
  output [63:0] z);
	 
reg S;  // state
reg [15:0] z0;
reg [47:0] z1, z2;
wire [35:0] p0, p1, p2, p3;

assign stall = run & ~S;
assign z[15:0] = z0;
assign z[63:16] = z1 + z2;

MULT18X18 mult0(.P(p0), .A({2'b0, x[15:0]}), .B({2'b0, y[15:0]}));
MULT18X18 mult1(.P(p1), .A({{2{u&x[31]}}, x[31:16]}), .B({2'b0, y[15:0]}));
MULT18X18 mult2(.P(p2), .A({2'b0, x[15:0]}), .B({{2{u&y[31]}}, y[31:16]}));
MULT18X18 mult3(.P(p3), .A({{2{u&x[31]}}, x[31:16]}), .B({{2{u&y[31]}}, y[31:16]}));

always @(posedge clk) begin
  S <= stall;
  z0 <= p0[15:0];
  z1 <= {{32'b0}, p0[31:16]} + {{16{u&p1[31]}}, p1[31:0]};
  z2 <= {{16{u&p2[31]}}, p2[31:0]} + {p3[31:0], 16'b0};
end
endmodule
