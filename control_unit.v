// refer to cpu_architecture.md for more info.
// it will simply not be possible to include everything here
module control_unit (
  input      [7:0] inst              ,
  input            CLK               ,
                   carry_in          ,
                   zero_in           ,
  output reg [2:0] READREG1          ,
                   READREG2          ,
                   WRITEREG          ,
  output reg       WRITEENABLE       ,
                   MUX1_SEL          ,
                   MUX2_SEL          ,
                   MUX3_SEL          ,
                   carry_flag        ,
                   carry_use         ,
                   zero_flag         ,
                   WRITE_STACK_ENABLE,
  output reg [7:0] IMMEDIATE         ,
                   PC                ,
                   stack_value       ,
                   stack_pointer     ,
  output reg [2:0] ALUOP
  );


  // All instructions are present at cpu_architecture.md
  // I've also made a google sheet to keep track of what instruction
  // is mapped to which hex code.

  reg [1:0] state                                  ;
  reg       immediate_flag, jmp_enable, call_enable;

  parameter FETCH           = 2'b00;
  parameter DECODE          = 2'b01;
  parameter EXECUTE         = 2'b10;
  parameter FETCH_IMMEDIATE = 2'b11;

  initial begin
    state              = FETCH;
    PC                 = 8'h00;
    immediate_flag     = 1'b0 ;
    WRITEENABLE        = 1'b0 ;
    carry_flag         = 1'b0 ;
    carry_use          = 1'b0 ;
    zero_flag          = 1'b0 ;
    MUX1_SEL           = 1'b0 ;
    MUX2_SEL           = 1'b0 ;
    MUX3_SEL           = 1'b0 ;
    jmp_enable         = 1'b0 ;
    call_enable        = 1'b0 ;
    stack_pointer      = 8'hFF;
    WRITE_STACK_ENABLE = 1'b0 ;
  end

  // helper function for branching instructions
  task branch_logic (input flag);
    begin
      if (flag && inst[0]) begin
        state          <= FETCH_IMMEDIATE;
        PC             <= PC + 1;
        immediate_flag <= 1'b1;

        if (inst[3]) begin
          call_enable    <= 1'b1;
        end else begin
          jmp_enable     <= 1'b1;
        end
      end
      else begin
        state          <= FETCH;
        PC             <= PC + 2;
      end
    end
  endtask

  // helper function for return instructions
  task return_logic (input flag);
    begin
      state <= FETCH;

      if (flag && inst[0]) begin
        PC            <= stack_pointer;
        stack_pointer <= stack_pointer + 1;
      end else begin
        PC            <= PC + 1;
      end
    end
  endtask

  // 3 states: 1 for fetching instruction
  // 2nd for decoding and sending proper control signals.
  // since mux's and alu are combinational, they won't need additional
  // cycle.
  // and we can get the output of alu, store it in register bank,
  // and simultaneously fetch next instruction as well.

  always @(posedge CLK) begin
    case (state)
      FETCH: begin
        // PC is set from previous cycle
        // inst is present already
        state              <= DECODE;
        WRITEENABLE        <= 1'b0  ;
        MUX3_SEL           <= 1'b0  ;
        WRITE_STACK_ENABLE <= 1'b0  ;

        // no operation op codes
        if (
        (inst == 8'h07 || inst == 8'h47 || inst == 8'h87)
        || (inst == 8'h11 || inst == 8'h16 || inst == 8'h17)
        || (inst[7:3] == 5'b00100)
        || (inst[7:3] == 5'b00110)
        || (inst[7:3] == 5'b01001)
        || (inst[7:4]== 4'b0101)
        || (inst[7:5] == 3'b011)
        || (inst[7:3] == 5'b10001)
        || (inst[7:4] == 4'b1001)
        || (inst == 8'hA1 || inst == 8'hA6 || inst == 8'hA7 || inst[7:3] == 5'b10101)
        || (inst[7:4] == 4'b1011)
        || (inst == 8'hDE || inst == 8'hDF || inst == 8'hE6 || inst == 8'hE7 || inst == 8'hEE || inst == 8'hEF)
        || (inst == 8'hF1 || inst == 8'hF6 || inst == 8'hF7)
        || (inst == 8'hF9 || inst == 8'hFE || inst == 8'hFF)
        ) begin
          state   <= FETCH;
          PC      <= PC+1;
        end
      end

      DECODE: begin
        // need to set all control signals.
        // register file reads combinationally

        // if we need an additional databyte for immediate instructions, go to fetch immediate state.

        // JMP/CALL instruction at F0-F5H and F8-FDH, simple take the next byte in inst_memory and go there.
        // in the form of 1111 0xxx for jmp, 1xxx for call
        if (inst[7:4] == 4'hF) begin
          // simple JMP (F0H) or CALL (F8H)
          if (inst[2:0] == 3'b000) begin
            state          <= FETCH_IMMEDIATE;
            immediate_flag <= 1'b1;
            PC             <= PC + 1;

            if (inst[3] == 0) begin
              jmp_enable     <= 1'b1;
            end else begin
              call_enable    <= 1'b1;
            end
          end

          // JNZ or JZ at F2/3H or CZ or CNZ aat FAH FBH
          else if (inst[2:1] == 2'b01) begin
            branch_logic(zero_flag);
          end

          // JNC or JC at F4/F5H or CNC or CC at FC/FDH
          else if (inst[2:1] == 2'b10) begin
            branch_logic(carry_flag);
          end
        end

        // return instructions, all at address 1010 0xxxH
        else if (inst[7:3] == 5'b10100) begin
          // unconditional return
          if (inst[2:0] === 3'b000) begin
            state         <= FETCH;
            PC            <= stack_pointer;
            stack_pointer <= stack_pointer + 1;
          end else if (inst[2:1] == 2'b01) begin
            return_logic(carry_flag);
          end else if (inst[2:1] == 2'b10) begin
            return_logic(zero_flag);
          end
        end

        // logical operations: AND OR NOR condition: 00/01/10 000 xxx
        else if (inst[7:6] != 2'b11 && inst[5:3] == 3'b000) begin
          READREG1 <= 3'b000;
          WRITEREG <= 3'b000;
          // op code will be like 000 for AND, 001 for OR, 010 for XOR
          ALUOP <= {1'b0, inst[7:6]};
          MUX1_SEL <= 1'b0;
          if (inst[2:1] == 2'b11) begin
            MUX2_SEL       <= 1'b1;
            immediate_flag <= 1'b1;
            PC             <= PC + 1;
            state          <= FETCH_IMMEDIATE;
          end else begin
            MUX2_SEL       <= 1'b0;
            READREG2 <= inst[2:0];
            state          <= EXECUTE;
          end
        end

        // logical operations: NOR: complex conditions from op codes
        // (C6/7 H, CE/F H) and (D6/7 H)
        // two conditions: (11 00x 11x) and (1101011x) respectively
        else if ((inst[7:4] == 4'hC && inst[2:1] == 2'b11) || inst[7:1] == 7'b1101011) begin
          READREG1 <= 3'b000;

          // reg 2 logic:
          // bit 4, 3, 0 decide the register
          // example: NOR A, C = CE H = 1100 1110
          // bit 4 3 0: 010 -> C register
          READREG2 <= {inst[4:3], inst[0]};
          MUX1_SEL <= 1'b0  ;
          MUX2_SEL <= 1'b0  ;
          WRITEREG <= 3'b000;

          ALUOP <= 3'b011 ;
          state <= EXECUTE;
        end

        // rotate operations
        // 2E -> ROL, 2F -> ROR (no carry usage in both)
        // 3E -> RLC, 3F -> RRC (carry usage in both)
        // we can treat ROL, RLC as same ALU instruction with carry usage differing
        // we can treat ROR, RRC as same ALU instruction with carry usage differing
        else if (inst[7:5] == 3'b001 && inst[3:1] == 3'b111) begin
          READREG1 <= 3'b000;
          WRITEREG <= 3'b000;
          // if ROL/RLC, 110 to rotate left, ROR/RRC: 111 to rotate right
          ALUOP <= (inst[0] == 1'b0) ? 3'b110 : 3'b111;
          // if ROL/ROR no carry usage, if RLC/RRC use carry
          carry_use <= (inst[4] == 1'b0) ? 1'b0: 1'b1;
          state    <= EXECUTE;
          MUX1_SEL <= 1'b0   ;
          MUX2_SEL <= 1'b0   ;
        end

        // arithmetic operation condition: 00 xx1 xxx
        else if (inst[7:6] == 2'b00 && inst[3] == 1'b1) begin
          carry_use <= 1'b0  ;
          WRITEREG  <= 3'b000;
          MUX2_SEL  <= 1'b0  ;

          // if subtracting or decreasing, then we'd want its 2's complement.
          MUX1_SEL <= (inst[4] == 1'b1) ? 1'b1 : 1'b0;

          // readreg1 will be A, unless for increment/decrement
          // if inc/dec then we'd have to have respective regsiter
          READREG1 <= (inst[5] == 1'b1) ? inst[2:0] : 3'b000;

          // reg 2 logic: if add, sub normal logic
          // if incrementing, decrementing,
          // we use special registr at reg[6] that has default value of 01.
          // if ADC or SBB, then we need only B
          READREG2 <= 
          (inst[5] == 1'b1)
          ? 3'b110
          : (inst[2:0] == 3'b111) ? 3'b001 :inst[2:0];

          // op code will be like 100 for adding/subtracting, 101 for SBB
          ALUOP <= (inst == 8'h1F) ? 3'b101 : 3'b100;

          state <= EXECUTE;

          // if add a, db (00 001 110) or sub a, db (00 011 110) instructions,
          // we need to load immediate value
          if (inst[5:4] == 2'b00 || inst[5:4] == 2'b01) begin
            if (inst[2:0] == 3'b110) begin
              MUX2_SEL       <= 1'b1;
              immediate_flag <= 1'b1;
              PC             <= PC + 1;
              state          <= FETCH_IMMEDIATE;
            end else if (inst[2:0] == 3'b111) begin
              // if adc a, b (00 001 111) or sbb a, b (00 011 111) instructions
              // we need to enable carry use flag
              carry_use      <= 1'b1;
            end
          end
        end

        // data transfer operation: 11 xxx xxx
        else if (inst[7:6] == 2'b11) begin
          READREG1 <= inst[2:0];
          MUX3_SEL <= 1'b1;
          WRITEREG <= inst[5:3];
          ALUOP <= 3'bxxx;

          state <= EXECUTE;

          if (inst[5:3] == inst[2:0]) begin
            immediate_flag <= 1'b1;
            MUX2_SEL       <= 1'b1;
            PC             <= PC + 1;
            state          <= FETCH_IMMEDIATE;
          end
        end
      end

      FETCH_IMMEDIATE: begin
        IMMEDIATE      <= inst   ;
        immediate_flag <= 1'b0   ;
        MUX3_SEL       <= 1'b0   ;
        state          <= EXECUTE;
      end

      EXECUTE: begin
        // need to write output back to register file, and update PC
        // to fetch new instruction
        WRITEENABLE <= 1'b1  ;
        PC <= (jmp_enable || call_enable) ? IMMEDIATE : PC + 1;
        WRITE_STACK_ENABLE <= jmp_enable;
        if (call_enable) begin
          stack_value   <= PC + 1;
          stack_pointer <= stack_pointer - 1;
        end

        jmp_enable  <= 1'b0  ;
        call_enable <= 1'b0  ;
        state       <= FETCH ;
        zero_flag <= 
        ( (inst[7:6] == 2'b00 && inst[3] == 1'b1) && !(inst == 8'h2E || inst == 8'h2F || inst == 8'h3E || inst == 8'h3F) )
          ? zero_in
          : zero_flag;
        carry_flag <= 
        (inst[7:3] == 5'b00011)
        ? !carry_in
        : (ALUOP == 3'b100 || ALUOP == 3'b110 || ALUOP == 3'b111)
        ? carry_in
        : carry_flag;
      end

      default: begin
        state <= FETCH;
      end
    endcase
  end

endmodule
