`timescale 1ns/1ps

module mux4_tb;

localparam N = 8;

reg  [1:0] sel;
wire [N-1:0] out;

initial begin
    $dumpvars;
    $display("[%0t] Start", $realtime);

    sel = 2'b00;
    #10;

    sel = 2'b01;
    #10;

    sel = 2'b10;
    #10;

    sel = 2'b11;
    #10;

    $display("[%0t] Done", $realtime);
    $finish;
end

mux4 #(.WIDTH(N)) dut(.i_0(8'd10), .i_1(8'd11), .i_2(8'd12), .i_3(8'd13),
                      .i_sel(sel), .out(out));

endmodule
