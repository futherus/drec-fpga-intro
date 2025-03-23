`include "alu.vh"

module alu (
    input  wire [`ALUOP_WIDTH-1:0] i_op,
    input  wire [31:0]             i_a, i_b,
    output reg  [31:0]             o_res
);

always @(*) begin
    case (i_op)
        `ALUOP_ADD:  o_res = i_a + i_b;
        `ALUOP_SUB:  o_res = i_a - i_b;
        `ALUOP_SLL:  o_res = i_a << i_b[4:0];
        `ALUOP_SLT:  o_res = ($signed(i_a) < $signed(i_b));
        `ALUOP_SLTU: o_res = (i_a < i_b);
        `ALUOP_XOR:  o_res = i_a ^ i_b;
        `ALUOP_SRL:  o_res = i_a >> i_b[4:0];
        `ALUOP_SRA:  o_res = $signed(i_a) >>> i_b[4:0];
        `ALUOP_OR:   o_res = i_a | i_b;
        `ALUOP_AND:  o_res = i_a & i_b;
        default:     o_res = 32'dX;
    endcase
end

endmodule
