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
    mem[0] = 8'h2E; // ROL
    mem[1] = 8'h2F; // ROR
    mem[2] = 8'h3E; // RLC
    mem[3] = 8'h3F; // RRC
  end

  always @(posedge CLK) begin
    if (WRITE_STACK_ENABLE) begin
      mem[stack_pointer] = stack_value;
    end
  end

  assign inst = mem[PC];
endmodule
