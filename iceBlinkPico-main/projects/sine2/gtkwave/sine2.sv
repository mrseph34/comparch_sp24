`include "memory.sv"

module top(
    input logic     clk, 
    output logic    _9b,    // D0
    output logic    _6a,    // D1
    output logic    _4a,    // D2
    output logic    _2a,    // D3
    output logic    _0a,    // D4
    output logic    _5a,    // D5
    output logic    _3b,    // D6
    output logic    _49a,   // D7
    output logic    _45a,   // D8
    output logic    _48b    // D9
);

    logic [8:0] counter = 0;
    logic [8:0] quarter_wave_value;
    logic [9:0] output_value;
    logic [6:0] memory_address;
    
    // Extract the quadrant (2 MSB of counter)
    logic [1:0] quadrant;
    assign quadrant = counter[8:7];
    
    memory #(
        .INIT_FILE("sine2.txt")
    ) u1 (
        .clk(clk),
        .read_address(memory_address),
        .read_data(quarter_wave_value)
    );
    
    // Increment counter on each clock edge
    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end
    
    // Calculate memory address based on quadrant
    always_comb begin
        case(quadrant)
            2'b00: memory_address = counter[6:0];             // First quadrant (0-127): direct mapping
            2'b01: memory_address = 7'd127 - counter[6:0];    // Second quadrant (128-255): reverse order
            2'b10: memory_address = counter[6:0];
            2'b11: memory_address = 7'd127 - counter[6:0];
        endcase
    end
    
    // Calculate final output value based on quadrant - CORRECTED to fix orientation
    always_comb begin
        case(quadrant)
            // First half-cycle
            2'b00, 2'b01: output_value = 10'd512 + {1'b0, quarter_wave_value};
            // Second half-cycle flip back to 0
            2'b10, 2'b11: output_value = 10'd512 - {1'b0, quarter_wave_value};
        endcase
    end
    
    assign {_48b, _45a, _49a, _3b, _5a, _0a, _2a, _4a, _6a, _9b} = output_value;

endmodule