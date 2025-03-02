module bin_display #(
    parameter CNT_WIDTH = 14
)(
   input  wire        clk,
   input  wire        rst_n,
   input  wire [15:0] i_data,
   input  wire [3:0]  i_dots,
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
   o_segments[0] = i_dots[pos];
   case (digit)                // ABCDEFG
       4'h0: o_segments[7:1] = 7'b1111110;
       4'h1: o_segments[7:1] = 7'b0110000;
       4'h2: o_segments[7:1] = 7'b1101101;
       4'h3: o_segments[7:1] = 7'b1111001;
       4'h4: o_segments[7:1] = 7'b0110011;
       4'h5: o_segments[7:1] = 7'b1011011;
       4'h6: o_segments[7:1] = 7'b1011111;
       4'h7: o_segments[7:1] = 7'b1110000;
       4'h8: o_segments[7:1] = 7'b1111111;
       4'h9: o_segments[7:1] = 7'b1111011;
       4'hA: o_segments[7:1] = 7'b1110111;
       4'hB: o_segments[7:1] = 7'b0011111;
       4'hC: o_segments[7:1] = 7'b1001110;
       4'hD: o_segments[7:1] = 7'b0111101;
       4'hE: o_segments[7:1] = 7'b1001111;
       4'hF: o_segments[7:1] = 7'b1000111;
   endcase
end

endmodule
