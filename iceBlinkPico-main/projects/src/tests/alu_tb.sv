`timescale 1ns/1ps

module alu_tb;
    logic [31:0] a, b;
    logic [3:0] alu_op;
    logic [31:0] result;
    logic zero;

    // Instantiate ALU
    alu uut (
        .a(a), 
        .b(b), 
        .alu_op(alu_op), 
        .result(result), 
        .zero(zero)
    );

    initial begin
        $dumpfile("gtkwave/alu.vcd");
        $dumpvars(0, alu_tb);

        // Test ADD (0x0)
        a = 10; b = 20; alu_op = 4'b0000;
        #10;
        $display("ADD: %d + %d = %d, Zero: %b", a, b, result, zero);

        // Test SUB (0x1)
        a = 30; b = 20; alu_op = 4'b0001;
        #10;
        $display("SUB: %d - %d = %d, Zero: %b", a, b, result, zero);

        // Test AND (0x2)
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = 4'b0010;
        #10;
        $display("AND: %h & %h = %h", a, b, result);

        // Test OR (0x3)
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = 4'b0011;
        #10;
        $display("OR: %h | %h = %h", a, b, result);

        // Test XOR (0x4)
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = 4'b0100;
        #10;
        $display("XOR: %h ^ %h = %h", a, b, result);

        // Test SLT (0x5) - Set Less Than
        a = 10; b = 20; alu_op = 4'b0101;
        #10;
        $display("SLT: %d < %d = %d", a, b, result);

        // Test Left Shift (0x6)
        a = 8; b = 2; alu_op = 4'b0110;
        #10;
        $display("SLL: %d << %d = %d", a, b, result);

        // Test Right Shift (0x7)
        a = 32; b = 2; alu_op = 4'b0111;
        #10;
        $display("SRL: %d >> %d = %d", a, b, result);

        $finish;
    end
endmodule