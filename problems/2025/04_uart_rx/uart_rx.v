module uart_rx #(
    parameter FREQ = 50_000_000,
    parameter RATE =  2_000_000
) (
    input  wire clk,
    input  wire rst_n,

    input  wire       i_rx,
    output reg  [7:0] o_data,
    output reg        o_data_vld
);

// Enabling Counter
wire en;
// Shifting Register
reg [7:0] data;
// FSM
reg [3:0] state, next_state;

localparam [3:0] IDLE  = {1'b0, 3'd0},
                 START = {1'b0, 3'd1},
                 STOP  = {1'b0, 3'd2},
                 BIT0  = {1'b1, 3'd0},
                 BIT1  = {1'b1, 3'd1},
                 BIT2  = {1'b1, 3'd2},
                 BIT3  = {1'b1, 3'd3},
                 BIT4  = {1'b1, 3'd4},
                 BIT5  = {1'b1, 3'd5},
                 BIT6  = {1'b1, 3'd6},
                 BIT7  = {1'b1, 3'd7};

counter #(
    .CNT_WIDTH  ($clog2(FREQ/RATE)),
    // Load half period => en=1 in middle of every bit
    .CNT_LOAD   (FREQ/RATE/2      ),
    .CNT_MAX    (FREQ/RATE-1      )
) cnt (
    .clk        (clk        ),
    .rst_n      (rst_n      ),
    .i_load     (restart_cnt),
    .o_en       (en         )
);

always @(posedge clk) begin
    if (en) begin
        data <= {i_rx, data[7:1]};
    end
end

reg rx_d;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        rx_d <= 1'b0;
    end
    else begin
        state <= next_state;
        rx_d <= i_rx;
    end
end

wire rx_fall = !i_rx && rx_d;
wire restart_cnt = rx_fall && (state == IDLE);
// Go from IDLE to BIT0 if got start bit
always @(*) begin
    case (state)
        IDLE:    next_state = rx_fall       ? START : state;
        START:   next_state = !en ? state : (i_rx == 1'b0) ? BIT0 : IDLE;
        BIT0:    next_state = en            ? BIT1  : state;
        BIT1:    next_state = en            ? BIT2  : state;
        BIT2:    next_state = en            ? BIT3  : state;
        BIT3:    next_state = en            ? BIT4  : state;
        BIT4:    next_state = en            ? BIT5  : state;
        BIT5:    next_state = en            ? BIT6  : state;
        BIT6:    next_state = en            ? BIT7  : state;
        BIT7:    next_state = en            ? STOP  : state;
        STOP:    next_state = en            ? IDLE  : state;
        default: next_state = state;
    endcase
end

always @(*) begin
    if ((state == STOP) && en && (i_rx == 1'b1)) begin
        o_data = data;
        o_data_vld = 1'b1;
    end
    else begin
        o_data = 8'dX;
        o_data_vld = 1'b0;
    end
end

endmodule
