module mmio_xbar(
    input  wire [29:0] i_mmio_addr,
    input  wire [31:0] i_mmio_data,
    input  wire  [3:0] i_mmio_mask,
    input  wire        i_mmio_wren,
    output wire [31:0] o_mmio_data,

    output reg  [15:0] o_hexd_data,
    output reg         o_hexd_wren
);

assign o_mmio_data = 32'hX;

always @(*) begin

    if (i_mmio_addr == `XBAR_HEXD_ADDR0 && i_mmio_mask == 4'b1111) begin
        o_hexd_data = i_mmio_data[15:0];
        o_hexd_wren = i_mmio_wren;
    end
    else begin
        o_hexd_data = 16'dX;
        o_hexd_wren = 1'b0;
    end
end

endmodule


