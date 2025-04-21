`timescale 1ns / 1ps

module cpu_tb;

    // Testbench signals
    logic clk, reset;
    logic [31:0] instr, mem_data;
    logic [31:0] mem_addr, write_data;
    logic mem_read, mem_write;
    
    // PC for tracking
    logic [31:0] pc;

    // Instantiate the CPU
    cpu uut (
        .clk(clk),
        .reset(reset),
        .instr(instr),
        .mem_data(mem_data),
        .mem_addr(mem_addr),
        .write_data(write_data),
        .mem_read(mem_read),
        .mem_write(mem_write)
    );

    // Instruction & Data Memory
    logic [31:0] instr_mem [0:63];  
    logic [31:0] data_mem [0:63];  

    // Clock generation
    always #5 clk = ~clk;
    
    // Track PC from the CPU
    assign pc = uut.DP.pc;

    // Initialize test sequence
    initial begin
        clk = 0;
        reset = 1;
        instr = 32'b0;
        mem_data = 32'b0;
        
        // Initialize memories
        for (int i = 0; i < 64; i++) begin
            instr_mem[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
            data_mem[i] = 0;
        end
        
        // Load test instructions
        instr_mem[0] = 32'b00000000000100000000000010010011; // ADDI x1, x0, 1
        instr_mem[1] = 32'b00000000001000000000000100010011; // ADDI x2, x0, 2
        instr_mem[2] = 32'b00000000001000001000000110110011; // ADD x3, x1, x2
        instr_mem[3] = 32'b00000000001100000010001000100011; // SW x3, 4(x0)
        instr_mem[4] = 32'b00000000010000000010001000000011; // LW x4, 4(x0)
        instr_mem[5] = 32'b00000000010000100000010001100011; // BEQ x4, x2, skip next
        instr_mem[6] = 32'b00000000010100000000000010010011; // ADDI x1, x0, 5 (skipped if branch taken)
        instr_mem[7] = 32'b00000000011000000000000010010011; // ADDI x1, x0, 6 (branch target)
        
        #10 reset = 0;

        // Run simulation
        repeat (20) begin
            @(posedge clk);
            if (pc >> 2 < 64) begin
                instr = instr_mem[pc >> 2];
                $display("PC=%h | Instr=%h", pc, instr);
            end else begin
                instr = 32'h00000013;
                $display("PC=%h out of range", pc);
            end
            
            @(negedge clk);
            if (mem_read) begin
                if (mem_addr >> 2 < 64) begin
                    mem_data = data_mem[mem_addr >> 2];
                    $display("Mem Read: Addr=%h | Data=%h", mem_addr, mem_data);
                end else begin
                    mem_data = 32'h0;
                    $display("Mem Read Error: Addr=%h out of range", mem_addr);
                end
            end
        end

        // End simulation
        #10 $finish;
    end

    // Memory writes
    always @(posedge clk) begin
        if (mem_write) begin
            if (mem_addr >> 2 < 64) begin
                data_mem[mem_addr >> 2] <= write_data;
                $display("Mem Write: Addr=%h | Data=%h", mem_addr, write_data);
            end else begin
                $display("Mem Write Error: Addr=%h out of range", mem_addr);
            end
        end
    end

    // Register File Monitoring
    int i;
    initial begin
        @(negedge reset);
        forever begin
            @(posedge clk);
            #1;
            for (i = 0; i < 8; i++) begin
                $display("Reg[%0d] = %h", i, uut.DP.RF.registers[i]);
            end
        end
    end

    // CPU Debugging Output
    always @(posedge clk) begin
        $display("T=%0t | PC=%h | Instr=%h | MemAddr=%h | WriteData=%h | ReadData=%h | MemRead=%b | MemWrite=%b",
                 $time, pc, instr, mem_addr, write_data, mem_data, mem_read, mem_write);
    end

endmodule