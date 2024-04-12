module mem_ctrl(
    input clk,
    input [31:0]addr,
    input [31:0]data,
    input we,

    output reg [15:0]data_out = 16'b0
);

always @(posedge clk) begin
//     $strobe("%4d S> [%h] <- %h, we: %d\n    FIB: %d", $time, addr, data, we, data);
    if (we) begin
        $display("%4d D> [%h] <- %h, we: %d\n    FIB: %h", $time, addr, data, we, data);
        if (addr == 32'h20)
            data_out <= data[15:0];
    end
end

endmodule
