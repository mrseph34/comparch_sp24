// memory.sv - Auto-generated file

module memory (
    input logic clk, mem_read, mem_write,
    input logic [31:0] addr, write_data,
    output logic [31:0] read_data
);
    logic [31:0] mem [0:2047]; // 8 kB of RAM
    
    // Define registers for memory-mapped peripherals
    logic [7:0] led_pwm;  // Example for PWM control
    logic [31:0] ms_timer; // Millisecond timer
    logic [31:0] us_timer; // Microsecond timer

    initial begin
        $readmemh("/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/projects/src/memory/mem_init.memh", mem);
        ms_timer = 0;
        us_timer = 0;
    end

    always_ff @(posedge clk) begin
        // Handle memory writes
        if (mem_write) begin
            if (addr >= 32'hFFF00000 && addr < 32'hFFF00004) begin
                led_pwm <= write_data[7:0]; // Write to PWM control
            end else if (addr == 32'hFFF00004) begin
                ms_timer <= write_data; // Write to millisecond timer
            end else if (addr == 32'hFFF00008) begin
                us_timer <= write_data; // Write to microsecond timer
            end else begin
                mem[addr >> 2] <= write_data; // Write to RAM
            end
        end
    end

    always_comb begin
        // Handle memory reads
        if (addr >= 32'hFFF00000 && addr < 32'hFFF00004) begin
            read_data = {24'b0, led_pwm}; // Read PWM control
        end else if (addr == 32'hFFF00004) begin
            read_data = ms_timer; // Read millisecond timer
        end else if (addr == 32'hFFF00008) begin
            read_data = us_timer; // Read microsecond timer
        end else begin
            read_data = (mem_read) ? mem[addr >> 2] : 32'b0; // Read from RAM
        end
    end
endmodule