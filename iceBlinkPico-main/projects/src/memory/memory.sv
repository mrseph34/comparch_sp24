// memory.sv - Auto-generated file

module memory (
    input logic clk, mem_read, mem_write,
    input logic [31:0] addr, write_data,
    output logic [31:0] read_data
);
    logic [31:0] mem [0:255]; // 256-word memory

    initial begin
        $readmemh("/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/projects/src/memory/mem_init.hex", mem);
    end

    always_ff @(posedge clk) begin
        if (mem_write)
            mem[addr >> 2] <= write_data; // Write data on rising edge
    end

    assign read_data = (mem_read) ? mem[addr >> 2] : 32'bx; // Read data
endmodule