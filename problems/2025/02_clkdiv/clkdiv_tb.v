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

wire clkdiv9600_out;
wire clkdiv38400_out;
wire clkdiv115200_out;

clkdiv #(
    .FBASE(50_000_000),
    .FOUT(9_600)
) clkdiv9600(.clk(clk), .rst_n(rst_n), .out(clkdiv9600_out));

clkdiv #(
    .FBASE(50_000_000),
    .FOUT(38_400)
) clkdiv38400(.clk(clk), .rst_n(rst_n), .out(clkdiv38400_out));

clkdiv #(
    .FBASE(50_000_000),
    .FOUT(115_200)
) clkdiv115200(.clk(clk), .rst_n(rst_n), .out(clkdiv115200_out));

initial begin
    $dumpvars;
    $display("Test started...");
    #20000 $finish;
end

endmodule

