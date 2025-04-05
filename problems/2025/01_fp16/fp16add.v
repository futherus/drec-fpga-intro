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

wire [4:0] e_abs_diff = need_swap ? -e_diff : e_diff;
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
reg [42:0] m_sum;
reg [5:0] e_sum;
reg       s_sum;

reg guard_bit;
reg round_bit;
reg sticky_bit;

reg [9:0] m_norm;
reg [5:0] e_norm;
always @(*) begin
    // x   = 01MMMMMMMMMM00
    // y   = ___________01MMMMMMMMMM
    //       <- shift ->   <|sticky>
    // sum = hhXXXXXXXXXXxx
    //
    // shift can be (0-31).
    x_mshifted = {2'b01, x_m, 31'h0};
    y_mshifted = {2'b01, y_m, 31'h0} >> e_abs_diff[4:0];
    m_sum = (oper)
        ? x_mshifted - y_mshifted
        : x_mshifted + y_mshifted;

    e_sum = {1'b0, x_e};

    s_sum = x_s;

    // Normalize.
    casez (m_sum[42:30])
        13'b1????????????: begin
            e_norm = e_sum + 6'd1;
            {m_norm, guard_bit, round_bit} = m_sum[41:30];
            sticky_bit = |m_sum[29:0];
        end
        13'b01???????????: begin
            e_norm = e_sum;
            {m_norm, guard_bit, round_bit} = m_sum[40:29];
            sticky_bit = |m_sum[28:0];
        end
        13'b001??????????: begin
            e_norm = e_sum - 6'd1;
            {m_norm, guard_bit, round_bit} = m_sum[39:28];
            sticky_bit = |m_sum[27:0];
        end
        13'b0001?????????: begin
            e_norm = e_sum - 6'd2;
            {m_norm, guard_bit, round_bit} = m_sum[38:27];
            sticky_bit = |m_sum[26:0];
        end
        13'b00001????????: begin
            e_norm = e_sum - 6'd3;
            {m_norm, guard_bit, round_bit} = m_sum[37:26];
            sticky_bit = |m_sum[25:0];
        end
        13'b000001???????: begin
            e_norm = e_sum - 6'd4;
            {m_norm, guard_bit, round_bit} = m_sum[36:25];
            sticky_bit = |m_sum[24:0];
        end
        13'b0000001??????: begin
            e_norm = e_sum - 6'd5;
            {m_norm, guard_bit, round_bit} = m_sum[35:24];
            sticky_bit = |m_sum[23:0];
        end
        13'b00000001?????: begin
            e_norm = e_sum - 6'd6;
            {m_norm, guard_bit, round_bit} = m_sum[34:23];
            sticky_bit = |m_sum[22:0];
        end
        13'b000000001????: begin
            e_norm = e_sum - 6'd7;
            {m_norm, guard_bit, round_bit} = m_sum[33:22];
            sticky_bit = |m_sum[21:0];
        end
        13'b0000000001???: begin
            e_norm = e_sum - 6'd8;
            {m_norm, guard_bit, round_bit} = m_sum[32:21];
            sticky_bit = |m_sum[20:0];
        end
        13'b00000000001??: begin
            e_norm = e_sum - 6'd9;
            {m_norm, guard_bit, round_bit} = m_sum[31:20];
            sticky_bit = |m_sum[19:0];
        end
        13'b000000000001?: begin
            e_norm = e_sum - 6'd10;
            {m_norm, guard_bit, round_bit} = m_sum[30:19];
            sticky_bit = |m_sum[18:0];
        end
        13'b0000000000001: begin
            e_norm = e_sum - 6'd11;
            {m_norm, guard_bit, round_bit} = m_sum[29:18];
            sticky_bit = |m_sum[17:0];
        end
        13'b000000000000: begin
            m_norm = 10'h0;
            guard_bit = 1'b0;
            round_bit = 1'b0;
            sticky_bit = 1'b0;
            e_norm = 6'h0;
        end
    endcase
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 3) Clamp.
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
// 4) RoundTiesToEven.
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
// 5) Handle special cases and obtain final result.
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
    else if (a_e == 5'b11111 || b_e == 5'b11111) begin
        if (a_m != 10'h0 || b_m != 10'h0) begin
            // One of opnds is NaN => NaN.
            res_s = 1'b0;
            res_e = 5'b11111;
            res_m = 10'h77;
        end
        else if (a_m == 10'h0 && b_m == 10'h0) begin
            // Both opnds are inf => inf/0, depending on signs.
            res_s = a_s;
            res_e = (a_s ^ b_s) ? 5'b00000 : 5'b11111;
            res_m = 10'h0;
        end
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
