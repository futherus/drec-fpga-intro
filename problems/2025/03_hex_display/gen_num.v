module gen_num(
    input wire clk,
    input wire rst_n,

    output reg [15:0] o_value
);

localparam DELAY = 20_000_000;
reg [31:0] delay_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        delay_cnt <= 16'd0;
        o_value <= 16'd0;
    end
    else begin
        if (delay_cnt == DELAY) begin
            delay_cnt <= 16'd0;
            o_value <= o_value + 16'd1;
        end
        else begin
            delay_cnt <= delay_cnt + 16'd1;
        end
    end
end

endmodule

