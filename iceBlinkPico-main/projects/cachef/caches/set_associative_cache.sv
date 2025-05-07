// set_associative_cache.sv

module set_associative_cache #(
    parameter CACHE_SIZE = 256, // Total cache size in bytes
    parameter BLOCK_SIZE = 16,  // Cache block size in bytes
    parameter ASSOC = 4,        // Associativity (ways per set)
    parameter NUM_SETS = CACHE_SIZE / (BLOCK_SIZE * ASSOC) // Number of sets
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
    localparam BLOCK_OFFSET_WIDTH = $clog2(BLOCK_SIZE);
    localparam INDEX_WIDTH = $clog2(NUM_SETS);
    localparam TAG_WIDTH = 32 - INDEX_WIDTH - BLOCK_OFFSET_WIDTH;

    // Cache memory and state
    logic [7:0] cache_data [NUM_SETS-1:0][ASSOC-1:0][BLOCK_SIZE-1:0]; // [set][way][offset]
    logic [TAG_WIDTH-1:0] cache_tag [NUM_SETS-1:0][ASSOC-1:0];       // [set][way]
    logic valid [NUM_SETS-1:0][ASSOC-1:0];                           // [set][way]

    // Replacement policy state (Simple FIFO per set)
    logic [$clog2(ASSOC)-1:0] replace_ptr [NUM_SETS-1:0]; // Points to the way to be replaced next for each set

    // Address decomposition
    logic [TAG_WIDTH-1:0] tag;
    logic [INDEX_WIDTH-1:0] index;
    logic [BLOCK_OFFSET_WIDTH-1:0] block_offset;

    // Combinational logic for address decomposition
    always_comb begin
        tag = addr[31 : INDEX_WIDTH + BLOCK_OFFSET_WIDTH];
        index = addr[INDEX_WIDTH + BLOCK_OFFSET_WIDTH - 1 : BLOCK_OFFSET_WIDTH];
        block_offset = addr[BLOCK_OFFSET_WIDTH-1 : 0];
    end

    // Combinational logic for hit detection and read data
    logic current_hit;
    logic current_miss;
    logic [7:0] current_rd_data;
    logic [$clog2(ASSOC)-1:0] hit_way; // Which way had the hit

    always_comb begin
        current_hit = 0; // Assume miss initially
        hit_way = '0;    // Default hit way

        // Check all ways in the selected set for a hit
        for (int i = 0; i < ASSOC; i++) begin
            if (valid[index][i] && (cache_tag[index][i] == tag)) begin
                current_hit = 1;
                hit_way = i; // Found the hit way
            end
        end

        current_miss = ~current_hit;

        // Determine read data
        if (current_hit && !wr_en)
            current_rd_data = cache_data[index][hit_way][block_offset];
        else
            current_rd_data = 8'b0; // Default data on miss or write
    end

    // Sequential logic for state updates
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize valid bits, replacement pointers, and outputs
            for (int s = 0; s < NUM_SETS; s++) begin
                for (int i = 0; i < ASSOC; i++) begin
                    valid[s][i] <= 0;
                end
                replace_ptr[s] <= '0;
            end
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
                    // Write hit: Update data in the hit way of the selected set
                    cache_data[index][hit_way][block_offset] <= wr_data;
                end else begin
                    // Write miss: Replace block at replace_ptr in the selected set
                    valid[index][replace_ptr[index]] <= 1;
                    cache_tag[index][replace_ptr[index]] <= tag;
                    cache_data[index][replace_ptr[index]][block_offset] <= wr_data;
                    // Update replacement pointer for this set (FIFO)
                    replace_ptr[index] <= (replace_ptr[index] == ASSOC - 1) ? '0 : replace_ptr[index] + 1;
                end
            end else if (current_miss) begin // Read miss (and not writing)
                // Read miss: Replace block at replace_ptr in the selected set
                valid[index][replace_ptr[index]] <= 1;
                cache_tag[index][replace_ptr[index]] <= tag;
                // Data is NOT updated on a read miss in this simple model.
                // Update replacement pointer for this set (FIFO)
                replace_ptr[index] <= (replace_ptr[index] == ASSOC - 1) ? '0 : replace_ptr[index] + 1;
            end
            // Read hit: No state change needed for simple FIFO
        end
    end

endmodule