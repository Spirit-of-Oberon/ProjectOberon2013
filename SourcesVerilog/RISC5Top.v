`timescale 1ns / 1ps  // NW 27.5.09 / 14.10.2014
// with SRAM, byte access, flt.-pt., and gpio
// PS/2 mouse and network 7.1.2014 PDR

module RISC5Top(
  input CLK50M,
  input [3:0] btn,
  input [7:0] swi,
  input  RxD,   // RS-232
  output TxD,
  output [7:0] leds,
  output SRce0, SRce1, SRwe, SRoe,  //SRAM
  output [3:0] SRbe,
  output [17:0] SRadr,
  inout [31:0] SRdat,
  input [1:0] MISO,          // SPI - SD card & network
  output [1:0] SCLK, MOSI,
  output [1:0] SS,
  output NEN,  // network enable
  output hsync, vsync, // video controller
  output [2:0] RGB,
  inout PS2C, PS2D,    // keyboard
  inout [1:0] mouse,
  inout [7:0] gpio);

// IO addresses for input / output
// 0  milliseconds / --
// 1  switches / LEDs
// 2  RS-232 data / RS-232 data (start)
// 3  RS-232 status / RS-232 control
// 4  SPI data / SPI data (start)
// 5  SPI status / SPI control
// 6  PS2 keyboard / --
// 7  mouse / --
// 8  general-purpose I/O data
// 9  general-purpose I/O tri-state control

wire clk, clk50;
reg rst, clk25;

wire[19:0] adr;
wire [3:0] iowadr; // word address
wire rd, wr, be, ioenb, dspreq;
wire a0, a1, a2, a3;
wire[31:0] inbus, inbus0, inbus1, outbus, outbus1;
wire [7:0] inbusL, outbusB0, outbusB1, outbusB2, outbusB3;
wire [23:0] inbusH;

wire [7:0] dataTx, dataRx, dataKbd;
wire rdyRx, doneRx, startTx, rdyTx, rdyKbd, doneKbd;
wire [27:0] dataMs;
reg bitrate;  // for RS232
wire limit;  // of cnt0

reg [7:0] Lreg;
reg [15:0] cnt0;
reg [31:0] cnt1; // milliseconds

wire [31:0] spiRx;
wire spiStart, spiRdy;
reg [3:0] spiCtrl;
wire [17:0] vidadr;
reg [7:0] gpout, gpoc;
wire [7:0] gpin;

RISC5 riscx(.clk(clk), .rst(rst), .rd(rd), .wr(wr), .ben(be), .stallX(dspreq),
   .adr(adr), .codebus(inbus1), .inbus(inbus), .outbus(outbus));
RS232R receiver(.clk(clk), .rst(rst), .RxD(RxD), .fsel(bitrate), .done(doneRx),
   .data(dataRx), .rdy(rdyRx));
RS232T transmitter(.clk(clk), .rst(rst), .start(startTx), .fsel(bitrate),
   .data(dataTx), .TxD(TxD), .rdy(rdyTx));
SPI spi(.clk(clk), .rst(rst), .start(spiStart), .dataTx(outbus),
   .fast(spiCtrl[2]), .dataRx(spiRx), .rdy(spiRdy),
 	.SCLK(SCLK[0]), .MOSI(MOSI[0]), .MISO(MISO[0] & MISO[1]));
VID vid(.clk(clk), .req(dspreq), .inv(swi[7]),
   .vidadr(vidadr), .viddata(inbus1), .RGB(RGB), .hsync(hsync), .vsync(vsync));
PS2 kbd(.clk(clk), .rst(rst), .done(doneKbd), .rdy(rdyKbd), .shift(),
   .data(dataKbd), .PS2C(PS2C), .PS2D(PS2D));
MouseP Ms(.clk(clk), .rst(rst), .io(mouse), .out(dataMs));

assign iowadr = adr[5:2];
assign ioenb = (adr[19:6] == 14'b11111111111111);
assign inbus = ~ioenb ? inbus0 :
   ((iowadr == 0) ? cnt1 :
    (iowadr == 1) ? {20'b0, btn, swi} :
    (iowadr == 2) ? {24'b0, dataRx} :
    (iowadr == 3) ? {30'b0, rdyTx, rdyRx} :
    (iowadr == 4) ? spiRx :
    (iowadr == 5) ? {31'b0, spiRdy} :
    (iowadr == 6) ? {3'b0, rdyKbd, dataMs} :
    (iowadr == 7) ? {24'b0, dataKbd} :
    (iowadr == 8) ? {24'b0, gpin} :
	 (iowadr == 9) ? {24'b0, gpoc} : 0);
	 
// byte access to SRAM
assign a0 = ~adr[1] & ~adr[0];
assign a1 = ~adr[1] & adr[0];
assign a2 = adr[1] & ~adr[0];
assign a3 = adr[1] & adr[0];
assign SRce0 = be & adr[1];
assign SRce1 = be & ~adr[1];
assign SRbe0 = be & adr[0];
assign SRbe1 = be & ~adr[0];
assign SRwe = ~wr | clk25;
assign SRoe = wr;
assign SRbe = {SRbe1, SRbe0, SRbe1, SRbe0};
assign SRadr = dspreq ? vidadr : adr[19:2];

assign inbusL = (~be | a0) ? inbus1[7:0] :
  a1 ? inbus1[15:8] : a2 ? inbus1[23:16] : inbus1[31:24];
assign inbusH = ~be ? inbus1[31:8] : 24'b0;
assign inbus0 = {inbusH, inbusL};assign outbus1[7:0] = outbus[7:0];

assign outbusB0 = outbus[7:0];
assign outbusB1 = be & a1 ? outbus[7:0] : outbus[15:8];
assign outbusB2 = be & a2 ? outbus[7:0] : outbus[23:16];
assign outbusB3 = be & a3 ? outbus[7:0] : outbus[31:24];
assign outbus1 = {outbusB3, outbusB2, outbusB1, outbusB0};

genvar i;
generate // tri-state buffer for SRAM
  for (i = 0; i < 32; i = i+1)
  begin: bufblock
    IOBUF SRbuf (.I(outbus1[i]), .O(inbus1[i]), .IO(SRdat[i]), .T(~wr));
  end
endgenerate

generate // tri-state buffer for gpio port
  for (i = 0; i < 8; i = i+1)
  begin: gpioblock
    IOBUF gpiobuf (.I(gpout[i]), .O(gpin[i]), .IO(gpio[i]), .T(~gpoc[i]));
  end
endgenerate

assign dataTx = outbus[7:0];
assign startTx = wr & ioenb & (iowadr == 2);
assign doneRx = rd & ioenb & (iowadr == 2);
assign limit = (cnt0 == 24999);
assign leds = Lreg;
assign spiStart = wr & ioenb & (iowadr == 4);
assign SS = ~spiCtrl[1:0];  //active low slave select
assign MOSI[1] = MOSI[0], SCLK[1] = SCLK[0], NEN = spiCtrl[3];
assign doneKbd = rd & ioenb & (iowadr == 7);

always @(posedge clk)
begin
  rst <= ((cnt1[4:0] == 0) & limit) ? ~btn[3] : rst;
  Lreg <= ~rst ? 0 : (wr & ioenb & (iowadr == 1)) ? outbus[7:0] : Lreg;
  cnt0 <= limit ? 0 : cnt0 + 1;
  cnt1 <= cnt1 + limit;
  spiCtrl <= ~rst ? 0 : (wr & ioenb & (iowadr == 5)) ? outbus[3:0] : spiCtrl;
  bitrate <= ~rst ? 0 : (wr & ioenb & (iowadr == 3)) ? outbus[0] : bitrate;
  gpout <= (wr & ioenb & (iowadr == 8)) ? outbus[7:0] : gpout;
  gpoc <= ~rst ? 0 : (wr & ioenb & (iowadr == 9)) ? outbus[7:0] : gpoc;
end

//The Clocks
IBUFG clkInBuf(.I(CLK50M), .O(clk50));
always @ (posedge clk50) clk25 <= ~clk25;
BUFG clk150buf(.I(clk25), .O(clk));
endmodule