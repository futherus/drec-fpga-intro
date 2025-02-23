module lfsr(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       i_enable,
    output wire [7:0] o_value
);

reg [7:0] val;
assign o_value = val;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        val <= 8'b0000_0001;
    else if (i_enable)
        // x^8 + x^6 + x^5 + x^4 + 1
        val <= {val[6:0], val[7] ^ val[5] ^ val[4] ^ val[3]};
end

endmodule
