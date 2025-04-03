`timescale 1ns / 1ps

module control_unit_tb;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic reg_write, alu_src, mem_to_reg, mem_read, mem_write, branch;
    logic [3:0] alu_op;

    // Instantiate Control Unit
    control_unit CU (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .alu_op(alu_op)
    );

    initial begin
        $dumpfile("gtkwave/control_unit.vcd");
        $dumpvars(0, control_unit_tb);

        // R-Type (ADD)
        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0000000;
        #10;
        $display("R-Type ADD -> reg_write:%b, alu_src:%b, alu_op:%b", reg_write, alu_src, alu_op);

        // I-Type (ADDI)
        opcode = 7'b0010011; funct3 = 3'b000;
        #10;
        $display("I-Type ADDI -> reg_write:%b, alu_src:%b, alu_op:%b", reg_write, alu_src, alu_op);

        // Load (LW)
        opcode = 7'b0000011;
        #10;
        $display("Load LW -> reg_write:%b, alu_src:%b, mem_to_reg:%b, mem_read:%b", reg_write, alu_src, mem_to_reg, mem_read);

        // Store (SW)
        opcode = 7'b0100011;
        #10;
        $display("Store SW -> alu_src:%b, mem_write:%b", alu_src, mem_write);

        // Branch (BEQ)
        opcode = 7'b1100011;
        #10;
        $display("Branch BEQ -> branch:%b, alu_op:%b", branch, alu_op);

        $finish;
    end

endmodule