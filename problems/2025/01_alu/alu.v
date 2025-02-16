`include "alu.vh"

module alu (
    input  wire [`ALUOP_WIDTH-1:0] op,
    input  wire [31:0]             rs1, rs2,
    output reg  [31:0]             rd
);

always @(*) begin
    case (op)
        `ALUOP_ADD:  rd = rs1 + rs2;
        `ALUOP_SUB:  rd = rs1 - rs2;
        `ALUOP_SLL:  rd = rs1 << rs2[4:0];
        `ALUOP_SLT:  rd = ($signed(rs1) < $signed(rs2));
        `ALUOP_SLTU: rd = (rs1 < rs2);
        `ALUOP_XOR:  rd = rs1 ^ rs2;
        `ALUOP_SRL:  rd = rs1 >> rs2[4:0];
        `ALUOP_SRA:  rd = $signed(rs1) >>> rs2[4:0];
        `ALUOP_OR:   rd = rs1 | rs2;
        `ALUOP_AND:  rd = rs1 & rs2;
        default:     rd = 32'hEBADF00D;
    endcase
end

endmodule
