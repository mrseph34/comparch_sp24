`timescale 1ps / 1ps

module instruction_decoder_tb;
    logic [31:0] instr;
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [31:0] imm;
    logic reg_write, mem_read, mem_write, branch;

    // Instantiate the decoder
    instruction_decoder uut (
        .instr(instr),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7),
        .imm(imm),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch)
    );

    // VCD dump for GTKWave
    initial begin
        $dumpfile("gtkwave/instruction_decoder.vcd");
        $dumpvars(0, instruction_decoder_tb);
    end

    // Test procedure
    initial begin
        $display("Starting Instruction Decoder Test...");

        // R-type ADD instruction (add x5, x10, x15)
        instr = 32'b00000001111001010000000110110011; // ADD x5, x10, x15
        #10;
        $display("R-type ADD: opcode=%b, rd=%d, rs1=%d, rs2=%d, funct3=%b, funct7=%b, reg_write=%b", opcode, rd, rs1, rs2, funct3, funct7, reg_write);

        // I-type ADDI instruction (addi x5, x10, 7)
        instr = 32'b00000000011101010000000110010011; // ADDI x5, x10, 7
        #10;
        $display("I-type ADDI: opcode=%b, rd=%d, rs1=%d, imm=%d, funct3=%b, reg_write=%b", opcode, rd, rs1, imm, funct3, reg_write);

        // Load LW instruction (lw x5, 4(x10))
        instr = 32'b00000000010001010010000010000011; // LW x5, 4(x10)
        #10;
        $display("Load LW: opcode=%b, rd=%d, rs1=%d, imm=%d, funct3=%b, mem_read=%b", opcode, rd, rs1, imm, funct3, mem_read);

        // Store SW instruction (sw x5, 1(x10))
        instr = 32'b00000000010101010010000010100011; // SW x5, 1(x10)
        #10;
        $display("Store SW: opcode=%b, rs1=%d, rs2=%d, imm=%d, funct3=%b, mem_write=%b", opcode, rs1, rs2, imm, funct3, mem_write);

        // Branch BEQ instruction (beq x10, x5, 4)
        instr = 32'b00000000010101010000000001100011; // BEQ x10, x5, 4
        #10;
        $display("Branch BEQ: opcode=%b, rs1=%d, rs2=%d, imm=%d, funct3=%b, branch=%b", opcode, rs1, rs2, imm, funct3, branch);

        // Jump JAL instruction (jal x5, 64)
        instr = 32'b00000001000000000000000110101111; // JAL x5, 64
        #10;
        $display("Jump JAL: opcode=%b, rd=%d, imm=%d, reg_write=%b", opcode, rd, imm, reg_write);

        $display("Instruction Decoder Test Completed.");
        $finish;
    end
endmodule