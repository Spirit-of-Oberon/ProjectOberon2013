`timescale 1ns / 1ps
//VID (1024x768) display controller; PDR 7.2.12 / NW 1.9.2013

module VID(
    input clk, clk25, inv,
    input [31:0] viddata,
    output req,  // read request
    output hsync, vsync,  // to display
    output [17:0] vidadr,
    output [2:0] RGB);

localparam Org = 18'h37FC0; // adr of low left corner
reg [9:0] hcnt, vcnt;
reg [31:0] buffer;
reg hblank1;
wire hblank, vblank, hend, vend;
wire pixel, vid;

// 25MHz clock; 2 pixels per cycle
assign hend = (hcnt == 591);
assign vend = (vcnt == 791);
assign hblank = hcnt[9];  // hcnt >= 512
assign vblank = (vcnt[8] & vcnt[9]);  // (vcnt >= 768)
assign hsync = (hcnt >= 537) & (hcnt < 553);
assign vsync = ~((vcnt >= 772) & (vcnt < 776));

assign vidadr = {3'b0, ~vcnt, hcnt[8:4]} + Org;
assign req = ~vblank & ~hcnt[9] & (hcnt[3:0] == 0);
assign pixel = clk25 ? buffer[0] : buffer[1];
assign vid = (pixel ^ inv) & ~hblank1 & ~vblank;
assign RGB = {vid, vid, vid};

always @(posedge clk) begin
  hcnt <= hend ? 0 : hcnt+1;
  vcnt <= hend ? (vend ? 0 : (vcnt+1)) : vcnt;
  hblank1 <= hblank;
  buffer <= req ? viddata : {2'b0, buffer[31:2]};
end
endmodule
