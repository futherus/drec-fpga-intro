`include "assert.vh"

module fifo #(
    parameter DATAW = 8,
    parameter SIZE  = 4  // WARNING: SIZE should be a power of 2.
)(
    input  wire clk,
    input  wire rst_n,

    input  wire [DATAW-1:0] i_wr_data,
    input  wire             i_wr_en,
    output wire             o_wr_full,

    output wire [DATAW-1:0] o_rd_data,
    input  wire             i_rd_en,
    output wire             o_rd_empty
);

localparam ADDRW = $clog2(SIZE);

reg [DATAW-1:0] mem[SIZE-1:0];

reg  [ADDRW:0] rd_ptr;
reg  [ADDRW:0] wr_ptr;
wire [ADDRW-1:0] rd_addr;
wire [ADDRW-1:0] wr_addr;
assign rd_addr = rd_ptr[ADDRW-1:0];
assign wr_addr = wr_ptr[ADDRW-1:0];

assign o_rd_data = mem[rd_addr];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_ptr <= {ADDRW{1'b0}};
        wr_ptr <= {ADDRW{1'b0}};
    end
    else begin
        if (i_wr_en) begin
            `assert(!o_wr_full);
            mem[wr_addr] <= i_wr_data;
            wr_ptr <= wr_ptr + 1;
        end

        if (i_rd_en) begin
            `assert(!o_rd_empty);
            rd_ptr <= rd_ptr + 1;
        end
    end
end

assign o_rd_empty = (rd_addr == wr_addr) && (rd_ptr[ADDRW] == wr_ptr[ADDRW]);
assign o_wr_full  = (rd_addr == wr_addr) && (rd_ptr[ADDRW] != wr_ptr[ADDRW]);

endmodule
