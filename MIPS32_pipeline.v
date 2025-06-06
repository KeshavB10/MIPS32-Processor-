//MIPS32 32 Bit Processor, with 32 32-bit Register-Bank, 1K (or 1024) 32-bit word addressable Memory containing data as well as instruction memory
//Each instruction is 32 bit encoded
//5 stage pipeline with IF- Instruction Fetch || ID- Instruction Decode/ Register Prefetch || EX- Execute/ Memory Address and conditon calculation ||
//MEM- Memory write / Loading of data from memory || WB- Write back to register file


module MIPS32_pipeline(clk1,clk2); 
    input clk1,clk2; //only two input clocks required to utilize two phase clock to prevent mixing of data when using only one clock
    reg [31:0] PC,IF_ID_IR,IF_ID_NPC;
    reg [31:0] ID_EX_IR,ID_EX_NPC,ID_EX_A,ID_EX_B,ID_EX_Imm;
    reg [31:0] ID_EX_type,EX_MEM_type,MEM_WB_type;  //used to store the type of instruction after decoding
    reg [31:0] EX_MEM_IR,EX_MEM_ALUout,EX_MEM_B;
    
    reg EX_MEM_cond; //one bit register to store condition for branching

    reg [31:0] MEM_WB_IR, MEM_WB_ALUout, MEM_WB_LMD;

    reg [31:0] regfile [0:31]; //32 32-bit register file
    reg [31:0] Mem [0:1023]; //1024 32-bit addressable memory locations

    parameter ADD=6'b000_000, SUB=6'b000_001, AND=6'b000_010, OR=6'b000_011, SLT=6'b000_100, MUL=6'b000_101, HLT=6'b111_111; // R-type instructions
    parameter LW=6'b001_000, SW=6'b001_001, ADDI=6'b001_010, SUBI=6'b001_011, SLTI=6'b001_100, BNEQZ=6'b001_101, BEQZ=6'b001_110; //I-Type instructions

    reg HALTED; //=1 if HLT instruction detected and that stage's WB is excecuted ONLY

    reg BRANCH_TAKEN; //=1  if Branch detected at ID and EX stage's cond condition is true, =0 at EX stage

    parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011, BRANCH=3'b100, HALT=3'b101; //to store type of instruction

    always @(posedge clk1) begin    //IF STAGE
        if (HALTED==0) begin
            if ((EX_MEM_IR[31:26]==BEQZ && EX_MEM_cond==1) || (EX_MEM_IR[31:26]==BNEQZ && EX_MEM_cond==0)) begin
                IF_ID_IR <= Mem [EX_MEM_ALUout];
                PC<= EX_MEM_ALUout;
                IF_ID_NPC<=PC+1;
                BRANCH_TAKEN<=1;
            end
            else begin
                IF_ID_IR<=Mem[PC];
                PC<=PC+1;
                IF_ID_NPC<=PC+1;
            end
        end
    end

    always @(posedge clk2) begin    //ID STAGE
        if (HALTED==0) begin
            if (IF_ID_IR[25:21]==5'b00000) ID_EX_A<=0; //if rs==R0, then by default the value will be 0
            else ID_EX_A<= regfile[IF_ID_IR[25:21]];

            if (IF_ID_IR[20:16]==5'b00000) ID_EX_B<=0; //if rt==R0, then by default the value will be 0
            else ID_EX_B<= regfile[IF_ID_IR[20:16]];

            ID_EX_Imm<= {{16{IF_ID_IR[15]}},IF_ID_IR[15:0]}; //16 bit sign extension of immediate value
            ID_EX_IR<=IF_ID_IR;
            ID_EX_NPC<=IF_ID_NPC;

            case (IF_ID_IR[31:26])
                ADD,SUB,AND,OR,SLT,MUL: ID_EX_type<= RR_ALU;
                ADDI,SUBI,SLTI: ID_EX_type<=RM_ALU;
                LW: ID_EX_type<= LOAD;
                SW: ID_EX_type<= STORE;
                BEQZ,BNEQZ: ID_EX_type<=BRANCH;
                HLT: ID_EX_type<= HALT; 
                default: ID_EX_type<=HALT; //this means it is an invalid opcode so execution must stop there itself
            endcase
        end
    end

    always @(posedge clk1) begin    //EX STAGE
        if (HALTED==0) begin
            EX_MEM_type<= ID_EX_type;
            BRANCH_TAKEN<=0;
            EX_MEM_IR<=ID_EX_IR;

            case (ID_EX_type)
                RR_ALU: begin 
                    case (ID_EX_IR[31:26]) //checking opcode
                        ADD: EX_MEM_ALUout <= ID_EX_A + ID_EX_B;
                        SUB: EX_MEM_ALUout <= ID_EX_A - ID_EX_B;
                        AND: EX_MEM_ALUout <= ID_EX_A & ID_EX_B;
                        OR:  EX_MEM_ALUout <= ID_EX_A | ID_EX_B;
                        SLT: EX_MEM_ALUout <= ID_EX_A < ID_EX_B;
                        MUL: EX_MEM_ALUout <= ID_EX_A * ID_EX_B; 
                        default: EX_MEM_ALUout <= 32'hxxxxxxxx;
                    endcase
                end

                RM_ALU: begin
                    case (ID_EX_IR[31:26])
                        ADDI: EX_MEM_ALUout <= ID_EX_A + ID_EX_Imm;
                        SUBI: EX_MEM_ALUout <= ID_EX_A - ID_EX_Imm;
                        SLTI: EX_MEM_ALUout <= ID_EX_A < ID_EX_Imm;
                        default: EX_MEM_ALUout <= 32'hxxxxxxxx;
                    endcase
                end

                LOAD,STORE: begin 
                    EX_MEM_ALUout <= ID_EX_A + ID_EX_Imm;
                    EX_MEM_B <= ID_EX_B;
                end

                BRANCH: begin
                    EX_MEM_ALUout <= ID_EX_NPC + ID_EX_Imm;
                    EX_MEM_cond <= (ID_EX_A ==0);
                end
            endcase
        end
    end

    always @(posedge clk2) begin    //MEM STAGE
        if (HALTED==0) begin
            MEM_WB_type <= EX_MEM_type;
            MEM_WB_IR <= EX_MEM_IR;
            case (EX_MEM_type)
                RR_ALU,RM_ALU: MEM_WB_ALUout <= EX_MEM_ALUout;
                LOAD: MEM_WB_LMD <= Mem[EX_MEM_ALUout];
                STORE: if (BRANCH_TAKEN==0) Mem[EX_MEM_ALUout] <= EX_MEM_B; //write is disabled if branch was taken (no writing allowed to avoid HAZARDs when branching)
            endcase
        end
    end

    always @(posedge clk1) begin    //WB STAGE
        begin
            if (BRANCH_TAKEN==0) begin //disable all "write to memory "if BRANCH is taken
                case (MEM_WB_type)
                    RR_ALU: if (MEM_WB_IR[15:11]!= 5'b00000) regfile[MEM_WB_IR[15:11]] <= MEM_WB_ALUout; //Reg and Reg ALU, so  destination is rd which is [15:11]
                    RM_ALU: if (MEM_WB_IR[20:16]!= 5'b00000) regfile[MEM_WB_IR[20:16]] <= MEM_WB_ALUout; //Reg and Memory ALU, so destination is rt which is [20:16]
                    LOAD:   if (MEM_WB_IR[20:16]!= 5'b00000) regfile[MEM_WB_IR[20:16]] <= MEM_WB_LMD;    //for load operations, destination is rt, but we have to load value from memory  
                    HALT:   HALTED <=1; //halt detected and done only after instruction cycle's WB stage is complete
                endcase
            end
        end
    end
endmodule





