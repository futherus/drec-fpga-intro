`timescale 1ns/1ps

module fp16pipe_tb;

reg clk = 1'b1;
reg rst_n = 1'b0;

always begin
    #0.5 clk <= ~clk;
end

wire [15:0] a, b, z;
wire [15:0] c_d;
reg  [15:0] a_d, b_d, z_d;

wire       z_sign = z_d[15];
wire [4:0] z_bexp = z_d[14:10];
wire [9:0] z_mant = z_d[9:0];

wire       c_sign = c_d[15];
wire [4:0] c_bexp = c_d[14:10];
wire [9:0] c_mant = c_d[9:0];

fp16pipe`TEST_OP fp16pipe`TEST_OP (
    .clk      (clk),
    .rst_n    (rst_n),
    .i_a      (a),
    .i_b      (b),
    .o_res    (c_d)
);

reg [3*16-1:0] test[`TEST_SIZE];
reg [$clog2(`TEST_SIZE):0] idx = 0;

reg ok, pass = 1;

assign {a, b, z} = test[idx];

initial begin
    $readmemh("test.txt", test);
end

wire signed [14:0] diff = $signed(c_d[14:0]) - $signed(z_d[14:0]);

always @(*) begin
    if (z_bexp == 5'h0) // Zero/denormal
        ok = (c_bexp == 5'h00) && (c_mant == 10'h0) && (c_sign == z_sign);
    else if (z_bexp == 5'h1F && z_mant == 10'h0) // Inf
        ok = (c_bexp == 5'h1F) && (c_mant == 10'h0) && (c_sign == z_sign);
    else if (z_bexp == 5'h1F && z_mant != 10'h0) // NaN
        ok = (c_bexp == 5'h1F) && (c_mant != 10'h0) && (c_sign == z_sign);
    else
        ok = ($abs(diff) == 15'd0) && (c_sign == z_sign);
end

always @(posedge clk) begin
    if (!rst_n) begin
        idx <= 0;
        a_d <= 0;
        b_d <= 0;
        z_d <= 0;
    end
    else begin
        idx <= idx + 1;
        a_d <= a;
        b_d <= b;
        z_d <= z;
        if (`DEBUG || !ok) begin
            $display("[%d] %h %h -> %h z=%h ok=%d", idx-1, a_d, b_d, c_d, z_d, ok);
        end
        pass <= ok ? pass : 0;
        // To check last test we overflow idx.
        if (idx == `TEST_SIZE) begin
            $display("Result: %s", pass ? "PASS" : "FAIL");
            $finish;
        end
    end
end

initial begin
    $dumpvars;
    $display("Test size: %d", `TEST_SIZE);
    #10
    rst_n = 1'b1;
end

endmodule
