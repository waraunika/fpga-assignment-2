`timescale 1ns / 1ps
module inst_memory_tb;

  reg [7:0] PC;
  reg CLK;
  wire [7:0] inst;

  inst_memory uut (
      PC,
      CLK,
      inst
  );

  // assuming 10 ns clock cycle,
  // so, each 5 ns, the clock is complementing
  always #5 CLK = ~CLK;

  initial begin
    $dumpfile("inst_memory.vcd");
    $dumpvars(0, uut);

    CLK = 0;
    PC  = 8'd0;
    #10;
    PC = 8'd1;
    #10;
    $finish;
  end

endmodule
