module mux4 #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] i_0, i_1, i_2, i_3,
    input  wire       [1:0] i_sel,
    output reg  [WIDTH-1:0] out
);

always @(*) begin
    case (i_sel)
        2'b00: out = i_0;
        2'b01: out = i_1;
        2'b10: out = i_2;
        2'b11: out = i_3;
    endcase
end

endmodule
