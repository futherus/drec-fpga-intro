`timescale 1ns/1ps

module testbench;

reg clk   = 1'b0;
reg rst_n = 1'b0;

always begin
    #1 clk <= ~clk;
end

reg [3:0] COUNTER_INIT = 3;
reg counter_is_initialized = 1'b0;
reg counter_enable = 1'b1;
reg count_down = 1'b0;
initial begin
    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    #6
    counter_is_initialized = 1'b1;
    #20
    counter_enable = 1'b0;
    #6
    counter_enable = 1'b1;
    #6
    count_down = 1'b1;
    #20
    counter_enable = 1'b0;
    #20
    $finish;
end

wire [3:0] value;
wire       carry;
dec_counter dec_counter(
    .clk(clk),
    .rst_n(rst_n),
    .i_init(COUNTER_INIT),
    .i_init_vld(!counter_is_initialized),
    .i_enable(counter_enable),
    .i_count_down(count_down),

    .o_value(value),
    .o_carry(carry)
);

initial begin
    $dumpvars;
    $display("Test started...");
    #1000 $finish;
end

endmodule
