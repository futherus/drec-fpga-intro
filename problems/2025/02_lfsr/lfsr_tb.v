`timescale 1ns/1ps

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

reg enable;
wire [7:0] value;

lfsr lfsr(.clk(clk), .rst_n(rst_n), .i_enable(enable), .o_value(value));

initial begin
    $dumpvars;
    $display("Test started...");
    enable = 1'b0;
    #20
    enable = 1'b1;
    #600
    enable = 1'b0;
    #20
    $finish;
end

endmodule

