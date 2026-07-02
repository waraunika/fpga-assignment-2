module inst_memory (
    input [7:0] PC,
    input CLK,
    input reg WRITE_STACK_ENABLE,
    input reg [7:0] stack_value,
    input reg [7:0] stack_pointer,
    output [7:0] inst
);

  reg [7:0] mem[0:255];

  initial begin
    mem[0] = 8'hC0; // MOV A, DB
    mem[1] = 8'h23; // DB
    mem[2] = 8'hD8; // MOV D, A
    mem[3] = 8'hE1; // MOV E, B
    mem[4] = 8'hDB; // MOV D, DB
    mem[5] = 8'h45; // DB
  end

  always @(posedge CLK) begin
    if (WRITE_STACK_ENABLE) begin
      mem[stack_pointer] = stack_value;
    end
  end

  assign inst = mem[PC];
endmodule
