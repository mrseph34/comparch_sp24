/ProjectFolder
│
├── blink_leds.s              # Assembly code for blinking LEDs
├── cpu.sv                     # CPU module
├── core/
│   ├── control_unit.sv       # Control unit logic
│   └── datapath.sv           # Datapath logic
├── instructions/
│   ├── alu.sv                # ALU logic
│   ├── immediate_generator.sv # Immediate generator logic
│   ├── register_file.sv      # Register file logic
│   ├── instruction_decoder.sv # Instruction decoder logic
├── memory/
│   ├── memory.sv             # Memory logic
│   └── mem_init.hex          # Initialization file for memory
└── top.sv                    # Top-level module

# Instructions for mem_init
instructions = [
    '00000033',  # ADD R1, R0, R0
    '00500113',  # ADDI R2, R0, 5
    '00202023',  # SW R2, 0(R0)
    '00002183',  # LW R3, 0(R0)
    '00310233',  # ADD R4, R2, R3
    '00005037',  # LUI R5, 0x00001
]

total_memory_words = 2048

# Create and write to mem_init.memh
with open('mem_init.memh', 'w') as mem_file:
    for instruction in instructions:
        mem_file.write(f'{instruction}\n')  # Write each instruction
  
    # Pad the rest of the memory with zeros
    for _ in range(len(instructions), total_memory_words):
        mem_file.write('00000000\n')  # Add zeros for unused addresses


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

// memory.sv - Auto-generated file

module memory (
    input logic clk, mem_read, mem_write,
    input logic [31:0] addr, write_data,
    output logic [31:0] read_data
);
    logic [31:0] mem [0:2047]; // 8 kB of RAM
    
    // Define registers for memory-mapped peripherals
    logic [7:0] led_pwm;  // Example for PWM control
    logic [31:0] ms_timer; // Millisecond timer
    logic [31:0] us_timer; // Microsecond timer

    initial begin
        $readmemh("/Users/user/Documents/Coding/Computer Architecture/comparch_sp24/iceBlinkPico-main/projects/src/memory/mem_init.memh", mem);
        ms_timer = 0;
        us_timer = 0;
    end

    always_ff @(posedge clk) begin
        // Handle memory writes
        if (mem_write) begin
            if (addr >= 32'hFFF00000 && addr < 32'hFFF00004) begin
                led_pwm <= write_data[7:0]; // Write to PWM control
            end else if (addr == 32'hFFF00004) begin
                ms_timer <= write_data; // Write to millisecond timer
            end else if (addr == 32'hFFF00008) begin
                us_timer <= write_data; // Write to microsecond timer
            end else begin
                mem[addr >> 2] <= write_data; // Write to RAM
            end
        end
    end

    always_comb begin
        // Handle memory reads
        if (addr >= 32'hFFF00000 && addr < 32'hFFF00004) begin
            read_data = {24'b0, led_pwm}; // Read PWM control
        end else if (addr == 32'hFFF00004) begin
            read_data = ms_timer; // Read millisecond timer
        end else if (addr == 32'hFFF00008) begin
            read_data = us_timer; // Read microsecond timer
        end else begin
            read_data = (mem_read) ? mem[addr >> 2] : 32'b0; // Read from RAM
        end
    end
endmodule

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