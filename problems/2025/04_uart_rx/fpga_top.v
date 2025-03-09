module fpga_top(
    input  wire CLK,
    input  wire RSTN,

    input  wire RXD,
    output wire TXD,
    output wire [11:0] LED
);

localparam RATE = 2_000_000;

assign LED[0] = RXD;
assign LED[4] = TXD;
assign {LED[11:5], LED[3:1]}  = ~10'b0;

// RSTN synchronizer
reg rst_n, RSTN_d;
always @(posedge CLK) begin
    rst_n <= RSTN_d;
    RSTN_d <= RSTN;
end

// RXD synchronizer
reg i_rx, RXD_d;
always @(posedge CLK) begin
    i_rx <= RXD_d;
    RXD_d <= RXD;
end

wire [7:0] data;
wire       data_vld;

uart_rx #(
    .FREQ       (50_000_000),
    .RATE       (      RATE)
) u_uart_rx (
    .clk        (CLK       ),
    .rst_n      (rst_n     ),
    .i_rx       (i_rx      ),
    .o_data     (data      ),
    .o_data_vld (data_vld  )
);

uart_tx #(
    .FREQ       (50_000_000),
    .RATE       (      RATE)
) u_uart_tx (
    .clk        (CLK       ),
    .rst_n      (rst_n     ),
    .i_data     (data+1'b1 ),
    .i_vld      (data_vld  ),
    .o_tx       (TXD       )
);

endmodule
