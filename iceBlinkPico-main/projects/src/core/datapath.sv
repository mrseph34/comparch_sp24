// datapath.sv - Auto-generated file

`include "./instructions/alu.sv"
`include "./instructions/register_file.sv"
`include "./memory/memory.sv"

module datapath (
    input logic clk, reset,
    input logic reg_write, alu_src, mem_to_reg, mem_read, mem_write, branch,
    input logic [3:0] alu_op,
    input logic [31:0] instr, mem_data,
    output logic [31:0] pc, mem_addr, write_data, read_data, alu_result
);

    logic [31:0] reg_data1, reg_data2, imm, next_pc;
    logic [4:0] rs1, rs2, rd;
    logic zero;
    logic [6:0] opcode;

    // Extract register addresses and opcode
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];
    assign opcode = instr[6:0];
    
    // Immediate generation - using individual assignments instead of case statement
    // I-type immediate (ADDI, LW, etc.)
    logic [31:0] i_imm;
    assign i_imm = {{20{instr[31]}}, instr[31:20]};
    
    // S-type immediate (SW)
    logic [31:0] s_imm;
    assign s_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    
    // B-type immediate (BEQ, BNE)
    logic [31:0] b_imm;
    assign b_imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    //assign b_imm = {{20{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    
    // Select the appropriate immediate based on opcode
    always_comb begin
        if (opcode == 7'b0100011)       // Store
            imm = s_imm;
        else if (opcode == 7'b1100011)  // Branch
            imm = b_imm;
        else                           // I-type and others
            imm = i_imm;
    end

    register_file RF (
        .clk(clk),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(mem_to_reg ? mem_data : alu_result),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    alu ALU (
        .a(reg_data1),
        .b(alu_src ? imm : reg_data2),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero)
    );

    // PC update logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 0;
        else
            pc <= next_pc;
    end
    
    // Calculate next PC value
    always_comb begin
        if (branch && zero)
            next_pc = pc + imm;
        else
            next_pc = pc + 4;
    end

    // Outputs
    assign mem_addr = alu_result;
    assign write_data = reg_data2;
    assign read_data = mem_data;

endmodule