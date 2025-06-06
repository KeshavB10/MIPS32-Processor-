module load_store_from_mem;
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
        mips.Mem[0]= 32'h28010078; 
        mips.Mem[1]= 32'h0c631800; //dummy instr
        mips.Mem[2]= 32'h20220000; 
        mips.Mem[3]= 32'h0c631800; //dummy instr
        mips.Mem[4]= 32'h2842002d; 
        mips.Mem[5]= 32'h0c631800; //dummy instr
        mips.Mem[6]= 32'h24220001; 
        mips.Mem[7]= 32'hfc000000; 

        mips.Mem[120]=85; //here output should be 85+45=130

        mips.BRANCH_TAKEN=0;
        mips.HALTED=0;
        mips.PC=0; //to start execution from 0 memory address

        #400;
        $display ("Mem[120]=%4d | Mem[121]=%4d",mips.Mem[120],mips.Mem[121]);
        #200 $finish;
    end
endmodule



