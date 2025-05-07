// fully_associative_cache_tb.sv

module fully_associative_cache_tb;

    // Parameters
    parameter CACHE_SIZE = 256;
    parameter BLOCK_SIZE = 16;
    parameter ASSOC = CACHE_SIZE / BLOCK_SIZE; // Should be 256 / 16 = 16

    localparam PERIOD = 10;
    localparam TAG_WIDTH = 32 - $clog2(BLOCK_SIZE);

    // Signals
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
        $display("CACHE_SIZE = %0d bytes", CACHE_SIZE);
        $display("BLOCK_SIZE = %0d bytes", BLOCK_SIZE);
        $display("ASSOC = %0d (Fully Associative)", ASSOC);
        $display("-------------------------------------");
    end

    // Instantiate the Cache Module
    fully_associative_cache #(
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
            #(PERIOD); // Wait one clock cycle
            #(PERIOD/2); // Sample hit/miss
            if (hit) begin
                test_read_hits++;
                read_hits++;
            end else begin
                test_read_misses++;
                read_misses++;
            end
            #(PERIOD/2); // Complete the clock cycle
        end
    endtask

    // Write operation task
    task write_access(input [31:0] write_addr, input [7:0] data_to_write);
        begin
            addr = write_addr;
            wr_data = data_to_write;
            wr_en = 1;
            total_accesses++;
            #(PERIOD); // Wait one clock cycle
            #(PERIOD/2); // Sample hit/miss
            if (hit) begin
                test_write_hits++;
                write_hits++;
            end else begin
                test_write_misses++;
                write_misses++;
            end
            #(PERIOD/2); // Complete the clock cycle
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
        reset = 1;
        addr = 32'b0;
        wr_data = 8'b0;
        #(PERIOD * 5); // Hold reset for a few cycles
        reset = 0;
        #(PERIOD); // Wait one cycle after reset deassertion

        // Initialize temporary counters
        test_read_hits = 0;
        test_read_misses = 0;
        test_write_hits = 0;
        test_write_misses = 0;

        // --- Basic Test Cases ---

        // Test 1: Initial Writes to Fill Cache
        for (int i = 0; i < ASSOC; i++) begin
            write_access(32'h0000_1000 + i * BLOCK_SIZE * 10, 8'hAA + i);
        end
        display_test_results();

        // Test 2: Read Back Initial Writes (Should be Hits)
        for (int i = 0; i < ASSOC; i++) begin
            read_access(32'h0000_1000 + i * BLOCK_SIZE * 10);
        end
        display_test_results();

        // Test 3: Write to Cause Replacement (FIFO)
        write_access(32'h0000_FFFF, 8'hFF);
        display_test_results();

        // Test 4: Read Original First Address (Should be Miss)
        read_access(32'h0000_1000);
        display_test_results();

        // Test 5: Read the Newly Written Address (Should be Hit)
        read_access(32'h0000_FFFF);
        display_test_results();

        // Test 6: Write and Read within the same block
        write_access(32'h0000_2000, 8'h10);
        write_access(32'h0000_2000 + 1, 8'h11);
        write_access(32'h0000_2000 + BLOCK_SIZE - 1, 8'h1F);
        read_access(32'h0000_2000);
        read_access(32'h0000_2000 + 1);
        read_access(32'h0000_2000 + BLOCK_SIZE - 1);
        display_test_results();

        // Test 7: Random Accesses
        read_access(32'h0000_3333); // Miss
        write_access(32'h0000_4444, 8'hCC); // Miss
        read_access(32'h0000_3333); // Could be hit or miss
        read_access(32'h0000_4444); // Hit
        display_test_results();

        // --- Extended Test Cases ---

        // Test 8: Sequential Read Access (Larger Range)
        for (int i = 0; i < ASSOC * BLOCK_SIZE * 2; i = i + BLOCK_SIZE) begin
            read_access(32'h0001_0000 + i);
        end
        display_test_results();

        // Test 9: Strided Read Access (Stride = Block Size)
        for (int i = 0; i < ASSOC * BLOCK_SIZE * 2; i = i + BLOCK_SIZE) begin
            read_access(32'h0002_0000 + i);
        end
        display_test_results();

        // Test 10: Strided Read Access (Stride < Block Size)
        for (int i = 0; i < ASSOC * BLOCK_SIZE * 2; i = i + (BLOCK_SIZE / 4)) begin
             read_access(32'h0003_0000 + i);
        end
        display_test_results();

        // Test 11: Sequential Write Access
        for (int i = 0; i < ASSOC * BLOCK_SIZE * 2; i = i + BLOCK_SIZE) begin
            write_access(32'h0004_0000 + i, 8'hEE + (i / BLOCK_SIZE));
        end
        display_test_results();

        // Test 12: Read Back Sequential Writes
        for (int i = 0; i < ASSOC * BLOCK_SIZE * 2; i = i + BLOCK_SIZE) begin
            read_access(32'h0004_0000 + i);
        end
        display_test_results();

        // Test 13: Accesses within the same block, different offsets
        write_access(32'h0005_0000, 8'hA0);
        write_access(32'h0005_0000 + 4, 8'hA4);
        write_access(32'h0005_0000 + 8, 8'hA8);
        read_access(32'h0005_0000 + 4);
        read_access(32'h0005_0000 + 8);
        read_access(32'h0005_0000);
        display_test_results();

        // Test 14: Repeated Access to a Few Blocks (Testing Hits)
        write_access(32'h0006_1000, 8'hB1);
        write_access(32'h0006_2000, 8'hB2);
        write_access(32'h0006_3000, 8'hB3);
        read_access(32'h0006_1000); // Should be hit
        read_access(32'h0006_2000); // Should be hit
        read_access(32'h0006_3000); // Should be hit
        read_access(32'h0006_1000); // Should be hit again
        display_test_results();

        // Final Metrics
        $display("--- Simulation Complete ---");
        $display("Total Accesses: %0d", total_accesses);
        $display("Total Read Hits: %0d", read_hits);
        $display("Total Read Misses: %0d", read_misses);
        $display("Total Write Hits: %0d", write_hits);
        $display("Total Write Misses: %0d", write_misses);
        $display("-------------------------------------");

        $finish; // End simulation
    end

    // Waveform dumping
    initial begin
        $dumpfile("fully_associative_cache.vcd");
        $dumpvars(0, fully_associative_cache_tb);
    end

endmodule
