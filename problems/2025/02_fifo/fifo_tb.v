`timescale 1ns/1ps

`include "assert.vh"

module testbench;

reg clk   = 1'b0;
reg rst_n = 1'b0;

always begin
    #1 clk <= ~clk;
end

initial begin
    repeat (3) @(posedge clk);
    rst_n <= 1'b1;
end

localparam DATAW = 8;
localparam SIZE  = 4;

reg  [DATAW-1:0] wr_data;
reg              wr_en;
wire             wr_full;
wire [DATAW-1:0] rd_data;
reg              rd_en;
wire             rd_empty;

fifo #(
    .DATAW(DATAW),
    .SIZE(SIZE)
) fifo(
    .clk(clk), .rst_n(rst_n),
    .i_wr_data(wr_data), .i_wr_en(wr_en), .o_wr_full(wr_full),
    .o_rd_data(rd_data), .i_rd_en(rd_en), .o_rd_empty(rd_empty)
);

initial begin
    $dumpvars;
    $display("Test started...");
    wr_en = 0;
    rd_en = 0;
    #20

    $display("Fill FIFO");
    wr_en = 1;
    wr_data = 15;
    #2
    wr_data = 16;
    #2
    wr_data = 17;
    #2
    wr_data = 18;
    #2
    $display("Check full");
    wr_en = 0;
    `assert(wr_full);

    #10
    $display("Read data");
    `assert(rd_data == 15);
    rd_en = 1;
    #2
    `assert(rd_data == 16);
    #2
    `assert(rd_data == 17);
    #2
    `assert(rd_data == 18);
    #2
    $display("Check empty");
    `assert(rd_empty);
    rd_en = 0;

    #20

    $display("Fill FIFO");
    wr_en = 1;
    wr_data = 115;
    #2
    wr_data = 116;
    #2
    wr_data = 117;
    #2
    wr_data = 118;
    #2
    $display("Check full");
    wr_en = 0;
    `assert(wr_full);

    #10
    $display("Read data");
    `assert(rd_data == 115);
    rd_en = 1;
    #2
    `assert(rd_data == 116);
    #2
    `assert(rd_data == 117);
    #2
    `assert(rd_data == 118);
    #2
    $display("Check empty");
    `assert(rd_empty);
    rd_en = 0;

    #20

    $finish;
end

endmodule

