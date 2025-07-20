
# MIPS32 RISC Processor with 5-Stage Pipeline

## Overview

This project implements a 32-bit MIPS32 RISC processor in Verilog with a **5-stage pipelined architecture**, capable of executing R-type and I-type instructions using a single unified memory for both instructions and data. The pipeline is designed to mimic real-world MIPS behavior and demonstrates fundamental concepts such as instruction execution, hazard handling, conditional branching, and memory interaction.

---

## Architecture Summary

### 🔧 Hardware Features

- **32-bit datapath** and instruction width
- **32 general-purpose registers**, each 32-bit wide
- **1024-word (4KB) memory**, unified for instructions and data
- **5-stage pipeline**:
  1. **IF (Instruction Fetch)**: Fetches instruction from memory using `PC`.
  2. **ID (Instruction Decode)**: Decodes opcode, registers, immediate; computes extended values.
  3. **EX (Execute)**: ALU operations, branch address computation, memory address calculation.
  4. **MEM (Memory Access)**: Load/store from memory.
  5. **WB (Write Back)**: Writes result back to register file.

- Two-phase clocking (`clk1`, `clk2`) prevents data races using rising edges at different stages.

---

## Instruction Set

### R-Type Instructions (Register-Register ALU):
| Mnemonic | Opcode    | Function |
|----------|-----------|----------|
| ADD      | `000000`  | `R[rd] = R[rs] + R[rt]` |
| SUB      | `000001`  | `R[rd] = R[rs] - R[rt]` |
| AND      | `000010`  | `R[rd] = R[rs] & R[rt]` |
| OR       | `000011`  | `R[rd] = R[rs] | R[rt]` |
| SLT      | `000100`  | `R[rd] = (R[rs] < R[rt])` |
| MUL      | `000101`  | `R[rd] = R[rs] * R[rt]` |
| HLT      | `111111`  | Halt execution |

### I-Type Instructions (Immediate and Memory):
| Mnemonic | Opcode    | Function |
|----------|-----------|----------|
| ADDI     | `001010`  | `R[rt] = R[rs] + Imm` |
| SUBI     | `001011`  | `R[rt] = R[rs] - Imm` |
| SLTI     | `001100`  | `R[rt] = (R[rs] < Imm)` |
| LW       | `001000`  | `R[rt] = Mem[R[rs] + Imm]` |
| SW       | `001001`  | `Mem[R[rs] + Imm] = R[rt]` |
| BEQZ     | `001110`  | Branch if zero |
| BNEQZ    | `001101`  | Branch if not zero |

---

## Pipeline Control

Each pipeline stage is synchronized via alternating clock edges (`clk1`, `clk2`) to allow concurrent execution without hazard issues. Branching is managed with flags like `BRANCH_TAKEN` and conditional checking in the EX stage.

Memory writes are blocked if a branch is taken, ensuring write-after-branch hazards are avoided.

---

## Design Modules

### `MIPS32_pipeline`

A monolithic module implementing:
- Instruction memory and decoding
- Register file
- ALU operations
- Hazard and control handling (basic)
- Load/store and branching logic

---

## Sample Programs

### 1️⃣ Add Three Numbers

This program demonstrates arithmetic and instruction sequencing in the pipeline.

```assembly
ADDI R1, R0, 10    ; R1 = 10
ADDI R2, R0, 20    ; R2 = 20
ADDI R3, R0, 25    ; R3 = 25
ADD  R4, R1, R2    ; R4 = 10 + 20 = 30
ADD  R5, R4, R3    ; R5 = 30 + 25 = 55
HLT
```

🧪 **Verification**: Registers R4 and R5 will hold intermediate and final results.

---

### 2️⃣ Factorial (e.g., 7!)

```assembly
ADDI R10, R0, 200      ; Address of input (Mem[200] = 7)
ADDI R2, R0, 1         ; Result initialized to 1
LW   R3, 0(R10)        ; Load n from Mem[200]
Loop:
MUL  R2, R2, R3        ; R2 = R2 * R3
SUBI R3, R3, 1         ; R3--
BNEQZ R3, Loop         ; Repeat until R3 == 0
SW   R2, -2(R10)       ; Store result in Mem[198]
HLT
```

🧪 **Verification**: Mem[198] should hold the factorial of 7 (5040).

---

### 3️⃣ Load/Store + Arithmetic

Demonstrates memory operations and accumulation.

```assembly
ADDI R1, R0, 120        ; R1 = address 120
LW   R2, 0(R1)          ; R2 = Mem[120] (85)
ADDI R2, R2, 45         ; R2 += 45 => 130
SW   R2, 1(R1)          ; Store result in Mem[121]
HLT
```

🧪 **Verification**: Final value in Mem[121] = 130.

---

## Waveform & Testing

All testbenches use a 2-phase clock system with `repeat` to simulate time and allow sequential execution.

Key features tested:
- Register updates
- Memory reads/writes
- Branching and looping
- Load/Store with immediate addressing

---

## Run Instructions

1. Load the modules and testbench files into your Verilog simulator (e.g., ModelSim, Icarus, Vivado).
2. Run the simulation using:
```verilog
vlog MIPS32_pipeline.v add_3_nos.v
vsim add_3_nos
run -all
```
3. Observe outputs via `$display()` or waveform viewers.

---

## Authors

Keshav Balakrishnan
LinkedIn- [https://www.linkedin.com/in/keshav-balakrishnan/]

This project was implemented as a part of learning computer architecture, CPU pipelining, and RTL-level simulation.

---

## License

MIT License
