// datapath.sv - Auto-generated file

`include "./instructions/alu.sv"
`include "./instructions/register_file.sv"

module datapath (
    input logic clk, reset,
    input logic reg_write, alu_src, mem_to_reg, mem_read, mem_write, branch,
    input logic [3:0] alu_op,
    input logic [31:0] instr, mem_data,
    output logic [31:0] pc, mem_addr, write_data, read_data, alu_result
);

    // Define internal signals
    logic [31:0] reg_data1, reg_data2, imm, next_pc;
    logic [4:0] rs1, rs2, rd;
    logic zero;
    logic [6:0] opcode;

    // Extract register addresses and opcode
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];
    assign opcode = instr[6:0];

    // Immediate generation 
    logic [31:0] i_imm, s_imm, b_imm, j_imm;

    // Define immediate values 
    assign i_imm = {{20{instr[31]}}, instr[31:20]}; // I-type immediate
    assign s_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-type immediate
    assign b_imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type immediate
    assign j_imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type immediate

    // Select the appropriate immediate based on opcode using continuous assignment
    assign imm = (opcode == 7'b0110111) ? {instr[31:12], 12'b0} :  // LUI
                 (opcode == 7'b0100011) ? s_imm :                   // Store
                 (opcode == 7'b1100011) ? b_imm :                   // Branch
                 (opcode == 7'b1101111) ? j_imm :                   // JAL
                                           i_imm;                     // I-type and others

    // Register File Instantiation
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

    // ALU Instantiation
    alu ALU (
        .a(reg_data1),
        .b(alu_src ? imm : reg_data2),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(zero)
    );

    // PC Update Logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 0;
        else
            pc <= next_pc;
    end
    
    // Calculate next PC value
    always_comb begin
        if (branch && zero)
            next_pc = pc + imm;         // Branch taken
        else if (opcode == 7'b1101111) // JAL
            next_pc = pc + imm;        // Jump to address
        else
            next_pc = pc + 4;          // Default next PC
    end

    // Outputs
    assign mem_addr = alu_result;
    assign write_data = reg_data2;
    assign read_data = mem_data;

endmodule