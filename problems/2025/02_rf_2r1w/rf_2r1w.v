module rf_2r1w(
    input  wire         clk,

    input  wire  [4:0]  i_rd_addr1,
    output wire  [31:0] o_rd_data1,

    input  wire  [4:0]  i_rd_addr2,
    output wire  [31:0] o_rd_data2,

    input  wire  [4:0]  i_wr_addr,
    input  wire  [31:0] i_wr_data,
    input  wire         i_wr_en
);

reg [31:0] r[31:0];

assign o_rd_data1 = r[i_rd_addr1];
assign o_rd_data2 = r[i_rd_addr2];

always @(posedge clk) begin
    if (i_wr_en) begin
        r[i_wr_addr] <= i_wr_data;
    end
end

endmodule
