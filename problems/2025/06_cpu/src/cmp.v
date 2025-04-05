`include "cmp.vh"

module cmp(
    input  wire [`CMPOP_WIDTH-1:0] i_op,
    input  wire [31:0]             i_a, i_b,
    output reg                     o_res
);

always @(*) begin
    case (i_op)
        `CMPOP_BEQ:  o_res = (i_a == i_b);
        `CMPOP_BNE:  o_res = (i_a != i_b);
        `CMPOP_BLT:  o_res = ($signed(i_a) < $signed(i_b));
        `CMPOP_BGE:  o_res = ($signed(i_a) >= $signed(i_b));
        `CMPOP_BLTU: o_res = (i_a < i_b);
        `CMPOP_BGEU: o_res = (i_a >= i_b);
        default:     o_res = 1'b0;
    endcase
end

endmodule
