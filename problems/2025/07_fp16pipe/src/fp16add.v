module fp16add (
    input  wire [15:0] i_a,
    input  wire [15:0] i_b,
    output wire [15:0] o_res
);

localparam E_BIAS = 15;

// Normal: E!=0             => (-1)^S * (1+M) * 2^(E-B)
// Subnormal: E=0, M!=0     => (-1)^S * M
// Zero: {S=+/-, E=0, M=0}
// +-inf = {S=+/-, E=1..1, M=0}
// NaN   = {S=+/-, E=1..1, M!=0}
//
// FTZ(for res) + DAZ(for args): E=0, M!=0 => E=0, M=0

wire       a_s = i_a[15];
wire [4:0] a_e = i_a[14:10];
wire [9:0] a_m = (a_e == 5'd0) ? 10'd0 : i_a[9:0]; // Perform DAZ.
wire       b_s = i_b[15];
wire [4:0] b_e = i_b[14:10];
wire [9:0] b_m = (b_e == 5'd0) ? 10'd0 : i_b[9:0]; // Perform DAZ.
reg       res_s;
reg [4:0] res_e;
reg [9:0] res_m;
assign o_res = {res_s, res_e, res_m};

///////////////////////////////////////////////////////////////////////////////
// 1) Swap to make |x| > |y|.
///////////////////////////////////////////////////////////////////////////////
wire [5:0] e_diff = {1'b0, a_e} - {1'b0, b_e};
wire need_swap = e_diff[5] || (e_diff == 6'h0 && a_m < b_m);

wire [4:0] e_abs_diff = need_swap ? -e_diff[4:0] : e_diff[4:0];
wire       x_s = need_swap ? b_s : a_s;
wire [4:0] x_e = need_swap ? b_e : a_e;
wire [9:0] x_m = need_swap ? b_m : a_m;
wire       y_s = need_swap ? a_s : b_s;
wire [4:0] y_e = need_swap ? a_e : b_e;
wire [9:0] y_m = need_swap ? a_m : b_m;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 2) Sign-magnitude adder.
///////////////////////////////////////////////////////////////////////////////
wire oper = x_s ^ y_s;  // 0 => '+', 1 => '-'

reg [42:0] x_mshifted;
reg [42:0] y_mshifted;
reg [42:0] sum;
reg [5:0] e_sum;
reg       s_sum;

always @(*) begin
    // x   = 01MMMMMMMMMM00
    // y   = ___________01MMMMMMMMMM
    //       <- shift ->   <|sticky>
    // sum = hhXXXXXXXXXXxx
    //
    // shift can be (0-31).
    x_mshifted = {2'b01, x_m, 31'h0};
    y_mshifted = {2'b01, y_m, 31'h0} >> e_abs_diff;
    sum = (oper)
        ? x_mshifted - y_mshifted
        : x_mshifted + y_mshifted;

    e_sum = {1'b0, x_e};

    s_sum = x_s;
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 3) Normalize.
///////////////////////////////////////////////////////////////////////////////
reg   [3:0] norm_shift;
wire [42:0] norm_sum;

wire [9:0] m_norm;
wire [5:0] e_norm;
wire       guard_bit;
wire       round_bit;
wire       sticky_bit;

always @(*) begin
    // Leading one detector.
    //
    // NOTE: If |a| != |b|, leading one may appear only on 13 positions.
    // Worst case: subtract, shift=1 => one on 12-th position:
    // a   = 010000000000
    // b   = _011111111111
    // sum = 0000000000001MMMMMMMMMMgr
    //
    // subtract, shift=2 => one on 2-nd position:
    // a   = 010000000000
    // b   = __011111111111
    // sum = 00100000000001
    casez (sum[42:30])
        13'b1????????????: norm_shift = 4'd01;
        13'b01???????????: norm_shift = 4'd02;
        13'b001??????????: norm_shift = 4'd03;
        13'b0001?????????: norm_shift = 4'd04;
        13'b00001????????: norm_shift = 4'd05;
        13'b000001???????: norm_shift = 4'd06;
        13'b0000001??????: norm_shift = 4'd07;
        13'b00000001?????: norm_shift = 4'd08;
        13'b000000001????: norm_shift = 4'd09;
        13'b0000000001???: norm_shift = 4'd10;
        13'b00000000001??: norm_shift = 4'd11;
        13'b000000000001?: norm_shift = 4'd12;
        13'b0000000000001: norm_shift = 4'd13;
        default          : norm_shift = 4'd14;
    endcase
end

// If leading one is not detected result is zero.
assign e_norm = (norm_shift == 4'd14) ? 6'd0 : e_sum - {2'b0, norm_shift} + 6'd2;
assign norm_sum = sum << norm_shift;

assign {m_norm, guard_bit, round_bit} = norm_sum[42:31];
assign sticky_bit = |norm_sum[30:0];
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 4) Clamp.
///////////////////////////////////////////////////////////////////////////////
reg [9:0] m_clamped;
reg [5:0] e_clamped;
reg is_clamped;
always @(*) begin
    if (e_norm[5]) begin // Exponent underflow => zero.
        m_clamped = 10'h0;
        e_clamped = 6'h0;
        is_clamped = 1'b1;
    end
    else if (e_norm[4:0] == 5'b11111) begin // Exponent "overflow" => inf.
        m_clamped = 10'h0;
        e_clamped = 5'b11111;
        is_clamped = 1'b1;
    end
    else begin
        m_clamped = m_norm;
        e_clamped = e_norm;
        is_clamped = 1'b0;
    end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 5) RoundTiesToEven.
///////////////////////////////////////////////////////////////////////////////
reg [9:0] m_round;
reg [4:0] e_round;
always @(*) begin
    if (is_round_up && !is_clamped) begin
        m_round = m_clamped + 10'd1;
        if (m_round == 10'd0) begin
            // Mantissa overflowed, increment exponent.
            e_round = e_clamped[4:0] + 5'd1;
            // if (e_round == 5'b11111) we obtain {S, 1...1, 0} = +-inf, as it should be.
        end
        else begin
            e_round = e_clamped[4:0];
        end
    end
    else begin
        m_round = m_clamped;
        e_round = e_clamped[4:0];
    end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 6) Handle special cases and obtain final result.
// a=0                  => res = b
// b=0                  => res = a
// a=NaN || b=NaN       => res = NaN
// a=+-inf && b=+-inf   => res = +-inf
// a=+-inf && b=-+inf   => res = 0
// a=inf && b=normal    => res = inf
///////////////////////////////////////////////////////////////////////////////
always @(*) begin
    if (a_e == 5'h0) begin
        // a is zero (DAZ) => res = b.
        {res_s, res_e, res_m} = i_b;
    end
    else if (b_e == 5'h0) begin
        // b is zero (DAZ) => res = a.
        {res_s, res_e, res_m} = i_a;
    end
    else if ((a_e == 5'b11111 && a_m != 10'h0)
             || (b_e == 5'b11111 && b_m != 10'h0)) begin
        // One of opnds is NaN => NaN.
        res_s = 1'b0;
        res_e = 5'b11111;
        res_m = 10'h77;
    end
    else if ((a_e == 5'b11111 && a_m == 10'h0)
            && (b_e == 5'b11111 && b_m == 10'h0)) begin
        // Both opnds are inf => inf/0, depending on signs.
        res_s = a_s;
        res_e = (a_s ^ b_s) ? 5'b00000 : 5'b11111;
        res_m = 10'h0;
    end
    else if (a_e == 5'b11111 && a_m == 10'h0) begin
        // a=inf, b=normal => a.
        {res_s, res_e, res_m} = i_a;
    end
    else if (b_e == 5'b11111 && b_m == 10'h0) begin
        // a=normal, b=inf => b.
        {res_s, res_e, res_m} = i_b;
    end
    else begin
        // Both opnds are normal.
        res_s = s_sum;
        res_e = e_round;
        res_m = (e_round == 5'h0) ? 10'h0 : m_round; // Perform FTZ.
    end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// RoundTiesToEven details.
///////////////////////////////////////////////////////////////////////////////
reg is_round_up;
always @(*) begin
    // RoundTiesToEven scheme.
    casez ({guard_bit, round_bit, sticky_bit})
        3'b0??: begin
            is_round_up = 1'b0;
        end
        3'b100: begin
            // Tie: round up if bit-before-guard is 1, round down otherwise.
            is_round_up = m_norm[0];
        end
        3'b101,
        3'b110,
        3'b111: begin
            is_round_up = 1'b1;
        end
    endcase
end
///////////////////////////////////////////////////////////////////////////////

endmodule
