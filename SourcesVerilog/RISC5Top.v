`timescale 1ns / 1ps  // 22.9.2015
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
  input PS2C, PS2D,    // keyboard
  inout msclk, msdat,
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

reg rst, clk;
wire[23:0] adr;
wire [3:0] iowadr; // word address
wire [31:0] inbus, inbus0;  // data to RISC core
wire [31:0] outbus;  // data from RISC core
wire rd, wr, ben, ioenb, dspreq;

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

RISC5 riscx(.clk(clk), .rst(rst), .rd(rd), .wr(wr), .ben(ben), .stallX(dspreq),
   .adr(adr), .codebus(inbus0), .inbus(inbus), .outbus(outbus));
RS232R receiver(.clk(clk), .rst(rst), .RxD(RxD), .fsel(bitrate), .done(doneRx),
   .data(dataRx), .rdy(rdyRx));
RS232T transmitter(.clk(clk), .rst(rst), .start(startTx), .fsel(bitrate),
   .data(dataTx), .TxD(TxD), .rdy(rdyTx));
SPI spi(.clk(clk), .rst(rst), .start(spiStart), .dataTx(outbus),
   .fast(spiCtrl[2]), .dataRx(spiRx), .rdy(spiRdy),
 	.SCLK(SCLK[0]), .MOSI(MOSI[0]), .MISO(MISO[0] & MISO[1]));
VID vid(.clk(clk), .req(dspreq), .inv(swi[7]),
   .vidadr(vidadr), .viddata(inbus0), .RGB(RGB), .hsync(hsync), .vsync(vsync));
PS2 kbd(.clk(clk), .rst(rst), .done(doneKbd), .rdy(rdyKbd), .shift(),
   .data(dataKbd), .PS2C(PS2C), .PS2D(PS2D));
MouseP Ms(.clk(clk), .rst(rst), .msclk(msclk), .msdat(msdat), .out(dataMs));

assign iowadr = adr[5:2];
assign ioenb = (adr[23:6] == 18'h3FFFF);
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
	 
assign SRce0 = ben & adr[1];
assign SRce1 = ben & ~adr[1];
assign SRbe0 = ben & adr[0];
assign SRbe1 = ben & ~adr[0];
assign SRwe = ~wr | clk;
assign SRoe = wr;
assign SRbe = {SRbe1, SRbe0, SRbe1, SRbe0};
assign SRadr = dspreq ? vidadr : adr[19:2];

genvar i;
generate // tri-state buffer for SRAM
  for (i = 0; i < 32; i = i+1)
  begin: bufblock
    IOBUF SRbuf (.I(outbus[i]), .O(inbus0[i]), .IO(SRdat[i]), .T(~wr));
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

always @ (posedge CLK50M) clk <= ~clk;
endmodule