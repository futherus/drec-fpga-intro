module bin_display #(
    parameter CNT_WIDTH = 14
)(
   input  wire        clk,
   input  wire        rst_n,
   input  wire [15:0] i_data,
   output wire [3:0]  o_anodes,
   output reg  [7:0]  o_segments
);

reg [CNT_WIDTH-1:0] cnt;
wire          [1:0] pos = cnt[CNT_WIDTH-1:CNT_WIDTH-2];

reg [3:0] digit;

always @(*) begin
   case (pos)
      2'd0: digit = i_data[ 3: 0];
      2'd1: digit = i_data[ 7: 4];
      2'd2: digit = i_data[11: 8];
      2'd3: digit = i_data[15:12];
   endcase
end

always @(posedge clk or negedge rst_n)
   cnt <= !rst_n ? {CNT_WIDTH{1'b0}} : (cnt + 1'b1);

assign o_anodes = ~(4'b1 << pos);

/**
 *  /-A-\
 *  F   B
 *  +-G-+
 *  E   C
 *  \-D-/ DOT
 */
always @(*) begin
   case (digit)           // ABCDEFG DOT
       4'h0: o_segments = 8'b1111110_0;
       4'h1: o_segments = 8'b0110000_0;
       4'h2: o_segments = 8'b1101101_0;
       4'h3: o_segments = 8'b1111001_0;
       4'h4: o_segments = 8'b0110011_0;
       4'h5: o_segments = 8'b1011011_0;
       4'h6: o_segments = 8'b1011111_0;
       4'h7: o_segments = 8'b1110000_0;
       4'h8: o_segments = 8'b1111111_0;
       4'h9: o_segments = 8'b1111011_0;
       4'hA: o_segments = 8'b1110111_0;
       4'hB: o_segments = 8'b0011111_0;
       4'hC: o_segments = 8'b1001110_0;
       4'hD: o_segments = 8'b0111101_0;
       4'hE: o_segments = 8'b1001111_0;
       4'hF: o_segments = 8'b1000111_0;
   endcase
end

endmodule
