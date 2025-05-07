// set_associative_cache_tb.sv

module set_associative_cache_tb;

    // Parameters
    parameter CACHE_SIZE = 256;
    parameter BLOCK_SIZE = 16;
    parameter ASSOC = 4;  // 4-way set associative
    parameter NUM_SETS = CACHE_SIZE / (BLOCK_SIZE * ASSOC); // Should be 256 / (16 * 4) = 4

    localparam PERIOD = 10;
    localparam INDEX_WIDTH = $clog2(NUM_SETS);
    localparam BLOCK_OFFSET_WIDTH = $clog2(BLOCK_SIZE);
    localparam TAG_WIDTH = 32 - INDEX_WIDTH - BLOCK_OFFSET_WIDTH;

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
        $display("ASSOC = %0d ways", ASSOC);
        $display("NUM_SETS = %0d sets", NUM_SETS);
        $display("TAG_WIDTH = %0d bits", TAG_WIDTH);
        $display("INDEX_WIDTH = %0d bits", INDEX_WIDTH);
        $display("BLOCK_OFFSET_WIDTH = %0d bits", BLOCK_OFFSET_WIDTH);
        $display("-------------------------------------");
    end

    // Instantiate the Cache Module
    set_associative_cache #(
        .CACHE_SIZE(CACHE_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .ASSOC(ASSOC),
        .NUM_SETS(NUM_SETS)
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

    // Helper function to generate address with specific set index
    function [31:0] generate_addr(input [31:0] tag_val, input [INDEX_WIDTH-1:0] set_idx, input [BLOCK_OFFSET_WIDTH-1:0] offset);
        return (tag_val << (INDEX_WIDTH + BLOCK_OFFSET_WIDTH)) | (set_idx << BLOCK_OFFSET_WIDTH) | offset;
    endfunction

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
    task display_test_results(input string test_name);
        $display("Test %s: Read Hits: %0d, Read Misses: %0d, Write Hits: %0d, Write Misses: %0d", 
                 test_name, test_read_hits, test_read_misses, test_write_hits, test_write_misses);
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

        // Test 1: Initial Writes to Fill Cache Set 0
        for (int i = 0; i < ASSOC; i++) begin
            // Using set 0 for all writes
            write_access(generate_addr(i + 1, 0, 0), 8'hAA + i);
        end
        display_test_results("1 - Fill Set 0");

        // Test 2: Read Back Initial Writes (Should be Hits)
        for (int i = 0; i < ASSOC; i++) begin
            read_access(generate_addr(i + 1, 0, 0));
        end
        display_test_results("2 - Read Back Set 0");

        // Test 3: Write to cause eviction in set 0 (FIFO)
        write_access(generate_addr(ASSOC + 1, 0, 0), 8'hFF);
        display_test_results("3 - Eviction in Set 0");

        // Test 4: Read Original First Address (Should be Miss - replaced by FIFO)
        read_access(generate_addr(1, 0, 0));
        display_test_results("4 - Read First Address After Eviction");

        // Test 5: Read the Newly Written Address (Should be Hit)
        read_access(generate_addr(ASSOC + 1, 0, 0));
        display_test_results("5 - Read New Address After Eviction");

        // Test 6: Write and Read from Different Sets
        for (int s = 0; s < NUM_SETS; s++) begin
            write_access(generate_addr(10 + s, s, 0), 8'h10 + s);
        end
        for (int s = 0; s < NUM_SETS; s++) begin
            read_access(generate_addr(10 + s, s, 0));
        end
        display_test_results("6 - Write/Read Different Sets");

        // Test 7: Access different offsets within the same block
        write_access(generate_addr(20, 1, 0), 8'h20);
        write_access(generate_addr(20, 1, 1), 8'h21);
        write_access(generate_addr(20, 1, BLOCK_SIZE - 1), 8'h2F);
        read_access(generate_addr(20, 1, 0));
        read_access(generate_addr(20, 1, 1));
        read_access(generate_addr(20, 1, BLOCK_SIZE - 1));
        display_test_results("7 - Different Offsets Same Block");

        // Test 8: Fill a Set to Capacity and Beyond
        for (int i = 0; i < ASSOC + 2; i++) begin
            write_access(generate_addr(30 + i, 2, 0), 8'h30 + i);
        end
        display_test_results("8 - Fill Set 2 Beyond Capacity");

        // Test 9: Read Back Set 2 - Earlier addresses should miss, later ones hit
        read_access(generate_addr(30, 2, 0));     // Should miss (evicted)
        read_access(generate_addr(31, 2, 0));     // Should miss (evicted)
        read_access(generate_addr(32, 2, 0));     // Should hit
        read_access(generate_addr(33, 2, 0));     // Should hit
        read_access(generate_addr(ASSOC + 30, 2, 0)); // Should hit
        read_access(generate_addr(ASSOC + 31, 2, 0)); // Should hit
        display_test_results("9 - Read Back Set 2 After Eviction");

        // Test 10: Test Set Conflict Misses
        // Fill set 3 with specific pattern
        for (int i = 0; i < ASSOC; i++) begin
            write_access(generate_addr(40 + i, 3, 0), 8'h40 + i);
        end
        // Now replace with different pattern (Set 3 conflict misses)
        for (int i = 0; i < ASSOC; i++) begin
            write_access(generate_addr(50 + i, 3, 0), 8'h50 + i);
        end
        // Read back original pattern (should all miss)
        for (int i = 0; i < ASSOC; i++) begin
            read_access(generate_addr(40 + i, 3, 0));
        end
        // Read back new pattern (should all hit)
        for (int i = 0; i < ASSOC; i++) begin
            read_access(generate_addr(50 + i, 3, 0));
        end
        display_test_results("10 - Set Conflict Misses");

        // Test 11: Sequential Access Across Sets
        for (int s = 0; s < NUM_SETS; s++) begin
            for (int w = 0; w < ASSOC; w++) begin
                write_access(generate_addr(60 + w, s, 0), 8'h60 + w + s);
            end
        end
        for (int s = 0; s < NUM_SETS; s++) begin
            for (int w = 0; w < ASSOC; w++) begin
                read_access(generate_addr(60 + w, s, 0));
            end
        end
        display_test_results("11 - Sequential Access Across Sets");

        // Test 12: Random Access Pattern (Hit/Miss Mix)
        read_access(generate_addr(70, 0, 0));  // Miss
        write_access(generate_addr(70, 0, 0), 8'h70);  // Miss
        read_access(generate_addr(70, 0, 0));  // Hit
        read_access(generate_addr(71, 1, 0));  // Miss
        write_access(generate_addr(71, 1, 0), 8'h71);  // Miss
        read_access(generate_addr(71, 1, 0));  // Hit
        read_access(generate_addr(70, 0, 0));  // Hit
        display_test_results("12 - Random Access Pattern");

        // Test 13: Strided Access Across Sets
        for (int i = 0; i < 2 * NUM_SETS; i++) begin
            read_access(generate_addr(80 + i, i % NUM_SETS, 0));
        end
        display_test_results("13 - Strided Access Across Sets");

        // Test 14: Access with Different Block Offsets
        for (int o = 0; o < BLOCK_SIZE; o++) begin
            write_access(generate_addr(90, 0, o), 8'h90 + o);
        end
        for (int o = 0; o < BLOCK_SIZE; o++) begin
            read_access(generate_addr(90, 0, o));
        end
        display_test_results("14 - Different Block Offsets");

        // Final Metrics
        $display("--- Simulation Complete ---");
        $display("Total Accesses: %0d", total_accesses);
        $display("Total Read Hits: %0d", read_hits);
        $display("Total Read Misses: %0d", read_misses);
        $display("Total Write Hits: %0d", write_hits);
        $display("Total Write Misses: %0d", write_misses);
        $display("Hit Rate: %0.2f%%", (read_hits + write_hits) * 100.0 / total_accesses);
        $display("-------------------------------------");

        $finish; // End simulation
    end

    // Waveform dumping
    initial begin
        $dumpfile("set_associative_cache.vcd");
        $dumpvars(0, set_associative_cache_tb);
    end

endmodule