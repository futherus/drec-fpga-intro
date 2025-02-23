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

reg  [7:0] state = 8'b111_000_11;
reg        state_vld;
wire       out;

shiftreg shiftreg(.clk(clk), .rst_n(rst_n), .i_state(state), .i_state_vld(state_vld), .o_out(out));

initial begin
    $dumpvars;
    $display("Test started...");
    state_vld = 1'b0;
    #20
    state_vld = 1'b1;
    #2
    state_vld = 1'b0;
    #40
    $finish;
end

endmodule

