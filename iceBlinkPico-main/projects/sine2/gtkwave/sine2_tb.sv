`timescale 10ns/10ns

module sine2_tb;

    logic clk = 0;
    logic _9b, _6a, _4a, _2a, _0a, _5a, _3b, _49a, _45a, _48b;

    logic [9:0] dac_value;
    assign dac_value = {_48b, _45a, _49a, _3b, _5a, _0a, _2a, _4a, _6a, _9b};

    top u0 (
        .clk    (clk), 
        ._9b    (_9b), 
        ._6a    (_6a), 
        ._4a    (_4a), 
        ._2a    (_2a), 
        ._0a    (_0a), 
        ._5a    (_5a), 
        ._3b    (_3b), 
        ._49a   (_49a), 
        ._45a   (_45a), 
        ._48b   (_48b)
    );

    initial begin
        $dumpfile("sine2.vcd");
        $dumpvars(0, sine2_tb);
        $dumpvars(1, dac_value);
        #10000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule