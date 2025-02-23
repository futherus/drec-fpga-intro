module clkdiv #(
    parameter FBASE = 50_000_000,
    parameter FOUT = 12_500_000
)(
    input  clk,
    input  rst_n,
    output out
);

localparam CNT_WIDTH = $clog2(FBASE / FOUT);

reg [CNT_WIDTH-1:0] cnt;

assign out = (cnt == 0);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt <= {CNT_WIDTH{1'b0}};
    else
        cnt <= (cnt == FBASE/FOUT) ? {CNT_WIDTH{1'b0}} : cnt + 1;
end

endmodule
