`define BEHAVIORAL

`ifdef BEHAVIORAL
module sgnextN #(
    parameter N = 8,
    parameter M = 32
)(
    input  wire [N-1:0] i_x,
    output wire [M-1:0] o_y
);

assign o_y = { {M-N{i_x[N-1]}}, i_x };

endmodule

`else

module sgnextN #(
    parameter N = 8,
    parameter M = 32
)(
    input  wire [N-1:0] i_x,
    output wire [M-1:0] o_y
);

generate
genvar i;
for (i = 0; i < M; i = i + 1) begin
	select #(.SEL(i >= N)) select(.i_first(i_x[i]), .i_second(i_x[N-1]), .o_val(o_y[i]));
end
endgenerate

endmodule

`endif
