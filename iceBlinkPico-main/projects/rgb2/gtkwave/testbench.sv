module testbench;
    // Testbench signals
    logic CLK;
    logic LED;
    logic RGB_R, RGB_G, RGB_B;

    // Instantiate the top module
    top uut (
        .CLK(CLK),
        .LED(LED),
        .RGB_R(RGB_R),
        .RGB_G(RGB_G),
        .RGB_B(RGB_B)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 10 time units for a full clock cycle
    end

    // Test stimulus and monitoring
    initial begin
        $dumpfile("rgb2.vcd");
        $dumpvars(0, testbench);
        
        // Let it run for 1 second (1_000_000_000 ns)
        #1000000000;
        $finish;
    end
endmodule