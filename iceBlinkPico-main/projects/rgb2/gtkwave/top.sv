module top(
    input logic CLK,                     // 12 MHz clock input
    output logic LED,                    // On-board LED output (active low)
    output logic RGB_R, RGB_G, RGB_B     // RGB LED outputs (active low)
);

    // Parameters for timing and control
    parameter PWM_BITS = 4;             // 4-bit PWM resolution
    parameter PWM_COUNT_MAX = 15;       // Maximum PWM count (2^4 - 1)
    parameter ANGLE_MAX = 360;          // Full circle
    parameter STEP_SIZE = 60;           // 60 degrees per transition

    // Internal signals
    logic [23:0] count = 0;            // Counter for timing
    logic [PWM_BITS-1:0] pwm_counter = 0;
    logic [8:0] angle_counter = 0;     // Increased size to handle 0-360
    logic [PWM_BITS-1:0] r_intensity;
    logic [PWM_BITS-1:0] g_intensity;
    logic [PWM_BITS-1:0] b_intensity;
    
    // Initialize outputs
    initial begin
        LED = 1'b0;    // LED off (active low)
        RGB_R = 1'b1;  // Red off (active low)
        RGB_G = 1'b1;  // Green off (active low)
        RGB_B = 1'b1;  // Blue off (active low)
    end

    // Intensity Calculation
    always_comb begin
        case (angle_counter / STEP_SIZE)
            0: begin  // 0-60: R=100%, G=0-100%, B=0%
                r_intensity = PWM_COUNT_MAX;
                g_intensity = (angle_counter * PWM_COUNT_MAX) / STEP_SIZE;
                b_intensity = 0;
            end
            1: begin  // 60-120: R=100-0%, G=100%, B=0%
                r_intensity = PWM_COUNT_MAX - ((angle_counter - STEP_SIZE) * PWM_COUNT_MAX) / STEP_SIZE;
                g_intensity = PWM_COUNT_MAX;
                b_intensity = 0;
            end
            2: begin  // 120-180: R=0%, G=100%, B=0-100%
                r_intensity = 0;
                g_intensity = PWM_COUNT_MAX;
                b_intensity = ((angle_counter - 2*STEP_SIZE) * PWM_COUNT_MAX) / STEP_SIZE;
            end
            3: begin  // 180-240: R=0%, G=100-0%, B=100%
                r_intensity = 0;
                g_intensity = PWM_COUNT_MAX - ((angle_counter - 3*STEP_SIZE) * PWM_COUNT_MAX) / STEP_SIZE;
                b_intensity = PWM_COUNT_MAX;
            end
            4: begin  // 240-300: R=0-100%, G=0%, B=100%
                r_intensity = ((angle_counter - 4*STEP_SIZE) * PWM_COUNT_MAX) / STEP_SIZE;
                g_intensity = 0;
                b_intensity = PWM_COUNT_MAX;
            end
            default: begin  // 300-360: R=100%, G=0%, B=100-0%
                r_intensity = PWM_COUNT_MAX;
                g_intensity = 0;
                b_intensity = PWM_COUNT_MAX - ((angle_counter - 5*STEP_SIZE) * PWM_COUNT_MAX) / STEP_SIZE;
            end
        endcase
    end

    // PWM control
    always_ff @(posedge CLK) begin
        count <= count + 1;
        if (count[8:0] == 0) begin
            pwm_counter <= pwm_counter + 1;
            if (pwm_counter == PWM_COUNT_MAX) begin
                pwm_counter <= 0;
            end
        end

        // Update angle every angle increment period (1 second / 360 = ~2,777,778 ns)
        if (count == (12000000 / 360)) begin 
            count <= 0;
            angle_counter <= (angle_counter == ANGLE_MAX - 1) ? 0 : angle_counter + 1;
        end

        // PWM Control
        RGB_R <= (pwm_counter < r_intensity) ? 1'b0 : 1'b1;
        RGB_G <= (pwm_counter < g_intensity) ? 1'b0 : 1'b1;
        RGB_B <= (pwm_counter < b_intensity) ? 1'b0 : 1'b1;
    end

endmodule