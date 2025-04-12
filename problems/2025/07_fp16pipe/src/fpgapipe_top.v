module fpgapipe_top(
   input  wire CLK,
   input  wire RSTN,
   input  wire [15:0] i_a,
   input  wire [15:0] i_b,
   output reg  [15:0] o_res
);

reg  [15:0] a, b;
wire [15:0] res;

always @(posedge CLK) begin
   if (!RSTN) begin
      o_res <= 16'h0;
      a     <= 16'h0;
      b     <= 16'h0;
   end
   else begin
      o_res <= res;
      a     <= i_a;
      b     <= i_b;
   end
end

fp16pipeadd u_fp16pipeadd(
   .clk      (CLK),
   .rst_n    (RSTN),
   .i_a      (a),
   .i_b      (b),
   .o_res    (res)
);

endmodule
