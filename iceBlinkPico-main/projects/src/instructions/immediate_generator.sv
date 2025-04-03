// immediate_generator.sv - Auto-generated file

module immediate_generator(
    input  logic [31:0] instr,  // 32-bit instruction
    output logic [31:0] imm     // Sign-extended immediate value
);

    wire [6:0] opcode = instr[6:0];

    assign imm = (opcode == 7'b0010011 || opcode == 7'b0000011) ? {{20{instr[31]}}, instr[31:20]} : // I-type
                 (opcode == 7'b0100011) ? {{20{instr[31]}}, instr[31:25], instr[11:7]} :           // S-type
                 (opcode == 7'b1100011) ? {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0} : // B-type
                 (opcode == 7'b1101111) ? {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0} : // J-type
                 32'b0; // Default case

endmodule