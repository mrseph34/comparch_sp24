// RGB

module top(

    input logic clk,                                            // 12 MHz clock input
    output logic LED,                                           // On-board LED output (active low)
    output logic RGB_R, RGB_G, RGB_B                            // RGB LED outputs (active low)

);

    // Define the clock interval for 1 second based on 12 MHz frequency
    parameter INTERVAL = 12000000;                              // Total clock cycles in 1 second
    logic [$clog2(INTERVAL) - 1:0] count = 0;                   // Counter for clock cycles
    logic [2:0] color_state = 3'b000;                           // State variable for cycling through colors

    // Initial setup of LED states
    initial begin
        LED = 1'b0;                                             // Turn off the LED (active low)
        RGB_R = 1'b1;                                           // Set RGB Red to off (active low)
        RGB_G = 1'b1;                                           // Set RGB Green to off (active low)
        RGB_B = 1'b1;                                           // Set RGB Blue to off (active low)
    end

    // Always block triggered on the rising edge of the clock
    always_ff @(posedge clk) begin 
           
        // Check if the count has reached the interval limit
        if (count == INTERVAL - 1) begin  
                    
            count <= 0;                                         // Reset cyc count
            
            // Update the color state, cycling through colors
            color_state <= (color_state == 3'b101) ? 3'b000 : color_state + 1; 

            // Set the RGB outputs based on the current color state
            case (color_state)
                3'b000: {RGB_R, RGB_G, RGB_B} <= 3'b100;        // red
                3'b001: {RGB_R, RGB_G, RGB_B} <= 3'b110;        // yellow
                3'b010: {RGB_R, RGB_G, RGB_B} <= 3'b010;        // green
                3'b011: {RGB_R, RGB_G, RGB_B} <= 3'b011;        // cyan
                3'b100: {RGB_R, RGB_G, RGB_B} <= 3'b001;        // blue
                3'b101: {RGB_R, RGB_G, RGB_B} <= 3'b101;        // purple
            endcase

        end else begin

            count <= count + 1;                                 // Increment the count if not at interval

        end

    end

endmodule