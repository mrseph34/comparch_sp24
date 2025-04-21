`timescale 1ps/1ps

module datapath_tb;
    // Signals for datapath
    logic clk, reset;
    logic reg_write, alu_src, mem_to_reg, mem_read, mem_write, branch;
    logic [3:0] alu_op;
    logic [31:0] instr, mem_data;
    logic [31:0] pc, mem_addr, write_data, read_data, alu_result;

    // Instantiate datapath module
    datapath DUT (
        .clk(clk),
        .reset(reset),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .alu_op(alu_op),
        .instr(instr),
        .mem_data(mem_data),
        .pc(pc),
        .mem_addr(mem_addr),
        .write_data(write_data),
        .read_data(read_data),
        .alu_result(alu_result)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        $dumpfile("gtkwave/datapath.vcd");
        $dumpvars(0, datapath_tb);

        // Initialize all control signals
        reset = 1;
        reg_write = 0;
        alu_src = 0;
        mem_to_reg = 0;
        mem_read = 0;
        mem_write = 0;
        branch = 0;
        alu_op = 4'b0000;
        instr = 32'h00000000;
        mem_data = 32'h00000000;
        
        // Release reset after a few clock cycles
        #20 reset = 0;
        
        // ADD R1, R0, R0 (R1 = 0)
        #10;
        reg_write = 1;
        alu_src = 0;
        mem_to_reg = 0;
        alu_op = 4'b0000;
        instr = 32'h00000033; // rd=1, rs1=0, rs2=0, ADD

        // ADDI R2, R0, 5 (R2 = 5)
        #10;
        reg_write = 1;
        alu_src = 1;
        mem_to_reg = 0;
        alu_op = 4'b0000;
        instr = 32'h00500113; // rd=2, rs1=0, imm=5, ADDI
        
        // SW R2, 0(R0) (MEM[0] = 5)
        #10;
        reg_write = 0;
        alu_src = 1;
        mem_write = 1;
        mem_read = 0;
        alu_op = 4'b0000;
        instr = 32'h00202023; // rs2=2, rs1=0, imm=0, SW
        
        // LW R3, 0(R0) (R3 = MEM[0] = 5)
        #10;
        reg_write = 1;
        alu_src = 1;
        mem_to_reg = 1;
        mem_write = 0;
        mem_read = 1;
        alu_op = 4'b0000;
        instr = 32'h00002183; // rd=3, rs1=0, imm=0, LW
        
        // ADD R4, R2, R3 (R4 = 5 + 5 = 10)
        #10;
        reg_write = 1;
        alu_src = 0;
        mem_to_reg = 0;
        mem_write = 0;
        mem_read = 0;
        alu_op = 4'b0000;
        instr = 32'h00310233; // rd=4, rs1=2, rs2=3, ADD
        
        // Run for some more cycles
        #20;
        
        // End simulation
        $display("Simulation complete");
        $finish;
    end
    
    // Monitoring logic
    always @(posedge clk) begin
        if (!reset) begin
            $display("PC: %10d, ALU Result: %10d, Mem Addr: %10d, Write Data: %10d, Read Data: %10d",
                     pc, alu_result, mem_addr, write_data, read_data);
        end
    end

endmodule