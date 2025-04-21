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

        // Test ADD with negative numbers
        a = -10; b = 20; alu_op = 4'b0000;
        #10;
        $display("ADD (signed): %d + %d = %d, Zero: %b", $signed(a), $signed(b), $signed(result), zero);

        // Test SUB (0x1)
        a = 30; b = 20; alu_op = 4'b0001;
        #10;
        $display("SUB: %d - %d = %d, Zero: %b", a, b, result, zero);

        // Test SUB with negative result
        a = 20; b = 30; alu_op = 4'b0001;
        #10;
        $display("SUB (negative result): %d - %d = %d, Zero: %b", a, b, $signed(result), zero);

        // Test SUB resulting in zero
        a = 20; b = 20; alu_op = 4'b0001;
        #10;
        $display("SUB (zero result): %d - %d = %d, Zero: %b", a, b, result, zero);

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

        // Test SLT (0x5) - Signed Set Less Than
        a = 10; b = 20; alu_op = 4'b0101;
        #10;
        $display("SLT (signed): %d < %d = %d", $signed(a), $signed(b), result);

        // Test SLT with negative numbers
        a = -10; b = 5; alu_op = 4'b0101;
        #10;
        $display("SLT (signed negative): %d < %d = %d", $signed(a), $signed(b), result);

        // Test SLT where unsigned comparison would give different result
        a = 32'hFFFFFFFF; b = 1; alu_op = 4'b0101;
        #10;
        $display("SLT (signed vs unsigned): %d < %d = %d, but %d < %d = %d (unsigned)", 
                 $signed(a), $signed(b), result, a, b, (a < b ? 1 : 0));

        // Test SLTU (0x8) - Unsigned Set Less Than (if implemented)
        a = 10; b = 20; alu_op = 4'b1000;
        #10;
        $display("SLTU (unsigned): %d < %d = %d", a, b, result);

        // Test SLTU with value that's negative in signed context
        a = 32'hFFFFFFFF; b = 1; alu_op = 4'b1000;
        #10;
        $display("SLTU (unsigned with 0xFFFFFFFF): %d < %d = %d", a, b, result);

        // Test Left Shift (0x6)
        a = 8; b = 2; alu_op = 4'b0110;
        #10;
        $display("SLL: %d << %d = %d", a, b, result);

        // Test Left Shift with sign bit
        a = 32'h40000000; b = 1; alu_op = 4'b0110;
        #10;
        $display("SLL (affecting sign): 0x%h << %d = 0x%h (signed: %d)", 
                a, b, result, $signed(result));

        // Test Logical Right Shift (0x7)
        a = 32; b = 2; alu_op = 4'b0111;
        #10;
        $display("SRL: %d >> %d = %d", a, b, result);

        // Test Logical Right Shift with negative number
        a = 32'h80000000; b = 4; alu_op = 4'b0111;
        #10;
        $display("SRL (with MSB set): 0x%h >> %d = 0x%h", a, b, result);

        // Test Arithmetic Right Shift (0x9) - if implemented
        a = 32'h80000000; b = 4; alu_op = 4'b1001;
        #10;
        $display("SRA (with MSB set): 0x%h >>> %d = 0x%h", a, b, result);

        // Test Arithmetic Right Shift with positive number
        a = 32; b = 2; alu_op = 4'b1001;
        #10;
        $display("SRA (positive): %d >>> %d = %d", a, b, result);

        // Test operations with maximum and minimum 32-bit values
        a = 32'h7FFFFFFF; b = 1; alu_op = 4'b0000;  // ADD - will overflow signed
        #10;
        $display("ADD (max signed): %d + %d = %d (unsigned: %d)", 
                 $signed(a), $signed(b), $signed(result), result);

        a = 32'h80000000; b = 32'h80000000; alu_op = 4'b0001;  // SUB - will underflow
        #10;
        $display("SUB (min signed): %d - %d = %d (unsigned: %d)", 
                 $signed(a), $signed(b), $signed(result), result);

        $finish;
    end
endmodule