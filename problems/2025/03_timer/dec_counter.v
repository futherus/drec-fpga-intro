module dec_counter(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] i_init,
    input  wire       i_init_vld,
    input  wire       i_enable,
    input  wire       i_count_down,

    output reg  [3:0] o_value,
    output wire       o_carry
);

assign o_carry = i_enable
                 && (i_count_down ? (o_value == 4'd0) : (o_value == 4'd9));

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        o_value <= 0;
    end
    else if (i_init_vld) begin
        o_value <= i_init;
    end
    else if (i_enable) begin
        if (!i_count_down) begin
            if (o_value == 4'd9) begin
                o_value <= 4'd0;
            end
            else begin
                o_value <= o_value + 4'd1;
            end
        end
        else begin
            if (o_value == 4'd0) begin
                o_value <= 4'd9;
            end
            else begin
                o_value <= o_value - 4'd1;
            end
        end
    end
end



endmodule
