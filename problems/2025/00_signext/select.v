module select #(
    parameter SEL = 0
)(
    input  wire i_first,
    input  wire i_second,
    output wire o_val
);

assign o_val = (SEL == 0) ? i_first : i_second;

endmodule
