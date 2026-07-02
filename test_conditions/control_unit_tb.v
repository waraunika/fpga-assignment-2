`timescale 1ns / 1ps
module control_unit_tb ();

  reg CLK;
  wire [7:0] PC;
  wire [7:0] inst;
  wire [2:0] READREG1, READREG2, WRITEREG;
  wire WRITEENABLE, MUX1_SEL, MUX2_SEL;
  wire [7:0] IMMEDIATE, stack_value, stack_pointer;
  wire [2:0] ALUOP;

  control_unit cu (
    .inst              (inst),
    .CLK               (CLK),
    .carry_in          (carry_in),
    .zero_in           (zero_in),
    .READREG1          (READREG1),
    .READREG2          (READREG2),
    .WRITEREG          (WRITEREG),
    .WRITEENABLE       (WRITEENABLE),
    .MUX1_SEL          (MUX1_SEL),
    .MUX2_SEL          (MUX2_SEL),
    .DMUX_SEL          (DMUX_SEL),
    .carry_flag        (carry_flag),
    .carry_use         (carry_use),
    .zero_flag         (zero_flag),
    .WRITE_STACK_ENABLE(WRITE_STACK_ENABLE),
    .IMMEDIATE         (IMMEDIATE),
    .PC                (PC),
    .stack_value       (stack_value),
    .stack_pointer     (stack_pointer),
    .ALUOP             (ALUOP)
  );

  inst_memory mem (
    .PC                (PC),
    .CLK               (CLK),
    .WRITE_STACK_ENABLE(WRITE_STACK_ENABLE),
    .stack_value       (stack_value),
    .stack_pointer     (stack_pointer),
    .inst              (inst)
  );

  always #5 CLK = ~CLK;

  initial begin
    $dumpfile("control_unit.vcd");
    $dumpvars(0, cu);
    $dumpvars(1, mem);

    CLK = 0;
    #120;
    $finish;
  end
endmodule
