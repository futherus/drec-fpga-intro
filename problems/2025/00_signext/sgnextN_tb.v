`timescale 1ns/1ps

module sgnextN_tb;

localparam N = 12;
localparam M = 32;

wire [M-1:0] y;
reg  [N-1:0] x = {N{1'b0}};

integer count;
reg signed [M-1:0] y_ref;

initial begin
    $dumpvars;
    $display("[%0t] Start", $realtime);

    for (count = -2048; count <= 2047; count++) begin
        x = count;
        y_ref = count;
        #1;

        if ( y == y_ref ) begin
            // $display("[%0t] x=%b y=%b OK", $realtime, x, y);
        end
        else begin
            $display("[%0t] x=%b y=%b FAIL", $realtime, x, y);
        end

        #1;
    end

    $display("[%0t] Done", $realtime);
    $finish;
end

sgnextN #(.N(N), .M(M)) sgnextN(.i_x(x), .o_y(y));

endmodule
