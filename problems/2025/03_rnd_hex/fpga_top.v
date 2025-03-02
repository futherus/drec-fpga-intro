module fpga_top(
    input  wire CLK,   // CLOCK
    input  wire RSTN,  // BUTTON RST (NEGATIVE)
    output wire STCP,
    output wire SHCP,
    output wire DS,
    output wire OE
);

reg rst_n, RSTN_d;

// Synchronizer chain for reset
always @(posedge CLK) begin
    rst_n <= RSTN_d;
    RSTN_d <= RSTN;
end

// Initialization of LFSR
localparam LFSR_INIT = 16'h1;
reg lfsr_is_initialized;
always @(posedge CLK or negedge rst_n) begin
    if (!rst_n) begin
        lfsr_is_initialized <= 0;
    end
    else begin
        if (~lfsr_is_initialized) begin
            lfsr_is_initialized <= 1;
        end
    end
end

// Iterate LFSR with low frequency
wire lfsr_enable;
clkdiv #(
    .FOUT(2)
) clkdiv(
    .clk(CLK),
    .rst_n(rst_n),
    .out(lfsr_enable)
);

wire   [3:0] anodes;
wire   [7:0] segments;
wire  [15:0] value;

lfsr lfsr(
    .clk(CLK),
    .rst_n(rst_n),
    .i_init(LFSR_INIT),
    .i_init_vld(~lfsr_is_initialized),
    .i_enable(lfsr_enable),
    .o_value(value)
);

bin_display bin_display(CLK, rst_n, value, anodes, segments);

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
