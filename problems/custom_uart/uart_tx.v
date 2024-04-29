module uart_tx #(
    parameter FREQ = 1e9,
    parameter BAUD = 115200,
    parameter DATA_SIZE = 8
)(
    input clk,
    input start,
    input [DATA_SIZE-1:0]data,

    output reg out
);

localparam TX_IDLE = 0;
localparam TX_SEND = 1;
localparam TX_STOP = 2;

initial begin
    out = 1;
end

// 0 -- reset enabled, 1 -- disabled.
reg reset = 1'b0;
reg [3:0] state = TX_IDLE;

// TX strobe
wire tx_strobe;
clk_strobe #(.DIVISOR(FREQ/BAUD)) clk_strobe(
    .clk(clk),
    .reset(reset),
    .strobe(tx_strobe)
);

reg [DATA_SIZE-1:0]buffer = 0;
reg [7:0]current_bit = 0;
always @(posedge clk) begin
    case (state)
        TX_IDLE:
            if (start) begin
                state <= TX_SEND;
                reset <= 1'b1;          // disable reset
                buffer <= data;         // buffer data for sending
                current_bit <= 0;       // reset counter
                out <= 1'b0;            // output start bit
            end
        TX_SEND:
            if (tx_strobe) begin
                if (current_bit != DATA_SIZE) begin
                    out <= buffer[0];                               // send data bit
                    buffer <= {1'b0, buffer[DATA_SIZE-1:1]};        // shift data in buffer
                    current_bit <= current_bit + 1;
                end
                else begin
                    out <= 1'b1;                        // output stop bit
                    state <= TX_STOP;
                end
            end
        // NOTE: Losing one clk cycle if sending is continous (transition
        //       TX_STOP -> TX_IDLE -> TX_SEND).
        //       1) If this module will use some output reg to show ready for
        //       next sending, it will be ok.
        //       2) Otherwise can be fixed with direct transition TX_STOP ->
        //       TX_SEND.
        TX_STOP:
            if (tx_strobe) begin
                state <= TX_IDLE;
                reset <= 1'b0;          // enable reset
            end
    endcase
end

endmodule
