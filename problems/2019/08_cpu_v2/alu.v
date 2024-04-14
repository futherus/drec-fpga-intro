module alu(
    input [31:0]src_a,
    input [31:0]src_b,
    input [2:0]op,
    output reg [31:0]res
);

always @(*) begin
    $display("%4d D> Alu: op: %h, src_a: %h, src_b: %h", $time, op, src_a, src_b);
    case (op)
        3'b000: res = src_a;
        3'b001: res = src_a + src_b;
        3'b010: res = src_a * src_b;
        3'b100: res = src_a ^ src_b;
        3'b110: res = src_a | src_b;
        3'b111: res = src_a & src_b;
        default: res = 0;
    endcase
end

endmodule
