// direct_mapped_cache_tb.sv

module direct_mapped_cache_tb;
    // Default parameters
    parameter CACHE_SIZE = 256;        // Default values; can be overridden
    parameter BLOCK_SIZE = 16;
    parameter ASSOC = 1;               // Direct Mapped
    parameter ADDR_WIDTH = 32;         // Bit-width of address
    parameter DATA_WIDTH = 32;         // Bit-width of data

    // Signal declarations
    logic clk;
    logic rst;
    logic [ADDR_WIDTH-1:0] address;
    logic read_enable;
    logic write_enable;
    logic [DATA_WIDTH-1:0] write_data;
    logic [DATA_WIDTH-1:0] read_data;
    logic hit;
    logic miss;
    
    // Statistics
    int total_accesses = 0;
    int total_hits = 0;
    int total_misses = 0;

    // Instantiate the direct mapped cache
    direct_mapped_cache #(
        .CACHE_SIZE(CACHE_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .ASSOC(ASSOC),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .address(address),
        .read_enable(read_enable),
        .write_enable(write_enable),
        .write_data(write_data),
        .read_data(read_data),
        .hit(hit),
        .miss(miss)
    );

    // Clock generation
    always #5 clk = ~clk;
    
    // Monitor hit/miss status
    always @(posedge clk) begin
        if (read_enable || write_enable) begin
            total_accesses++;
            if (hit) total_hits++;
            if (miss) total_misses++;
        end
    end

    initial begin
        // Initialize signals and dump waveform
        $dumpfile("direct_mapped_cache.vcd");
        $dumpvars(0, direct_mapped_cache_tb);
        
        clk = 0;
        rst = 1;
        write_enable = 0;
        read_enable = 0;
        address = 0;
        write_data = 0;
        
        #10 rst = 0; // Release reset after some time
        
        // Test 1: Sequential access pattern (good spatial locality)
        $display("Test 1: Sequential Access Pattern");
        for (int i = 0; i < 16; i++) begin
            // Write phase
            @(posedge clk);
            address = i * 16;  // Sequential addresses matching block size
            write_data = i + 100;
            write_enable = 1;
            read_enable = 0;
            @(posedge clk);
            write_enable = 0;
            
            // Read phase (should hit after first miss)
            @(posedge clk);
            read_enable = 1;
            @(posedge clk);
            read_enable = 0;
            
            $display("Address: %h, Write: %h, Read: %h, Hit: %b, Miss: %b", 
                    address, write_data, read_data, hit, miss);
        end
        
        // Test 2: Random access pattern (poor locality)
        $display("\nTest 2: Random Access Pattern");
        for (int i = 0; i < 16; i++) begin
            @(posedge clk);
            // Use a pseudo-random pattern
            address = ((i * 97) % 64) * 16;  // Create some conflicts
            write_data = i + 200;
            write_enable = 1;
            read_enable = 0;
            @(posedge clk);
            write_enable = 0;
            
            @(posedge clk);
            read_enable = 1;
            @(posedge clk);
            read_enable = 0;
            
            $display("Address: %h, Write: %h, Read: %h, Hit: %b, Miss: %b", 
                    address, write_data, read_data, hit, miss);
        end
        
        // Report statistics
        $display("\nCache Statistics:");
        $display("Total Accesses: %d", total_accesses);
        $display("Total Hits: %d (%.2f%%)", total_hits, 100.0*total_hits/total_accesses);
        $display("Total Misses: %d (%.2f%%)", total_misses, 100.0*total_misses/total_accesses);
        
        #50 $finish;
    end
endmodule