`timescale 1ns/1ps

module register_file_tb;
    logic clk;
    logic reg_write;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] write_data;
    logic [31:0] read_data1, read_data2;

    // Instantiate Register File
    register_file uut (
        .clk(clk),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("gtkwave/register_file.vcd");
        $dumpvars(0, register_file_tb);

        clk = 0; reg_write = 0; rd = 0; write_data = 0;
        
        // Write values to registers
        #10 reg_write = 1; rd = 5; write_data = 10;
        #10 reg_write = 1; rd = 10; write_data = 20;
        #10 reg_write = 1; rd = 15; write_data = 30;

        // Read back values
        #10 reg_write = 0; rs1 = 5; rs2 = 10;
        #10 $display("Read x5: %d, Read x10: %d", read_data1, read_data2);

        // Check another read
        #10 rs1 = 15; rs2 = 0;
        #10 $display("Read x15: %d, Read x0 (should be 0): %d", read_data1, read_data2);

        $finish;
    end
endmodule