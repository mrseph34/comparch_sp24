// direct_mapped_cache_tb.sv

module direct_mapped_cache_tb;

    parameter CACHE_SIZE = 256;
    parameter BLOCK_SIZE = 16; // Block size set for tests
    parameter ASSOC = 1; // Direct-mapped

    localparam PERIOD = 10; // Clock period in ns
    localparam NUM_SETS = CACHE_SIZE / (BLOCK_SIZE * ASSOC);
    localparam BLOCK_OFFSET_WIDTH = $clog2(BLOCK_SIZE);
    localparam INDEX_WIDTH = $clog2(NUM_SETS);
    localparam TAG_WIDTH = 32 - INDEX_WIDTH - BLOCK_OFFSET_WIDTH;

    logic clk;
    logic reset;
    logic [31:0] addr;
    logic [7:0] wr_data;
    logic wr_en;
    logic [7:0] rd_data;
    logic hit;
    logic miss;

     // Initial block to display parameters
    initial begin
        $display("Simulation Parameters:");
        $display("CACHE_SIZE = %0d", CACHE_SIZE);
        $display("BLOCK_SIZE = %0d", BLOCK_SIZE);
        $display("ASSOC = %0d", ASSOC);
        $display("NUM_SETS = %0d", NUM_SETS);
        $display("BLOCK_OFFSET_WIDTH = %0d", BLOCK_OFFSET_WIDTH);
        $display("INDEX_WIDTH = %0d", INDEX_WIDTH);
        $display("TAG_WIDTH = %0d", TAG_WIDTH);
    end

    // Instantiate the Cache Module
    direct_mapped_cache #(
        .CACHE_SIZE(CACHE_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .ASSOC(ASSOC)
    ) dut (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .wr_data(wr_data),
        .wr_en(wr_en),
        .rd_data(rd_data),
        .hit(hit),
        .miss(miss)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(PERIOD/2) clk = ~clk;
    end

    // Metrics Counters
    integer total_accesses = 0;
    integer read_hits = 0;
    integer read_misses = 0;
    integer write_hits = 0;
    integer write_misses = 0;

    // Temporary counters for each test
    integer test_read_hits;
    integer test_read_misses;
    integer test_write_hits;
    integer test_write_misses;

    // Read operation task
    task read_access(input [31:0] read_addr);
        begin
            addr = read_addr;
            wr_en = 0;
            total_accesses++;
            #(PERIOD);
            if (hit) begin
                test_read_hits++;
                read_hits++;
            end else begin
                test_read_misses++;
                read_misses++;
            end
            #(PERIOD);
        end
    endtask

    // Write operation task
    task write_access(input [31:0] write_addr, input [7:0] data_to_write);
        begin
            addr = write_addr;
            wr_data = data_to_write;
            wr_en = 1;
            total_accesses++;
            #(PERIOD);
            if (miss) begin
                test_write_misses++;
                write_misses++;
            end else begin
                test_write_hits++;
                write_hits++;
            end
            #(PERIOD);
        end
    endtask

    // Function to display test results
    task display_test_results();
        $display("Test Results: Read Hits: %0d, Read Misses: %0d, Write Hits: %0d, Write Misses: %0d", 
            test_read_hits, test_read_misses, test_write_hits, test_write_misses);
        
        // Reset temporary counters for the next test
        test_read_hits = 0;
        test_read_misses = 0;
        test_write_hits = 0;
        test_write_misses = 0;
    endtask

    initial begin
        // Reset the cache
        $display("--- Resetting Cache ---");
        reset = 1;
        wr_en = 0;
        addr = 32'b0;
        wr_data = 8'b0;
        #(PERIOD * 5); // Hold reset
        reset = 0;
        #(PERIOD);

        // Initialize temporary counters
        test_read_hits = 0;
        test_read_misses = 0;
        test_write_hits = 0;
        test_write_misses = 0;

        // Basic Test Cases
        $display("--- Basic Test 1: Initial Write ---");
        write_access(32'h0000_1000, 8'hAA);
        
        $display("--- Basic Test 2: Read After Write ---");
        read_access(32'h0000_1000);
        display_test_results(); // Display totals after the test

        $display("--- Basic Test 3: Conflict Write ---");
        write_access(32'h0000_2000, 8'hBB);
        
        $display("--- Basic Test 4: Read Original Address After Conflict ---");
        read_access(32'h0000_1000);
        display_test_results(); // Display totals after the test
        
        $display("--- Basic Test 5: Read Conflict Address ---");
        read_access(32'h0000_2000);
        display_test_results(); // Display totals after the test
        
        $display("--- Basic Test 6: Write to a Different Set ---");
        write_access(32'h0000_3000, 8'hCC);
        
        $display("--- Basic Test 7: Read from New Set ---");
        read_access(32'h0000_3000);
        display_test_results(); // Display totals after the test

        // Test Cases
        $display("--- Test 8: Sequential Read Access ---");
        for (int i = 0; i < NUM_SETS * BLOCK_SIZE * 2; i = i + BLOCK_SIZE) begin 
            read_access(32'h0001_0000 + i);
        end
        display_test_results(); // Display totals after the test

        $display("--- Test 9: Strided Read Access (Stride = Block Size) ---");
        for (int i = 0; i < NUM_SETS * BLOCK_SIZE; i = i + BLOCK_SIZE) begin
            read_access(32'h0002_0000 + i);
        end
        display_test_results(); // Display totals after the test

        $display("--- Test 10: Strided Read Access (Stride < Block Size) ---");
        for (int i = 0; i < NUM_SETS * BLOCK_SIZE; i = i + (BLOCK_SIZE / 4)) begin 
            read_access(32'h0003_0000 + i);
        end
        display_test_results(); // Display totals after the test

        $display("--- Test 11: Sequential Write Access ---");
        for (int i = 0; i < NUM_SETS * BLOCK_SIZE; i = i + BLOCK_SIZE) begin
            write_access(32'h0004_0000 + i, 8'hEE);
        end
        display_test_results(); // Display totals after the test

        $display("--- Test 12: Read Back Sequential Writes ---");
        for (int i = 0; i < NUM_SETS * BLOCK_SIZE; i = i + BLOCK_SIZE) begin
            read_access(32'h0004_0000 + i);
        end
        display_test_results(); // Display totals after the test

        $display("--- Test 13: Accesses within the same set, different offsets ---");
        for (int i = 0; i < BLOCK_SIZE; i++) begin
            write_access(32'h0005_0000 + i, 8'hF0 + i); // Write different data
        end
        for (int i = 0; i < BLOCK_SIZE; i++) begin
            read_access(32'h0005_0000 + i); // Read back
        end
        display_test_results(); // Display totals after the test

        $display("--- Test 14: Random Access ---");
        read_access(32'h0006_1234);
        write_access(32'h0007_5678, 8'h11);
        read_access(32'h0008_9ABC);
        read_access(32'h0007_5678);
        display_test_results(); // Display totals after the test

        // Final Metrics
        $display("--- Simulation Complete ---");
        $display("Total Accesses: %0d", total_accesses);
        $display("Total Read Hits: %0d", read_hits);
        $display("Total Read Misses: %0d", read_misses);
        $display("Total Write Hits: %0d", write_hits);
        $display("Total Write Misses: %0d", write_misses);

        $finish; // End simulation
    end

    // Waveform dumping
    initial begin
        $dumpfile("direct_mapped_cache.vcd");
        $dumpvars(0, direct_mapped_cache_tb);
    end

endmodule