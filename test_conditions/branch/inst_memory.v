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
    mem[0] = 8'hF0; // JMP 22H
    mem[1] = 8'h22; // 22H = 34
    mem[34] = 8'hFB; // CZ 12H
    mem[35] = 8'h12; // 12H
    mem[18] = 8'hA0; // RET
  end

  always @(posedge CLK) begin
    if (WRITE_STACK_ENABLE) begin
      mem[stack_pointer] = stack_value;
    end
  end

  assign inst = mem[PC];
endmodule
