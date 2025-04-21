// register_file.sv - Auto-generated file

module register_file (
    input logic clk, reg_write,
    input logic [4:0] rs1, rs2, rd,
    input logic [31:0] write_data,
    output logic [31:0] read_data1, read_data2
);

    logic [31:0] registers [31:0]; // 32 general-purpose registers

    // Read register values
    assign read_data1 = (rs1 != 0) ? registers[rs1] : 0; // Register x0 is always 0
    assign read_data2 = (rs2 != 0) ? registers[rs2] : 0;

    // Write on rising edge
    always_ff @(posedge clk) begin
        if (reg_write && (rd != 0))  // x0 should never be written
            registers[rd] <= write_data;
    end

    // Function to read the value of a register
    function logic [31:0] read_register(input logic [4:0] reg_index);
        return registers[reg_index];
    endfunction

endmodule