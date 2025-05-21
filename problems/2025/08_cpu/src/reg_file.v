module reg_file(
    input  wire         clk,

    input  wire  [4:0]  i_rd_addr1,
    output reg   [31:0] o_rd_data1,

    input  wire  [4:0]  i_rd_addr2,
    output reg   [31:0] o_rd_data2,

    input  wire  [4:0]  i_wr_addr,
    input  wire  [31:0] i_wr_data,
    input  wire         i_wr_en
);

// x0 is always-zero, so doesn't require register
reg [31:0] r[30:0];

always @(*) begin
    if (i_rd_addr1 == 5'd0) begin
        o_rd_data1 = 32'h0;
    end
    else if (i_wr_en && i_rd_addr1 == i_wr_addr) begin
        o_rd_data1 = i_wr_data;
    end
    else begin
        o_rd_data1 = r[i_rd_addr1-5'd1];
    end
end

always @(*) begin
    if (i_rd_addr2 == 5'd0) begin
        o_rd_data2 = 32'h0;
    end
    else if (i_wr_en && i_rd_addr2 == i_wr_addr) begin
        o_rd_data2 = i_wr_data;
    end
    else begin
        o_rd_data2 = r[i_rd_addr2-5'd1];
    end
end

always @(posedge clk) begin
    if (i_wr_en && i_wr_addr != 5'd0) begin
        r[i_wr_addr-5'd1] <= i_wr_data;
    end
end

endmodule
