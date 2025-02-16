`include "cmp_unit.vh"

module cmp_unit (
    input  wire [`CMPOP_WIDTH-1:0] op,
    input  wire [31:0]             i_a, i_b,
    output reg                     out
);

always @(*) begin
    case (op)
        `CMPOP_BEQ:  out = (i_a == i_b);
        `CMPOP_BNE:  out = (i_a != i_b);
        `CMPOP_BLT:  out = ($signed(i_a) < $signed(i_b));
        `CMPOP_BGE:  out = ($signed(i_a) >= $signed(i_b));
        `CMPOP_BLTU: out = (i_a < i_b);
        `CMPOP_BGEU: out = (i_a >= i_b);
        default:     out = 1'b0;
    endcase
end

endmodule
