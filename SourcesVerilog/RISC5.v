`timescale 1ns / 1ps  // 25.9.2015

module RISC5(
input clk, rst, stallX,
input [31:0] inbus, codebus,
output [23:0] adr,
output rd, wr, ben,
output [31:0] outbus);

localparam StartAdr = 22'h3FF800;

reg [21:0] PC;
reg [31:0] IR;  // instruction register
reg N, Z, C, OV;  // condition flags 
reg [31:0] R [0:15];  // array of 16 registers
reg [31:0] H;  // aux register
reg stall1, PMsel;

wire [31:0] ins, pmout;
wire [21:0] pcmux, nxpc;
wire cond, S;
wire sa, sb, sc;

wire p, q, u, v, w;  // instruction fields
wire [3:0] op, ira, ira0, irb, irc;
wire [2:0] cc;
wire [15:0] imm;
wire [19:0] off;
wire [23:0] offL;

wire regwr;
wire stall, stallL, stallM, stallD, stallFA, stallFM, stallFD;
wire [1:0] sc1, sc0;  // shift counts

wire a0, a1, a2, a3;
wire [7:0] inbusL, outbusB0, outbusB1, outbusB2, outbusB3;
wire [23:0] inbusH;

wire [31:0] A, B, C0, C1, aluRes, regmux;
wire [31:0] s1, s2, s3, t1, t2, t3;
wire [31:0] quotient, remainder;
wire [63:0] product;
wire [31:0] fsum, fprod, fquot;

wire MOV, LSL, ASR, ROR, AND, ANN, IOR, XOR;  // operation signals
wire ADD, SUB, MUL, DIV; wire FAD, FSB, FML, FDV;
wire LDR, STR, BR;

PROM PM (.adr(pcmux[8:0]), .data(pmout), .clk(clk));

Multiplier mulUnit (.clk(clk), .run(MUL), .stall(stallM),
   .u(~u), .x(B), .y(C1), .z(product));

Divider divUnit (.clk(clk), .run(DIV), .stall(stallD),
   .u(~u), .x(B), .y(C1), .quot(quotient), .rem(remainder));

FPAdder fpaddx (.clk(clk), .run(FAD|FSB), .u(u), .v(v), .stall(stallFA),
   .x(B), .y({FSB^C0[31], C0[30:0]}), .z(fsum));

FPMultiplier fpmulx (.clk(clk), .run(FML), .stall(stallFM),
   .x(B), .y(C0), .z(fprod));

FPDivider fpdivx (.clk(clk), .run(FDV), .stall(stallFD),
   .x(B), .y(C0), .z(fquot));

assign ins = PMsel ? pmout : IR;  // decoding
assign p = ins[31];
assign q = ins[30];
assign u = ins[29];
assign v = ins[28];
assign w = ins[16];
assign cc  = ins[26:24];
assign ira = ins[27:24];
assign irb = ins[23:20];
assign op  = ins[19:16];
assign irc = ins[3:0];
assign imm = ins[15:0];   // reg instr.
assign off = ins[19:0];   // mem instr.
assign offL = ins[23:0];  // branch instr.

assign MOV = ~p & (op == 0);
assign LSL = ~p & (op == 1);
assign ASR = ~p & (op == 2);
assign ROR = ~p & (op == 3);
assign AND = ~p & (op == 4);
assign ANN = ~p & (op == 5);
assign IOR = ~p & (op == 6);
assign XOR = ~p & (op == 7);

assign ADD = ~p & (op == 8);
assign SUB = ~p & (op == 9);
assign MUL = ~p & (op == 10);
assign DIV = ~p & (op == 11);
assign FAD = ~p & (op == 12);
assign FSB = ~p & (op == 13);
assign FML = ~p & (op == 14);
assign FDV = ~p & (op == 15);

assign LDR = p & ~q & ~u;
assign STR = p & ~q & u;
assign BR = p & q;

assign A = R[ira0];  // register data signals
assign B = R[irb];
assign C0 = R[irc];

// Arithmetic-logical unit (ALU)
assign ira0 = BR ? 15 : ira;
assign C1 = q ? {{16{v}}, imm} : C0;
assign adr = stallL ? B[23:0] + {4'b0, off} : {pcmux, 2'b00};
assign rd = LDR & ~stallX & ~stall1;
assign wr = STR & ~stallX & ~stall1;
assign ben = p & ~q & v & ~stallX & ~stall1;  // byte enable

assign sc0 = C1[1:0];
assign sc1 = C1[3:2];

// shifter for ASR and ROR
assign s1 = (sc0 == 3) ? {(w ? B[2:0] : {3{B[31]}}), B[31:3]} :
    (sc0 == 2) ? {(w ? B[1:0] : {2{B[31]}}), B[31:2]} :
    (sc0 == 1) ? {(w ? B[0] : B[31]), B[31:1]} : B;
assign s2 = (sc1 == 3) ? {(w ? s1[11:0] : {12{s1[31]}}), s1[31:12]} :
    (sc1 == 2) ? {(w ? s1[7:0] : {8{s1[31]}}), s1[31:8]} :
    (sc1 == 1) ? {(w ? s1[3:0] : {4{s1[31]}}), s1[31:4]} : s1;
assign s3 = C1[4] ? {(w ? s2[15:0] : {16{s2[31]}}), s2[31:16]} : s2;

// shifter for LSL
assign t1 = (sc0 == 3) ? {B[28:0], 3'b0} :
    (sc0 == 2) ? {B[29:0], 2'b0} :
    (sc0 == 1) ? {B[30:0], 1'b0} : B;
assign t2 = (sc1 == 3) ? {t1[19:0], 12'b0} :
    (sc1 == 2) ? {t1[23:0], 8'b0} :
    (sc1 == 1) ? {t1[27:0], 4'b0} : t1;
assign t3 = C1[4] ? {t2[15:0], 16'b0} : t2;

assign aluRes =
  MOV ? (q ?
    (~u ? {{16{v}}, imm} : {imm, 16'b0}) :
    (~u ? C0 : (~v ? H : {N, Z, C, OV, 20'b0, 8'h50}))) :
  LSL ? t3 :
  (ASR|ROR) ? s3 :
  AND ? B & C1 :
  ANN ? B & ~C1 :
  IOR  ? B | C1 :
  XOR ? B ^ C1 :
  ADD ? B + C1 + (u & C) :
  SUB ? B - C1 - (u & C) :
  MUL ? product[31:0] :
  DIV ? quotient :
 (FAD|FSB) ? fsum :
  FML ? fprod :
  FDV ? fquot :
  0;
  
assign regwr = ~p & ~stall | (LDR & ~stallX & ~stall1) | (BR & cond & v & ~stallX);
assign a0 = ~adr[1] & ~adr[0];
assign a1 = ~adr[1] & adr[0];
assign a2 = adr[1] & ~adr[0];
assign a3 = adr[1] & adr[0];
assign inbusL = (~ben | a0) ? inbus[7:0] :
  a1 ? inbus[15:8] : a2 ? inbus[23:16] : inbus[31:24];
assign inbusH = ~ben ? inbus[31:8] : 24'b0;
assign regmux = LDR ? {inbusH, inbusL} : (BR & v) ? {8'b0, nxpc, 2'b0} : aluRes;

assign outbusB0 = A[7:0];
assign outbusB1 = ben & a1 ? A[7:0] : A[15:8];
assign outbusB2 = ben & a2 ? A[7:0] : A[23:16];
assign outbusB3 = ben & a3 ? A[7:0] : A[31:24];
assign outbus = {outbusB3, outbusB2, outbusB1, outbusB0};

// Control unit CU
assign S = N ^ OV;
assign nxpc = PC + 1;
assign cond = ins[27] ^
  ((cc == 0) & N | // MI, PL
   (cc == 1) & Z | // EQ, NE
   (cc == 2) & C | // CS, CC
   (cc == 3) & OV | // VS, VC
   (cc == 4) & (C|Z) | // LS, HI
   (cc == 5) & S | // LT, GE
   (cc == 6) & (S|Z) | // LE, GT
   (cc == 7)); // T, F

assign pcmux = ~rst ? StartAdr :
  stall ? PC :
  (BR & cond & u) ? offL[21:0] + nxpc :
  (BR & cond & ~u) ? C0[23:2] : nxpc;
  
assign sa = aluRes[31];
assign sb = B[31];
assign sc = C1[31];

assign stall = stallL | stallM | stallD | stallX | stallFA | stallFM | stallFD;
assign stallL = (LDR|STR) & ~stall1;

always @ (posedge clk) begin
  PC <= pcmux;
  PMsel <= ~rst | (pcmux[21:12] == 10'h3FF);
  IR <= stall ? IR : codebus;
  stall1 <= stallX ? stall1 : stallL;
  R[ira0] <= regwr ? regmux : A;
  N <= regwr ? regmux[31] : N;
  Z <= regwr ? (regmux == 0) : Z;
  C <= ADD ? (~sb&sc&~sa) | (sb&sc&sa) | (sb&~sa) :
	 SUB ? (~sb&sc&~sa) | (sb&sc&sa) | (~sb&sa) : C;
  OV <= ADD ? (sa&~sb&~sc) | (~sa&sb&sc): 
	 SUB ? (sa&~sb&sc) | (~sa&sb&~sc) : OV;
  H <= MUL ? product[63:32] : DIV ? remainder : H;
end 
endmodule 
