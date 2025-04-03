module immediate_generator_tb;
    logic [31:0] instr;
    logic [31:0] imm;
    
    immediate_generator uut (.instr(instr), .imm(imm));

    initial begin
        $dumpfile("gtkwave/immediate_generator.vcd");
        $dumpvars(0, immediate_generator_tb);
        
        $display("Starting Immediate Generator Test...");

        // Test I-type (ADDI)
        instr = 32'b00000000011101010000000110010011; // ADDI, imm = 7
        #10;
        $display("I-type ADDI: instr=%b, imm=%d", instr, imm);
        assert(imm == 7) else $error("Failed ADDI");

        // Test Load (LW)
        instr = 32'b00000000010001010010000010000011; // LW, imm = 4
        #10;
        $display("Load LW: instr=%b, imm=%d", instr, imm);
        assert(imm == 4) else $error("Failed LW");

        // Test Store (SW)
        instr = 32'b00000000000100101010010100100011; // SW, expected imm = 1
        #10;
        $display("Store SW: instr=%b, imm=%d", instr, imm);
        assert(imm == 1) else $error("Failed SW");

        // Test Branch (BEQ)
        instr = 32'b00000000000001010000001011100011; // BEQ, expected imm = 4
        #10;
        $display("Branch BEQ: instr=%b, imm=%d", instr, imm);
        assert(imm == 4) else $error("Failed BEQ");

        // Test Jump (JAL)
        instr = 32'b00000000000000000000000001101111; // JAL, expected imm = 104
        #10;
        $display("Jump JAL: instr=%b, imm=%d", instr, imm);
        assert(imm == 104) else $error("Failed JAL");

        $display("Immediate Generator Test Completed.");
        $finish;
    end
endmodule