// alu.sv - Auto-generated file

module alu (
    input logic [31:0] a, b,
    input logic [3:0] alu_op,
    output logic [31:0] result,
    output logic zero
);
    logic [31:0] shift_amount;  // Temporary variable for shifting

    always_comb begin
        // $display("ALU Debug: A=%d, B=%d, ALU_OP=%b", a, b, alu_op);
        shift_amount = b & 32'h1F; // Ensure shift amount is within valid range (0-31)
        case (alu_op)
            4'b0000: result = a + b;                                            // ADD
            4'b0001: result = a - b;                                            // SUB
            4'b0010: result = a & b;                                            // AND
            4'b0011: result = a | b;                                            // OR
            4'b0100: result = a ^ b;                                            // XOR
            4'b0101: result = ($signed(a) < $signed(b)) ? 1 : 0;                // SLT (signed comparison)
            4'b0110: result = a << shift_amount;                                // SLL (shift left)
            4'b0111: result = a >> shift_amount;                                // SRL (logical shift right)
            4'b1000: result = (a < b) ? 1 : 0;                                  // SLTU (unsigned comparison)
            4'b1001: result = $signed(a) >>> shift_amount;                      // SRA (arithmetic shift right)
            default: result = 0;
        endcase
        zero = (result == 0);
    end
endmodule