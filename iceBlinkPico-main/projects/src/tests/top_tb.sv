`timescale 1ns/1ps

module toptb;

    // Testbench signals
    logic clk, reset;
    logic [31:0] instr, mem_data;
    logic [31:0] mem_addr, write_data;
    logic mem_read, mem_write;

    // PC for tracking
    logic [31:0] pc;

    // Instantiate the design under test (DUT)
    top dut (
        .clk(clk),
        .reset(reset)
        // Do not connect register outputs here if not exposed from top
    );

    // Clock generation
    always #5 clk = ~clk;

    // Track PC from the CPU
    assign pc = dut.my_cpu.DP.pc; // Assuming dut.my_cpu exposes the datapath instance

    // Initialize test sequence
    initial begin
        clk = 0;
        reset = 1;
        
        // Initialize testbench signals
        #10 reset = 0; // Deassert reset

        // Run simulation for a specific number of cycles
        #1000; // Simulate for 1000 ns

        // Monitoring registers (assuming direct access to registers from the CPU)
        for (int i = 0; i < 32; i++) begin
            // Assuming registers are accessible via the cpu instance
            $display("Register %0d: %h", i, dut.my_cpu.DP.RF.registers[i]);
        end

        // Finish simulation
        $finish;
    end

    // Instruction and Memory Management Logs (similar to cpu_tb) can be included as well...

endmodule