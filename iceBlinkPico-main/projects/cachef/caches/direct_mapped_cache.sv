// direct_mapped_cache.sv

module direct_mapped_cache #(
    parameter CACHE_SIZE = 256, // Total cache size in bytes
    parameter BLOCK_SIZE = 16,   // Cache block size in bytes
    parameter ASSOC = 1          // Associativity (1 for direct-mapped)
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

    localparam NUM_SETS = CACHE_SIZE / (BLOCK_SIZE * ASSOC);
    localparam BLOCK_OFFSET_WIDTH = $clog2(BLOCK_SIZE);
    localparam INDEX_WIDTH = $clog2(NUM_SETS);
    localparam TAG_WIDTH = 32 - INDEX_WIDTH - BLOCK_OFFSET_WIDTH;

    logic [7:0] cache_data [NUM_SETS-1:0][BLOCK_SIZE-1:0];
    logic [TAG_WIDTH-1:0] cache_tag [NUM_SETS-1:0];
    logic valid [NUM_SETS-1:0];

    logic [TAG_WIDTH-1:0] tag;
    logic [INDEX_WIDTH-1:0] index;
    logic [BLOCK_OFFSET_WIDTH-1:0] block_offset;

    always_comb begin
        tag = addr[31 : 32 - TAG_WIDTH];
        index = addr[32 - TAG_WIDTH - 1 : BLOCK_OFFSET_WIDTH];
        block_offset = addr[BLOCK_OFFSET_WIDTH-1 : 0];
    end

    logic current_hit;
    logic current_miss;
    logic [7:0] current_rd_data;

    always_comb begin
        current_hit = (valid[index] && (cache_tag[index] == tag));
        current_miss = ~current_hit;

        if (current_hit && !wr_en) 
            current_rd_data = cache_data[index][block_offset];
        else 
            current_rd_data = 8'b0; // Default data on miss/write
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < NUM_SETS; i++) 
                valid[i] <= 0;

            hit <= 0;
            miss <= 0;
            rd_data <= 8'b0;
        end else begin
            hit <= current_hit;
            miss <= current_miss;
            rd_data <= current_rd_data;

            if (current_miss || wr_en) begin
                valid[index] <= 1;
                cache_tag[index] <= tag;

                if (wr_en) 
                    cache_data[index][block_offset] <= wr_data;
            end
        end
    end

endmodule