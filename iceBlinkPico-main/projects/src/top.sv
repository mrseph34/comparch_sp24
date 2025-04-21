// top.sv
`include "./cpu.sv"
`include "./memory/memory.sv"

module top (
    input logic clk,
    input logic reset,
    output logic [31:0] registers_outputs [0:31] // Expose all registers
);

    // Internal signals
    logic [31:0] instr;           // Instruction fetched from memory
    logic [31:0] mem_data;        // Data read from memory
    logic [31:0] mem_addr;        // Address for memory read/write
    logic [31:0] write_data;      // Data to write to memory
    logic mem_read, mem_write;    // Control signals for memory

    // Instantiate the memory
    memory my_memory (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(mem_addr),
        .write_data(write_data),
        .read_data(mem_data)       // Output from memory to the CPU
    );

    // Instantiate the CPU
    cpu my_cpu (
        .clk(clk),
        .reset(reset),
        .instr(instr),              // Instruction input to CPU
        .mem_data(mem_data),        // Data read from memory
        .mem_addr(mem_addr),        // Address to which CPU writes/reads
        .write_data(write_data),    // Data to be written to memory
        .mem_read(mem_read),        // Control signal for memory read
        .mem_write(mem_write),      // Control signal for memory write
        .reg_data_out(registers_outputs) 
    );

    // Instruction fetch logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            instr <= 32'b0;         // Reset instruction to zero
        end else begin
            instr <= mem_data;      // Read instruction directly from memory output
        end
    end

endmodule