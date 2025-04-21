// control_unit.sv - Auto-generated file

module control_unit (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic reg_write, alu_src, mem_to_reg, mem_read, mem_write, branch,
    output logic [3:0] alu_op
);

    always_comb begin
        // Default values
        reg_write = 0;
        alu_src = 0;
        mem_to_reg = 0;
        mem_read = 0;
        mem_write = 0;
        branch = 0;
        alu_op = 4'b0000;

        case (opcode)
            7'b0110011: begin  // R-Type (ADD, SUB, AND, OR, XOR, etc.)
                reg_write = 1;
                alu_src = 0;
                alu_op = (funct7 == 7'b0000000) ? {1'b0, funct3} : {1'b1, funct3}; // Fix applied
            end
            7'b0010011: begin  // I-Type (ADDI, ANDI, ORI, XORI, etc.)
                reg_write = 1;
                alu_src = 1;
                alu_op = {1'b0, funct3};
            end
            7'b0000011: begin  // Load (LW)
                reg_write = 1;
                alu_src = 1;
                mem_to_reg = 1;
                mem_read = 1;
                alu_op = 4'b0000;  // ADD for address calculation
            end
            7'b0100011: begin  // Store (SW)
                alu_src = 1;
                mem_write = 1;
                alu_op = 4'b0000;  // ADD for address calculation
            end
            7'b1100011: begin  // Branch (BEQ, BNE, BLT, BGE, etc.)
                branch = 1;
                case (funct3)
                    3'b000: alu_op = 4'b0001; // BEQ (ALU: SUB for comparison)
                    3'b001: alu_op = 4'b0001; // BNE (ALU: SUB for comparison)
                    3'b100: alu_op = 4'b0101; // BLT (ALU: SLT for signed comparison)
                    3'b101: alu_op = 4'b0010; // BGE (ALU: SLT for signed comparison)
                    3'b110: alu_op = 4'b1000; // BLTU (ALU: SLTU for unsigned comparison)
                    3'b111: alu_op = 4'b1001; // BGEU (ALU: SLTU for unsigned comparison)
                    default: alu_op = 4'b0000; // Handle unexpected funct3 cases
                endcase
            end
            7'b0110111: begin  // LUI
                reg_write = 1;      // We need to write to a register
                alu_src = 1;        // Use the immediate value
                alu_op = 4'b0001;   // Operation for LUI: essentially setting the immediate value to upper half
            end
        endcase
    end

endmodule