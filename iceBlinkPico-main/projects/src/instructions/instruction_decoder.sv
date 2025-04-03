// instruction_decoder.sv - Auto-generated file

module instruction_decoder(
    input  logic [31:0] instr, // 32-bit instruction
    output logic [6:0] opcode,
    output logic [4:0] rd,
    output logic [2:0] funct3,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [6:0] funct7,
    output logic [31:0] imm,  // Sign-extended immediate
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic branch
);

    // Extract opcode
    assign opcode = instr[6:0];

    // Register and function field extraction
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // Immediate value extraction (fixed)
    assign imm = (opcode == 7'b0010011 || opcode == 7'b0000011) ? {{20{instr[31]}}, instr[31:20]} : // I-type
                 (opcode == 7'b0100011) ? {{20{instr[31]}}, instr[31:25], instr[11:7]} : // S-type
                 (opcode == 7'b1100011) ? {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0} : // B-type
                 (opcode == 7'b1101111) ? {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0} : // J-type
                 32'b0;

    // Control signals
    assign reg_write = (opcode == 7'b0110011 || opcode == 7'b0010011 || opcode == 7'b1101111); // R, I, J types
    assign mem_read  = (opcode == 7'b0000011); // Load instructions (LW)
    assign mem_write = (opcode == 7'b0100011); // Store instructions (SW)
    assign branch    = (opcode == 7'b1100011); // Branch instructions (BEQ, BNE)

endmodule