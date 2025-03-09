`timescale 1ns/1ps

module tb;

reg clk   = 1'b0;
reg rst_n = 1'b0;

always begin
    #1 clk <= ~clk;
end

initial begin
    repeat (3) @(posedge clk);
    rst_n <= 1'b1;
end

reg  i_vld = 1'b0;
reg  [7:0] i_data;
wire tx2rx;
wire [7:0] o_data;
wire       o_data_vld;

uart_tx #(
    .FREQ(1_000_000),
    .RATE(  115_200)
) uart_tx (
    .clk        (clk    ),
    .rst_n      (rst_n  ),
    .i_data     (i_data ),
    .i_vld      (i_vld  ),
    .o_tx       (tx2rx  )
);

uart_rx #(
    .FREQ(1_000_000),
    .RATE(  115_200)
) uart_rx (
    .clk        (clk         ),
    .rst_n      (rst_n       ),
    .i_rx       (tx2rx       ),
    .o_data     (o_data      ),
    .o_data_vld (o_data_vld  )
);

initial begin
    repeat (100) @(posedge clk);
    i_data <= 7'h6A;
    i_vld  <= 1'b1;
    @(posedge clk);
    i_data <= 7'hXX;
    i_vld  <= 1'b0;
end

initial begin
    $dumpvars;
    #1000 $finish;
end

endmodule
