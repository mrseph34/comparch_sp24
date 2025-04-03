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
            7'b1100011: begin  // Branch (BEQ, BNE)
                branch = 1;
                alu_op = 4'b0001;  // SUB for comparison
            end
        endcase
    end

endmodule