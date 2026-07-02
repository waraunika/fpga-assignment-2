`timescale 1ns / 1ps
module cpu;


  reg        CLK                            ;
  wire [7:0] PC                             ;
  wire [7:0] inst                           ;
  wire [2:0] READREG1, READREG2, WRITEREG   ;
  wire [2:0] REGOUT1, REGOUt2, COMP_OUT     ;
  wire       WRITEENABLE, MUX1_SEL, MUX2_SEL;
  wire       MUX1_OUT, OPERAND1, OPERAND2   ;
  wire [7:0] IMMEDIATE, ALURESULT           ;
  wire [2:0] ALUOP                          ;

  control_unit cu (
      .inst(inst),
      .CLK (CLK),
      .READREG1(READREG1),
      .READREG2(READREG2),
      .WRITEREG(WRITEREG),
      .WRITEENABLE(WRITEENABLE),
      .MUX1_SEL(MUX1_SEL),
      .MUX2_SEL(MUX2_SEL),
      .IMMEDIATE(IMMEDIATE),
      .PC(PC),
      .ALUOP(ALUOP)
  );

  inst_memory mem (
      .PC(PC),
      .CLK(CLK),
      .inst(inst)
  );

  register_file register_file (
    .CLK        (CLK),
    .READREG1   (READREG1),
    .READREG2   (READREG2),
    .WRITEREG   (WRITEREG),
    .WRITEENABLE(WRITEENABLE),
    .WRITEDATA  (ALURESULT),
    .REGOUT1    (REGOUT1),
    .REGOUT2    (REGOUT2)
  );

  twos_comp twos_comp (
    .x(REGOUT2),
    .y(COMP_OUT)
  );

  mux_2x1 m1 (
    .x(REGOUT2),
    .y(COMP_OUT),
    .s(MUX1_SEL),
    .z(MUX1_OUT)
  );

  mux_2x1 m2 (
    .x(MUX1_OUT),
    .y(IMMEDIATE),
    .s(MUX2_SEL),
    .z(OPERAND1)
  );

  always #5 CLK = ~CLK;

  initial begin
    $dumpfile("cpu.vcd");
    $dumpvars(0, cu);

    CLK = 0;
    #100;
    $finish;
  end
endmodule
