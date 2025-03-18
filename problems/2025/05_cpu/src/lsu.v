module lsu(
    input  wire        i_is_store,
    input  wire [31:0] i_addr,
    input  wire [31:0] i_store_data,
    input  wire  [3:0] i_store_mask,
    output wire [31:0] o_load_data,

    output wire        o_is_store,
    output wire [29:0] o_addr,
    output wire [31:0] o_store_data,
    output wire  [3:0] o_store_mask,
    input  wire [31:0] i_load_data
);

assign o_is_store   = i_is_store;
assign o_load_data  = i_load_data;
assign o_store_data = i_store_data;
assign o_store_mask = i_store_mask;
// FIXME: Unaligned load/store are supported by ISA.
assign o_addr       = i_addr[31:2];

endmodule
