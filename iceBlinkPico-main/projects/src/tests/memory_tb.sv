`timescale 1ns / 1ps

module memory_tb;
    logic clk;
    logic mem_read, mem_write;
    logic [31:0] addr, write_data;
    logic [31:0] read_data;

    // Instantiate the memory module
    memory dut (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("gtkwave/memory.vcd");
        $dumpvars(0, memory_tb);

        // Initialize signals
        clk = 0;
        mem_read = 0;
        mem_write = 0;
        addr = 0;
        write_data = 0;

        // Wait for memory to initialize
        #10;
        $display("Checking memory initialization...");
        mem_read = 1;
        addr = 0;
        #10;
        $display("Memory[0]: %h", read_data);

        // Write test
        $display("Writing to memory...");
        mem_read = 0;
        mem_write = 1;
        addr = 4;
        write_data = 32'hDEADBEEF;
        #10;
        mem_write = 0;

        // Read back written value
        $display("Reading back from memory...");
        mem_read = 1;
        addr = 4;
        #10;
        $display("Memory[4]: %h", read_data);

        // End simulation
        $finish;
    end
endmodule