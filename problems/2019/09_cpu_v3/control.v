module control(
    input [31:0]instr,
    input [31:0]alu_result,

    output reg [31:0]imm32,
    output reg rf_we,
    output reg [2:0]alu_op,
    output reg has_imm,
    output reg mem_we,
    output reg branch_taken,
    output reg link_reg,
    output reg indirect_branch
);

wire [6:0]opcode = instr[6:0];
wire [2:0]funct3 = instr[14:12];
wire [1:0]funct2 = instr[26:25];
wire [4:0]funct5 = instr[31:27];

always @(*) begin
    rf_we = 1'b0;
    alu_op = 3'b0;
    imm32 = 32'b0;
    has_imm = 1'b0;
    mem_we = 1'b0;
    branch_taken = 1'b0;
    link_reg = 1'b0;
    indirect_branch = 1'b0;

    casez ({funct5, funct2, funct3, opcode})
        17'b?????_??_000_0010011: begin // ADDI
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "ADDI", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            alu_op = 3'b001;
            imm32 = {{20{instr[31]}}, instr[31:20]};
            has_imm = 1'b1;
        end
        17'b?????_??_100_0010011: begin // XORI
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "XORI", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            alu_op = 3'b100;
            imm32 = {{20{instr[31]}}, instr[31:20]};
            has_imm = 1'b1;
        end
        17'b?????_??_110_0010011: begin // ORI
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "ORI", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            alu_op = 3'b110;
            imm32 = {{20{instr[31]}}, instr[31:20]};
            has_imm = 1'b1;
        end
        17'b?????_??_111_0010011: begin // ANDI
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "ANDI", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            alu_op = 3'b111;
            imm32 = {{20{instr[31]}}, instr[31:20]};
            has_imm = 1'b1;
        end
        17'b00000_00_000_0110011: begin // ADD
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "ADD", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            alu_op = 3'b001;
            has_imm = 1'b0;
        end
        17'b00000_00_100_0110011: begin // XOR
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "XOR", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            alu_op = 3'b100;
            has_imm = 1'b0;
        end
        17'b00000_00_110_0110011: begin // OR
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "OR", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            alu_op = 3'b110;
            has_imm = 1'b0;
        end
        17'b00000_00_111_0110011: begin // AND
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "AND", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            alu_op = 3'b111;
            has_imm = 1'b0;
        end
        17'b00000_01_000_0110011: begin
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "MUL", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            alu_op = 3'b010;
            has_imm = 1'b0;
        end
        17'b?????_??_010_0100011: begin // SW
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "SW", funct5, funct2, funct3, opcode);
            rf_we = 1'b0;
            alu_op = 3'b001;
            imm32 = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            has_imm = 1'b1;
            mem_we = 1'b1;
        end
        17'b?????_??_000_1100011: begin // BEQ
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "BEQ", funct5, funct2, funct3, opcode);
            rf_we = 1'b0;
            has_imm = 1'b0; // imm plays role of address offset, not immediate operand.
            imm32 = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            alu_op = 3'b100;
            branch_taken = (alu_result == 0);
        end
        17'b?????_??_001_1100011: begin // BNE
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "BNE", funct5, funct2, funct3, opcode);
            rf_we = 1'b0;
            has_imm = 1'b0; // imm plays role of address offset, not immediate operand.
            imm32 = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            alu_op = 3'b100;
            branch_taken = (alu_result != 0);
        end
        17'b?????_??_???_1101111: begin // JAL
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "JAL", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            link_reg = 1'b1;
            has_imm = 1'b0; // imm plays role of address offset, not immediate operand.
            imm32 = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            branch_taken = 1'b1;
        end
        17'b?????_??_000_1100111: begin // JALR
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                $time, "JALR", funct5, funct2, funct3, opcode);
            rf_we = 1'b1;
            link_reg = 1'b1;
            has_imm = 1'b1;
            indirect_branch = 1'b1;
            imm32 = {{20{instr[31]}}, instr[31:20]};
            alu_op = 3'b001;
            branch_taken = 1'b1;
        end
        default: begin
            $monitor("%4d M> (%s) funct5 = %h, funct2 = %h, funct3 = %h, opcode = %h",
                 $time, "UNKNOWN INSTRUCTION", funct5, funct2, funct3, opcode);
        end
    endcase
end

endmodule
