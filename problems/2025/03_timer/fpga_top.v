module fpga_top(
    input  wire CLK,   // CLOCK
    input  wire RSTN,  // BUTTON RST (NEGATIVE)
    output wire STCP,
    output wire SHCP,
    output wire DS,
    output wire OE
);

localparam FOUT = 10; // Hz
localparam COUNTER_WIDTH = 4;
reg [15:0] COUNTER_INIT = {4'd0, 4'd6, 4'd0, 4'd0};
reg [3:0]  DOTS = 4'b0010;

reg rst_n, RSTN_d;

// Synchronizer chain for reset
always @(posedge CLK) begin
    rst_n <= RSTN_d;
    RSTN_d <= RSTN;
end

// Initialization of counter
reg counter_is_initialized;
always @(posedge CLK or negedge rst_n) begin
    if (!rst_n) begin
        counter_is_initialized <= 0;
    end
    else begin
        if (!counter_is_initialized) begin
            counter_is_initialized <= 1;
        end
        else if (value == 16'b0) begin
            counter_is_initialized <= 0;
        end
    end
end

// Iterate counter with low frequency
wire counter_enable;
clkdiv #(
    .FOUT(FOUT)
) clkdiv(
    .clk(CLK),
    .rst_n(rst_n),
    .out(counter_enable)
);

// Wide decimal counter
wire [COUNTER_WIDTH-1:0] carry_bus;
wire [COUNTER_WIDTH-1:0] enable_bus;
genvar i;
generate
    for (i = 0; i < COUNTER_WIDTH; i = i + 1) begin : gen_buses
        if (i == 0)
            assign enable_bus[i] = counter_enable;
        else
            assign enable_bus[i] = counter_enable && carry_bus[i-1];
    end
endgenerate
generate
    for (i = 0; i < COUNTER_WIDTH; i = i + 1) begin : gen_counters
        dec_counter dec_counter(
            .clk(CLK),
            .rst_n(rst_n),
            .i_init(COUNTER_INIT[4*i+3:4*i]),
            .i_init_vld(!counter_is_initialized),
            .i_enable(enable_bus[i]),
            .i_count_down(1'b1),

            .o_value(value[4*i+3:4*i]),
            .o_carry(carry_bus[i])
        );
    end
endgenerate

wire   [3:0] anodes;
wire   [7:0] segments;
wire  [15:0] value;

bin_display bin_display(CLK, rst_n, value, DOTS, anodes, segments);

ctrl_74hc595 ctrl(
    .clk    (CLK                ),
    .rst_n  (rst_n              ),
    .i_data ({segments, anodes} ),
    .o_stcp (STCP               ),
    .o_shcp (SHCP               ),
    .o_ds   (DS                 ),
    .o_oe   (OE                 )
);

endmodule
