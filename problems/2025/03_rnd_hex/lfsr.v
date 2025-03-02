module lfsr(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] i_init,
    input  wire        i_init_vld,
    input  wire        i_enable,
    output wire [15:0] o_value
);

reg [15:0] val;
assign o_value = val;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        val <= 0;
    end
    else if (i_init_vld) begin
        val <= i_init;
    end
    else if (i_enable) begin
        // x^16 + x^14 + x^13 + x^11 + 1
        val <= {val[14:0], val[15] ^ val[13] ^ val[12] ^ val[10]};
    end
end

endmodule
