module factorial;
    reg clk1,clk2;
    integer k;

    MIPS32_pipeline mips(clk1,clk2);

    initial begin
        clk1=0;clk2=0;
        repeat(20) begin //two phase clock
            #5 clk1=1; #5 clk1=0;
            #5 clk2=1; #5 clk2=0;
        end
    end
    
    initial begin
        for (k=0;k<32;k=k+1) mips.regfile[k] = k; //initializing regfile
        //eg: reg[7]=7
        mips.Mem[0]= 32'h280a00c8; //ADDI R10,R0,200
        mips.Mem[1]= 32'h28020001; //ADDI R2,R0,1
        mips.Mem[2]= 32'h0ce77800; //dummy instr 
        mips.Mem[3]= 32'h21430000; //LW R3,0(R10)
        mips.Mem[4]= 32'h0ce77800; //dummy instr
        mips.Mem[5]= 32'h14431000; //MUL R2,R2,R3
        mips.Mem[6]= 32'h0ce77800;
        mips.Mem[7]= 32'h0ce77800; //dummy instr
        mips.Mem[8]= 32'h2c630001; //SUBI R3,R3,1
        mips.Mem[9]= 32'h0ce77800; //dummy instr
        mips.Mem[10]= 32'h3460fffa; //BNEQZ R3,-6 (loop)
        mips.Mem[11]= 32'h2542fffe; //SW R2,-2(R10)
        mips.Mem[12]= 32'hfc000000; //HLT

        mips.Mem[200]=7; //finding factorial of 7

        mips.BRANCH_TAKEN=0;
        mips.HALTED=0;
        mips.PC=0; //to start execution from 0 memory address

        #2000;
        $display ("Mem[200]=%d | Mem[198]=%d",mips.Mem[200],mips.Mem[198]);
        #200 $finish;
    end

    initial begin
  $monitor("PC=%d R2=%d R3=%d", mips.PC, mips.regfile[2], mips.regfile[3]);
end

endmodule



