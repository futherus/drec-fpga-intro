`include "lsu.vh"

module lsu(
    input  wire clk,
    input  wire rst_n,

    input  wire                    i_is_store,
    input  wire [`LSUOP_WIDTH-1:0] i_op,
    input  wire             [31:0] i_addr,
    input  wire             [31:0] i_store_data,
    output reg              [31:0] o_load_data,

    output wire        o_is_store,
    output wire [29:0] o_addr,
    output wire [31:0] o_store_data,
    output wire  [3:0] o_store_mask,
    input  wire [31:0] i_load_data
);

assign o_is_store = i_is_store;
// FIXME: Unaligned load/store are supported by ISA.
assign o_addr = i_addr[31:2];

wire             [1:0] load_shift = i_addr[1:0];
reg              [1:0] load_shift_d;
reg [`LSUOP_WIDTH-1:0] op_d;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        op_d         <= `LSUOP_WIDTH'h0;
        load_shift_d <= 2'd0;
    end
    else begin
        op_d         <= i_op;
        load_shift_d <= load_shift;
    end
end

// Prepare store.
reg [3:0] store_mask;
always @(*) begin
    casez (i_op)
        `LSUOP_B: store_mask = 4'b0001;
        `LSUOP_H: store_mask = 4'b0011;
        `LSUOP_W: store_mask = 4'b1111;
        default : store_mask = 4'hX;
    endcase
end
assign o_store_mask = store_mask   << load_shift;
assign o_store_data = i_store_data << load_shift;

// Process load.
wire [31:0] d = i_load_data >> load_shift_d;
always @(*) begin
    casez (op_d)
        `LSUOP_B : o_load_data = {{24{d[ 7]}}, d[ 7:0]};
        `LSUOP_H : o_load_data = {{16{d[15]}}, d[15:0]};
        `LSUOP_W : o_load_data = d;
        `LSUOP_BU: o_load_data = {24'd0, d[ 7:0]};
        `LSUOP_HU: o_load_data = {16'd0, d[15:0]};
        default  : o_load_data = 31'hX;
    endcase
end

endmodule
