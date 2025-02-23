module shiftreg(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] i_state,
    input  wire       i_state_vld,
    output wire       o_out
);

reg [7:0] val;
assign o_out = val[7];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        val <= 8'b0000_0000;
    else if (i_state_vld)
        val <= i_state;
    else
        val <= {val[6:0], 1'b0};
end

endmodule
