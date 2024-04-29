`timescale 1 ns / 100 ps

module testbench;

reg clk = 1'b0;

always begin
    #1 clk = ~clk;
end

localparam DATA_SIZE = 5;

reg [DATA_SIZE-1:0]tx_data = 0;
reg tx_start = 0;
wire tx_output;
uart_tx #(
    .FREQ(100),
    .BAUD(25),
    .DATA_SIZE(DATA_SIZE)
) uart_tx (
    .clk(clk),
    .start(tx_start),
    .data(tx_data),
    .out(tx_out)
);

wire [DATA_SIZE-1:0]rx_data;
wire rx_is_receiving;
wire rx_is_completed;
uart_rx #(
    .FREQ(100),
    .BAUD(25),
    .DATA_SIZE(DATA_SIZE)
) uart_rx (
    .clk(clk),
    .in(tx_out),
    .data(rx_data),
    .is_receiving(rx_is_receiving),
    .is_completed(rx_is_completed)
);

initial begin
    $dumpvars;
    #2
//    tx_data = 8'h55;
    tx_data = 8'hD;
    tx_start = 1'b1;
    #2
    tx_data = 0;
    tx_start = 0;
    #96
    tx_data = 8'h0;
    tx_start = 1'b1;

    #200 $finish;
end

endmodule
