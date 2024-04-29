module uart_rx #(
    parameter FREQ = 1e9,
    parameter BAUD = 115200,
    parameter DATA_SIZE = 8
)(
    input clk,
    input in,

    output reg [DATA_SIZE-1:0]data,
    output reg is_receiving,
    output reg is_completed
);

localparam S_IDLE = 0;
localparam S_RECV = 1;
localparam S_STOP = 2;

initial begin
    data = 0;
    is_receiving = 0;
    is_completed = 0;
end

// 0 -- reset enabled, 1 -- disabled.
reg reset = 1'b0;
reg [3:0] state = S_IDLE;

// RX strobe
wire strobe;
clk_strobe #(.DIVISOR(FREQ/BAUD)) clk_strobe(
    .clk(clk),
    .reset(reset),
    .strobe(strobe)
);

reg [7:0]current_bit = 0;
always @(posedge clk) begin
    case (state)
        S_IDLE:
            if (in == 0) begin
                state <= S_RECV;
                is_receiving <= 1;
                is_completed <= 0;
                reset <= 1'b1;          // disable reset
                data <= 0;              // reset output data
                current_bit <= 0;       // reset counter
            end
        S_RECV:
            if (strobe) begin
                if (current_bit != DATA_SIZE) begin
                    // FIXME: Maybe we should buffer received data to increase
                    //        time to read output data when is_completed == 1.
                    data[current_bit] <= in;          // receive bit
                    current_bit <= current_bit + 1;
                end
                else begin
                    state <= S_STOP;
                    is_completed <= 1;
                end
            end
        S_STOP:
            if (strobe) begin
                state <= S_IDLE;
                is_receiving <= 0;
                reset <= 0;
            end
    endcase
end

endmodule
