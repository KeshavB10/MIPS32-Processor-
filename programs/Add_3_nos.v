module add_3_nos;
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
        mips.Mem[0]= 32'h2801000a; 
        mips.Mem[1]= 32'h28020014; 
        mips.Mem[2]= 32'h28030019; 
        mips.Mem[3]= 32'h0ce77800; //dummy instr
        mips.Mem[4]= 32'h0ce77800; //dummy instr
        mips.Mem[5]= 32'h00222000; 
        mips.Mem[6]= 32'h0ce77800; 
        mips.Mem[7]= 32'h00832800; 
        mips.Mem[8]= 32'hfc000000; 

        mips.BRANCH_TAKEN=0;
        mips.HALTED=0;
        mips.PC=0; //to start execution from 0 memory address

        #400;

        for (k=0;k<10; k=k+1) begin
            $display (" Register R%1d= %2d", k, mips.regfile[k]);
        end
        #200 $finish;
    end
endmodule



