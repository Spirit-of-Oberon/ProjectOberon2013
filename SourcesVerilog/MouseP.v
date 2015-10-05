`timescale 1ns / 1ps  // PS/2 Logitech mouse PDR 14.10.2013 / 8.9.2015
module MouseP(
  input clk, rst,
  inout msclk, msdat,
  output [27:0] out);

  reg [9:0] x, y;
  reg [2:0] btns;
  reg Q0, Q1, run;
  reg [31:0] shreg;
  wire shift, endbit, reply;
  wire [9:0] dx, dy;

// 3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1                 bit
// 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
// ===============================================================
// p y y y y y y y y 0 1 p x x x x x x x x 0 1 p Y X t s 1 M R L 0 normal
// ---------------------------------------------------------------
// p ----response--- 0 1 --InitBuf echoed--- 1 1 1 1 1 1 1 1 1 1 1 init
// ---------------------------------------------------------------
// p = parity (ignored); X, Y = overflow; s, t = x, y sign bits

  // initially need to send F4 cmd (start reporting); add start and parity bits
  localparam InitBuf = 32'b11111111111111111111110_11110100_0;
  assign msclk = ~rst ? 0 : 1'bz;  // initial drive clock low
  assign msdat = ~run & ~shreg[0] ? 0 : 1'bz;
  assign shift = Q1 & ~Q0;  // falling edge detector
  assign reply = ~run & ~shreg[11];  // start bit of echoed InitBuf, if response
  assign endbit = run & ~shreg[0];  // normal packet received
  assign dx = {{2{shreg[5]}}, shreg[7] ? 8'b0 : shreg[19:12]};  //sign+overfl
  assign dy = {{2{shreg[6]}}, shreg[8] ? 8'b0 : shreg[30:23]};  //sign+overfl
  assign out = {run, btns, 2'b0, y, 2'b0, x};

  always @ (posedge clk) begin
    run <= rst & (reply | run); Q0 <= msclk; Q1 <= Q0;
    shreg <= ~rst ? InitBuf : (endbit | reply) ? -1 : shift ? {msdat,
shreg[31:1]} : shreg;
    x <= ~rst ? 0 : endbit ? x + dx : x;  y <= ~rst ? 0 : endbit ? y + dy
: y;
    btns <= ~rst ? 0 : endbit ? {shreg[1], shreg[3], shreg[2]} : btns;
  end

endmodule

