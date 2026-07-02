# Modules Developed So far:
**Only the Control Unit will be presented in this repo, as per the assignment demands**
all of the device take `CLK` as clock
## Instruction Memory
  - takes PC
  - outputs `inst` as instruction byte
  - takes `CLK` for synchronization, if needed for stack operations
  - `stack_value` is input to store into stack
  - `stack_pointer` is the address at which to store the `stack_value`
  - `WRITE_STACK_ENABLE` enables when the stack should be able to have values written into it.

## Control Unit
  - initializes
	  - `PC` as `00H`
	  - `immediate_flag` as 0
	  - `WRITEENABLE` as 0
	  - `carry_flag`, `zero_flag` as 0
	  - `carry_use` as 0
	  - `DMUX_SEL` as 0
	  - `jmp_enable`, `call_enable` as 0
	  - `stack_pointer` as `FFH`
	  - `WRITE_STACK_POINTER` as 0
  - explanation of all signals, and their use:
	  - `inst` -> instruction byte, fetched from `inst_memory` module with PC as address to the registers.
	  - CLK -> clock
	  - `carry_in` to take carry/borrow generated from ALU and decide what to do with it
	  - `zero_in` to take zero flag generated from ALU and decide what to do with it
	  - `READREG1/2` to read from register file
	  - `WRITEREG` to write into a register from register file
	  - `WRITEENABLE` to enable writing into `WRITEREG` destination
	  - `MUX1/2/3_SEL` to select for operand logic.
		  - `MUX1`: 0 for selecting `READREG2`, 1 for its 2's complement
		  - `MUX2`: 0 for selecting output of `MUX1` and 1 for immediate data byte
		  - `MUX3`: 0 to select between `ALU`'s output and direct register transfer from `READREG1`
	  - flags:
		  - `carry_flag`, `zero_flag`: as the name suggests, internal state for carry and zero flags
		  - `immediate_flag`: to get the operand from `inst_memory` or not
		  - `jmp_enable`, `call_enable`: flags to control how PC and stack should get its new corresponding values, if needed.
	  - `carry_use`: a flag for ALU to use or not use carry in its operation. like for ADC, we enable this flag.
	  - `WRITE_STACK_ENABLE`: a flag to write into stack
		  - here, stack starts from FFH of `inst_memory`, with decrementing address meaning pushing higher into the stack
	  - `IMMEDIATE`: databyte obtained from `inst_memory` used as immediate operand
	  - `PC`: program counter
	  - `stack_value`: the value to push into the stack
	  - `stack_pointer`: stores the value of stack pointer.
	  - `state`: 2 bit state machine with their parameters
		  - 00 (FETCH): fetch instruction
		  - 01 (DECODE): decode instruction and generate appropriate flags
		  - 10 (EXECUTE): execute signal, and set flags based on ALU output
		  - 11 (FETCH_OPERAND): additional state when we need to fetch immediate operands. state machine flow would be: 00 -> 01 -> 11 -> 10
  - other implementation details:
	  - `branch_logic` task:
		  - takes a flag as input
		  - `AND`s with inst\[0\] to get the actual usage of flag
		  - based on that and inst\[3\], it will either jump or call
		  - op code for branching are like:
		  - `1111 abcd`
		  - if `1111 0000`-> unconditional jump, if `1111 1000` then unconditional call
		  - a: 0 for jumping, 1 for calling
		  - bc: 01 for using zero flag, 10 for using call flag
		  - d: 0 for using with flag LOW as enabling branch, 1 for using with flag HIGH
	- `return_logic` task:
		- takes a flag as input
		- has the exact same logic as `branch_logic`'s call logic
		- op code's first 5 bits are `10100`
## 8x8 Register File
  - 8 registers each of 8 bit.
  - takes input signals: READREG1 and 2, WRITEREG, WRITEENABLE, and ALURESULT
  - selects register properly
  - sends output signal REGOUT1 and 2.
  - i'll use 6 as general purpose reg
  - 2 as special register
	  - reg\[6\] is used to store `01H` for increment decrement operations
	  - reg\[7\] is not currently used, but will be used for XCHG operations and other operations when a temporary register is needed.
## 2's Comp
  - no need for clock
  - takes REGOUT1 and 2's complements it.

## MUX1
  - based on select line `MUX3_SEL`, chooses `REGOUT1` or ~REGOUT2 from 2's Comp block
  - no need for clock
  - output as REGOUT2_mux_1

## MUX2
  - based on select line `MUX_SEL`, choose between REGOUT2_mux_1 and IMMEDIATE\[7:0\]
  - output as OPERAND2\[7:0\]
  - no need for clock
## MUX3
- based on select line `MUX_SEL`, choose between `REGOUT1` and `ALURESULT` to write into register file
## ALU
  - 8 types of alu operation, sent by control unit, in `ALUOP`\[2:0\]
  - produce output and send result in `ALURESULT`\[7:0\]
  - have output `carry_out` and `zero_out` flags for CU to process 
  - have input `carry_flag` and `carry_use` for appropriate usage of carry flag.
  - input is `OPERAND2` from `MUX2`, and `OPERAND1` as `REGOUT1`.
  - instructions are:
	  - 000: AND
	  - 001: OR
	  - 010: XOR
	  - 011: NOR
	  - 100: ADD
	  - 101: SBB
	  - 110: RL
	  - 111: RR

# Instruction Set:
If bitwise classifications of the opcodes (in hex/binary), then head to: [CPU ISA](https://docs.google.com/spreadsheets/d/1HAe2VzfGsogN4_n9ZDZejeOMXLIFRrK1n7Pcw1E7xAo/edit?usp=sharing)

Total of 115 instructions done. 2 forms of instructions left to utilize: XCHG (will give `5*6/2 = 15` instructions) and PUSH/POP instructions (will give 2 instructions)

implemented instructions: logical: 31, arithmetic: 28, data transfer: 36 and branch: 15
implemented: 110
future works: 17
total instructions: 127
## Logical
  1. AND A, A: `00 000 000`: 00H
  2. AND A, B: `00 000 001`: 01H
  3. AND A, C: `00 000 010`: 02H
  4. AND A, D: `00 000 011`: 03H
  5. AND A, E: `00 000 100`: 04H
  6. AND A, F: `00 000 101`: 05H
  7. AND A, DB: `00 000 110`: 06H

8. OR A, A: `01 000 000`: 40H
9. OR A, B: `01 000 001`: 41H
10. OR A, C: `01 000 010`: 42H
11. OR A, D: `01 000 011`: 43H
12. OR A, E: `01 000 100`: 44H
13. OR A, F: `01 000 101`: 45H
14. OR A, DB: `01 000 110`: hhH

15. XOR A, A: `10 000 000`: 80H
16. XOR A, B: `10 000 001`: 81H
17. XOR A, C: `10 000 010`: 82H
18. XOR A, D: `10 000 011`: 83H
19. XOR A, E: `10 000 100`: 84H
20. XOR A, F: `10 000 101`: 85H
21. XOR A, DB: `10 000 110`: 86H

22. NOR A, A: `11 000 110`: C6H
23. NOR A, B: `11 000 111`: C7H
24. NOR A, C: `11 001 110`: CEH
25. NOR A, D: `11 001 111`: CFH
26. NOR A, E: `11 010 110`: D6H
27. NOR A, F: `11 010 111`: D7H

### Logical/Rotate
28. ROL: `00 101 110`: 2EH
29. ROR: `00 101 111`: 2FH

30. RLC: `00 111 110`: 3EH
31. RRC: `00 111 111`: 3FH

## Arithmetic
1. ADD A, A: `00 001 000`: 08H
2. ADD A, B: `00 001 001`: 09H
3. ADD A, C: `00 001 010`: 0AH
4. ADD A, D: `00 001 011`: 0BH
5. ADD A, E: `00 001 100`: 0CH
6. ADD A, F: `00 001 101`: 0DH
7. ADD A, DB: `00 001 110`: 0EH
8. ADC A, B: `00 001 111`: 0FH

9. SUB A, A: `00 011 000`: 18H
10. SUB A, B: `00 011 001`: 19H
11. SUB A, C: `00 011 010`: 1AH
12. SUB A, D: `00 011 011`: 1BH
13. SUB A, E: `00 011 100`: 1CH
14. SUB A, F: `00 011 101`: 1DH
15. SUB A, DB: `00 011 110`: 1EH
16. SBB A, B: `00 011 111`: 1FH

17. INC A: `00 101 000`: 28H
18. INC B: `00 101 001`: 29H
19. INC C: `00 101 010`: 2AH
20. INC D: `00 101 011`: 2BH
21. INC E: `00 101 100`: 2CH
22. INC F: `00 101 101`: 2DH

23. DEC A: `00 111 000`: 38H
24. DEC B: `00 111 001`: 39H
25. DEC C: `00 111 010`: 3AH
26. DEC D: `00 111 011`: 3BH
27. DEC E: `00 111 100`: 3CH
28. DEC F: `00 111 101`: 3DH

## Data Transfer
1. MOV A, DB: `11 000 000`: C0H
2. MOV A, B: `11 000 001`: C1H
3. MOV A, C: `11 000 010`: C2H
4. MOV A, D: `11 000 011`: C3H
5. MOV A, E: `11 000 100`: C4H
6. MOV A, F: `11 000 101`: C5H

7. MOV B, A: `11 001 000`: C8H
8. MOV B, DB: `11 001 001`: C9H
9. MOV B, C: `11 001 010`: CAH
10. MOV B, D: `11 001 011`: CBH
11. MOV B, E: `11 001 100`: CCH
12. MOV B, F: `11 001 101`: CDH
l
13. MOV C, A: `11 010 000`: D0H
14. MOV C, B: `11 010 001`: D1H
15. MOV C, DB: `11 010 010`: D2H
16. MOV C, D: `11 010 011`: D3H
17. MOV C, E: `11 010 100`: D4H
18. MOV C, F: `11 010 101`: D5H

19. MOV D, A: `11 011 000`: D8H
20. MOV D, B: `11 011 001`: D9H
21. MOV D, C: `11 011 010`: DAH
22. MOV D, DB: `11 011 011`: DBH
23. MOV D, E: `11 011 100`: DCH
24. MOV D, F: `11 011 101`: DDH

25. MOV E, A: `11 100 000`: E0H
26. MOV E, B: `11 100 001`: E1H
27. MOV E, C: `11 100 010`: E2H
28. MOV E, D: `11 100 011`: E3H
29. MOV E, DB: `11 100 100`: E4H
30. MOV E, F: `11 100 101`: E5H

31. MOV F, A: `11 101 000`: E8H
32. MOV F, B: `11 101 001`: E9H
33. MOV F, C: `11 101 010`: EAH
34. MOV F, D: `11 101 011`: EBH
35. MOV F, E: `11 101 100`: ECH
36. MOV F, F: `11 101 101`: EDH

## Branch Instructions
1. JMP DB: `11110 000`: F0H
2. JNZ DB: `11110 010`: F4H
3. JZ DB: `11110 011`: F3H
4. JNC DB: `11110 100`: F2H
5. JC DB: `11110 101`: F1H

6. CALL DB: `11111 000`: F8H
7. CNZ DB: `11111 010`: FCH
8. CZ DB: `11111 011`: FBH
9. CNC DB: `11111 100`: FAH
10. CC DB: `11111 101`: F9H

11. RET: `00010 000`: A0H
12. RTNZ: `00010 010`: A2H
13. RTZ: `00010 011`: A3H
14. RTNC: `00010 100`: A4H
15. RTC: `00010 101`: A5H