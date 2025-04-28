// direct_mapped_cache.sv

module direct_mapped_cache #(
    parameter CACHE_SIZE = 256,        // Total size of the cache in bytes
    parameter BLOCK_SIZE = 16,         // Size of each cache block in bytes
    parameter ASSOC = 1,               // Level of associativity (1 for direct-mapped)
    parameter ADDR_WIDTH = 32,         // Bit-width of the address
    parameter DATA_WIDTH = 32          // Bit-width of data in each cache line
) (
    input logic clk,
    input logic rst,
    input logic [ADDR_WIDTH-1:0] address,
    input logic read_enable,
    input logic write_enable,
    input logic [DATA_WIDTH-1:0] write_data,
    output logic [DATA_WIDTH-1:0] read_data,
    output logic hit,
    output logic miss
);

    // Number of cache lines
    localparam NUM_LINES = CACHE_SIZE / BLOCK_SIZE;
    
    // Calculate address breakdowns
    localparam INDEX_BITS = $clog2(NUM_LINES);
    localparam OFFSET_BITS = $clog2(BLOCK_SIZE);
    localparam TAG_BITS = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;
    
    // Cache storage - separate arrays instead of structs
    logic [NUM_LINES-1:0] valid;
    logic [TAG_BITS-1:0] tags [NUM_LINES-1:0];
    logic [DATA_WIDTH-1:0] data [NUM_LINES-1:0]; // Simplified to one word per line for now
    
    // Address components
    logic [TAG_BITS-1:0] tag;
    logic [INDEX_BITS-1:0] index;
    logic [OFFSET_BITS-1:0] offset;
    
    // Extract address fields
    always_comb begin
        offset = address[OFFSET_BITS-1:0];
        index = address[INDEX_BITS+OFFSET_BITS-1:OFFSET_BITS];
        tag = address[ADDR_WIDTH-1:INDEX_BITS+OFFSET_BITS];
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all cache entries
            for (int i = 0; i < NUM_LINES; i++) begin
                valid[i] <= 0;
                tags[i] <= 0;
                data[i] <= 0;
            end
            hit <= 0;
            miss <= 0;
            read_data <= 0;
        end else begin
            // Default values
            hit <= 0;
            miss <= 0;
            
            if (read_enable) begin
                // Read operation
                if (valid[index] && (tags[index] == tag)) begin
                    hit <= 1;
                    read_data <= data[index];
                end else begin
                    miss <= 1;
                    // On a real system, we'd fetch from memory here
                    // For simulation, we'll just indicate the miss
                end
            end else if (write_enable) begin
                // Write operation (write-through policy)
                if (valid[index] && (tags[index] == tag)) begin
                    hit <= 1;
                end else begin
                    miss <= 1;
                    valid[index] <= 1;
                    tags[index] <= tag;
                end
                // Write data to cache regardless (write-allocate)
                data[index] <= write_data;
            end
        end
    end
endmodule