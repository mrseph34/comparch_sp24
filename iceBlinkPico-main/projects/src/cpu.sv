// cpu.sv - Auto-generated file

`include "./core/control_unit.sv"
`include "./core/datapath.sv"

module cpu (
    input logic clk, reset,
    input logic [31:0] instr, mem_data,  // Instruction & Memory Data
    output logic [31:0] mem_addr, write_data,  // Memory Address & Data Output
    output logic mem_read, mem_write  // Memory Control Signals
);

    logic [31:0] pc, alu_result, read_data;
    logic reg_write, alu_src, mem_to_reg, branch;
    logic [3:0] alu_op;

    // Control Unit
    control_unit CU (
        .opcode(instr[6:0]),
        .funct3(instr[14:12]),
        .funct7(instr[31:25]),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .alu_op(alu_op)
    );

    // Datapath
    datapath DP (
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
        .alu_result(alu_result),
        .write_data(write_data),
        .read_data(read_data)
    );

    assign mem_addr = alu_result; // Memory address comes from ALU result

endmodule