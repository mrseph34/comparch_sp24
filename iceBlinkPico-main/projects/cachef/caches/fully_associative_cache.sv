// fully_associative_cache.sv

module fully_associative_cache #(
    parameter CACHE_SIZE = 256, // Total cache size in bytes
    parameter BLOCK_SIZE = 16,  // Cache block size in bytes
    // For fully associative, ASSOC is the number of cache lines (ways)
    parameter ASSOC = CACHE_SIZE / BLOCK_SIZE
)(
    input logic clk,
    input logic reset,
    input logic [31:0] addr,
    input logic [7:0] wr_data,
    input logic wr_en,
    output logic [7:0] rd_data,
    output logic hit,
    output logic miss
);

    // Local parameters
    localparam NUM_SETS = 1; // Fully associative has only 1 set
    localparam BLOCK_OFFSET_WIDTH = $clog2(BLOCK_SIZE);
    localparam INDEX_WIDTH = 0; // No index bits for fully associative
    localparam TAG_WIDTH = 32 - BLOCK_OFFSET_WIDTH; // Tag is the rest of the address

    // Cache memory and state
    logic [7:0] cache_data [ASSOC-1:0][BLOCK_SIZE-1:0]; // [way][offset]
    logic [TAG_WIDTH-1:0] cache_tag [ASSOC-1:0];       // [way]
    logic valid [ASSOC-1:0];                           // [way]

    // Replacement policy state (Simple FIFO)
    logic [$clog2(ASSOC)-1:0] replace_ptr; // Points to the way to be replaced next

    // Address decomposition
    logic [TAG_WIDTH-1:0] tag;
    // logic [INDEX_WIDTH-1:0] index; // Not used in fully associative
    logic [BLOCK_OFFSET_WIDTH-1:0] block_offset;

    // Combinational logic for address decomposition
    always_comb begin
        tag = addr[31 : BLOCK_OFFSET_WIDTH];
        // index = 0; // Index is always 0
        block_offset = addr[BLOCK_OFFSET_WIDTH-1 : 0];
    end

    // Combinational logic for hit detection and read data
    logic current_hit;
    logic current_miss;
    logic [7:0] current_rd_data;
    logic [$clog2(ASSOC)-1:0] hit_way; // Which way had the hit

    always_comb begin
        current_hit = 0; // Assume miss initially
        hit_way = '0;     // Default hit way

        // Check all ways for a hit
        for (int i = 0; i < ASSOC; i++) begin
            if (valid[i] && (cache_tag[i] == tag)) begin
                current_hit = 1;
                hit_way = i; // Found the hit way
            end
        end

        current_miss = ~current_hit;

        // Determine read data
        if (current_hit && !wr_en)
            // Read data from the hit way at the specific offset
            current_rd_data = cache_data[hit_way][block_offset];
        else
            current_rd_data = 8'b0; // Default data on miss or write
    end

    // Sequential logic for state updates
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize valid bits, replacement pointer, and outputs
            for (int i = 0; i < ASSOC; i++)
                valid[i] <= 0;
            replace_ptr <= '0;
            hit <= 0;
            miss <= 0;
            rd_data <= 8'b0;
        end else begin
            // Update outputs based on current cycle's hit/miss
            hit <= current_hit;
            miss <= current_miss;
            rd_data <= current_rd_data;

            // Handle cache updates on miss or write
            if (wr_en) begin // Write operation (hit or miss)
                if (current_hit) begin
                    // Write hit: Update data in the hit way
                    cache_data[hit_way][block_offset] <= wr_data;
                    // For FIFO, write hit doesn't change replacement order
                end else begin
                    // Write miss: Replace block at replace_ptr
                    valid[replace_ptr] <= 1;
                    cache_tag[replace_ptr] <= tag;
                    cache_data[replace_ptr][block_offset] <= wr_data;
                    // Update replacement pointer (FIFO)
                    replace_ptr <= (replace_ptr == ASSOC - 1) ? '0 : replace_ptr + 1;
                end
            end else if (current_miss) begin // Read miss (and not writing)
                 // Read miss: Replace block at replace_ptr
                 // In a real system, this would prob involve fetching the block
                 valid[replace_ptr] <= 1;
                 cache_tag[replace_ptr] <= tag;
                 // Data is NOT updated on a read miss in this simple model.
                 // Update replacement pointer (FIFO)
                 replace_ptr <= (replace_ptr == ASSOC - 1) ? '0 : replace_ptr + 1;
            end
            // Read hit: No state change needed for simple FIFO
        end
    end

endmodule
