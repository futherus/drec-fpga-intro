/**
 *  Generates strobe for clk/DIVISOR.
 */
module clk_strobe #(parameter DIVISOR = 4)(
    input clk,
    input reset,

    output strobe
);

reg [31:0]counter = 0;
assign strobe = (counter == DIVISOR - 1);

always @(posedge clk) begin
    if (!reset || counter == DIVISOR - 1)
        counter <= 0;
    else
        counter <= counter + 1;
end

endmodule
