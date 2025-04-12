module fp16pipeadd (
    input  wire clk,
    input  wire rst_n,

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

wire       f1_a_s = i_a[15];
wire [4:0] f1_a_e = i_a[14:10];
wire [9:0] f1_a_m = (f1_a_e == 5'd0) ? 10'd0 : i_a[9:0]; // Perform DAZ.
wire       f1_b_s = i_b[15];
wire [4:0] f1_b_e = i_b[14:10];
wire [9:0] f1_b_m = (f1_b_e == 5'd0) ? 10'd0 : i_b[9:0]; // Perform DAZ.

///////////////////////////////////////////////////////////////////////////////
// 1.0) Handle special cases.
// a=0                  => res = b
// b=0                  => res = a
// a=NaN || b=NaN       => res = NaN
// a=+-inf && b=+-inf   => res = +-inf
// a=+-inf && b=-+inf   => res = 0
// a=inf && b=normal    => res = inf
///////////////////////////////////////////////////////////////////////////////
reg [15:0] f1_special_res;
reg        f1_is_special;
always @(*) begin
    if (f1_a_e == 5'h0) begin
        // a is zero (DAZ) => res = b.
        f1_special_res = i_b;
        f1_is_special = 1'b1;
    end
    else if (f1_b_e == 5'h0) begin
        // b is zero (DAZ) => res = a.
        f1_special_res = i_a;
        f1_is_special = 1'b1;
    end
    else if ((f1_a_e == 5'b11111 && f1_a_m != 10'h0)
             || (f1_b_e == 5'b11111 && f1_b_m != 10'h0)) begin
        // One of opnds is NaN => NaN.
        f1_special_res = {
            1'b0,
            5'b11111,
            10'h77
        };
        f1_is_special = 1'b1;
    end
    else if ((f1_a_e == 5'b11111 && f1_a_m == 10'h0)
            && (f1_b_e == 5'b11111 && f1_b_m == 10'h0)) begin
        // Both opnds are inf => inf/0, depending on signs.
        f1_special_res = {
            f1_a_s,
            (f1_a_s ^ f1_b_s) ? 5'b00000 : 5'b11111,
            10'h0
        };
        f1_is_special = 1'b1;
    end
    else if (f1_a_e == 5'b11111 && f1_a_m == 10'h0) begin
        // a=inf, b=normal => a.
        f1_special_res = i_a;
        f1_is_special = 1'b1;
    end
    else if (f1_b_e == 5'b11111 && f1_b_m == 10'h0) begin
        // a=normal, b=inf => b.
        f1_special_res = i_b;
        f1_is_special = 1'b1;
    end
    else begin
        // Both opnds are normal.
        f1_special_res = 16'hX;
        f1_is_special = 1'b0;
    end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 1.1) Swap to make |x| > |y|.
///////////////////////////////////////////////////////////////////////////////
wire [5:0] f1_e_diff = {1'b0, f1_a_e} - {1'b0, f1_b_e};
wire f1_need_swap = f1_e_diff[5] || (f1_e_diff == 6'h0 && f1_a_m < f1_b_m);

wire [4:0] f1_e_abs_diff = f1_need_swap ? -f1_e_diff[4:0] : f1_e_diff[4:0];
wire       f1_x_s = f1_need_swap ? f1_b_s : f1_a_s;
wire [4:0] f1_x_e = f1_need_swap ? f1_b_e : f1_a_e;
wire [9:0] f1_x_m = f1_need_swap ? f1_b_m : f1_a_m;
wire       f1_y_s = f1_need_swap ? f1_a_s : f1_b_s;
wire [4:0] f1_y_e = f1_need_swap ? f1_a_e : f1_b_e;
wire [9:0] f1_y_m = f1_need_swap ? f1_a_m : f1_b_m;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 1.2) Sign-magnitude adder.
///////////////////////////////////////////////////////////////////////////////
wire f1_oper = f1_x_s ^ f1_y_s;  // 0 => '+', 1 => '-'

reg [42:0] f1_x_mshifted;
reg [42:0] f1_y_mshifted;
reg [42:0] f1_sum;
reg  [5:0] f1_e_sum;
reg        f1_s_sum;

always @(*) begin
    // x   = 01MMMMMMMMMM00
    // y   = ___________01MMMMMMMMMM
    //       <- shift ->   <|sticky>
    // sum = hhXXXXXXXXXXxx
    //
    // shift can be (0-31).
    f1_x_mshifted = {2'b01, f1_x_m, 31'h0};
    f1_y_mshifted = {2'b01, f1_y_m, 31'h0} >> f1_e_abs_diff;
    f1_sum = (f1_oper)
        ? f1_x_mshifted - f1_y_mshifted
        : f1_x_mshifted + f1_y_mshifted;

    f1_e_sum = {1'b0, f1_x_e};

    f1_s_sum = f1_x_s;
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// F1 to F2 registers.
///////////////////////////////////////////////////////////////////////////////
reg [42:0] f1_f2_sum;
reg  [5:0] f1_f2_e_sum;
reg        f1_f2_s_sum;
reg        f1_f2_is_special;
reg [15:0] f1_f2_special_res;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        f1_f2_sum         <= 43'h0;
        f1_f2_e_sum       <= 6'h0;
        f1_f2_s_sum       <= 1'h0;
        f1_f2_is_special  <= 1'h0;
        f1_f2_special_res <= 16'h0;
    end
    else begin
        f1_f2_sum         <= f1_sum;
        f1_f2_e_sum       <= f1_e_sum;
        f1_f2_s_sum       <= f1_s_sum;
        f1_f2_is_special  <= f1_is_special;
        f1_f2_special_res <= f1_special_res;
    end
end

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 2.1) Normalize.
///////////////////////////////////////////////////////////////////////////////
reg   [3:0] f2_norm_shift;
wire [42:0] f2_norm_sum;

wire [9:0] f2_m_norm;
wire [5:0] f2_e_norm;
wire       f2_guard_bit;
wire       f2_round_bit;
wire       f2_sticky_bit;

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
    casez (f1_f2_sum[42:30])
        13'b1????????????: f2_norm_shift = 4'd01;
        13'b01???????????: f2_norm_shift = 4'd02;
        13'b001??????????: f2_norm_shift = 4'd03;
        13'b0001?????????: f2_norm_shift = 4'd04;
        13'b00001????????: f2_norm_shift = 4'd05;
        13'b000001???????: f2_norm_shift = 4'd06;
        13'b0000001??????: f2_norm_shift = 4'd07;
        13'b00000001?????: f2_norm_shift = 4'd08;
        13'b000000001????: f2_norm_shift = 4'd09;
        13'b0000000001???: f2_norm_shift = 4'd10;
        13'b00000000001??: f2_norm_shift = 4'd11;
        13'b000000000001?: f2_norm_shift = 4'd12;
        13'b0000000000001: f2_norm_shift = 4'd13;
        default          : f2_norm_shift = 4'd14;
    endcase
end

// If leading one is not detected result is zero.
assign f2_e_norm = (f2_norm_shift == 4'd14) ? 6'd0 : f1_f2_e_sum - {2'b0, f2_norm_shift} + 6'd2;
assign f2_norm_sum = f1_f2_sum << f2_norm_shift;

assign {f2_m_norm, f2_guard_bit, f2_round_bit} = f2_norm_sum[42:31];
assign f2_sticky_bit = |f2_norm_sum[30:0];
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 2.2) Clamp.
///////////////////////////////////////////////////////////////////////////////
reg [9:0] f2_m_clamped;
reg [5:0] f2_e_clamped;
reg       f2_is_clamped;
always @(*) begin
    if (f2_e_norm[5]) begin // Exponent underflow => zero.
        f2_m_clamped = 10'h0;
        f2_e_clamped = 6'h0;
        f2_is_clamped = 1'b1;
    end
    else if (f2_e_norm[4:0] == 5'b11111) begin // Exponent "overflow" => inf.
        f2_m_clamped = 10'h0;
        f2_e_clamped = 5'b11111;
        f2_is_clamped = 1'b1;
    end
    else begin
        f2_m_clamped = f2_m_norm;
        f2_e_clamped = f2_e_norm;
        f2_is_clamped = 1'b0;
    end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 2.3) RoundTiesToEven.
///////////////////////////////////////////////////////////////////////////////
reg [9:0] f2_m_round;
reg [4:0] f2_e_round;
always @(*) begin
    if (f2_is_round_up && !f2_is_clamped) begin
        f2_m_round = f2_m_clamped + 10'd1;
        if (f2_m_round == 10'd0) begin
            // Mantissa overflowed, increment exponent.
            f2_e_round = f2_e_clamped[4:0] + 5'd1;
            // if (f2_e_round == 5'b11111) we obtain {S, 1...1, 0} = +-inf, as it should be.
        end
        else begin
            f2_e_round = f2_e_clamped[4:0];
        end
    end
    else begin
        f2_m_round = f2_m_clamped;
        f2_e_round = f2_e_clamped[4:0];
    end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 2.4) Obtain final result.
///////////////////////////////////////////////////////////////////////////////
reg [15:0] f2_res;
assign o_res = f2_res;

always @(*) begin
    if (f1_f2_is_special)
        f2_res = f1_f2_special_res;
    else begin
        // Both opnds are normal.
        f2_res = {
            f1_f2_s_sum,
            f2_e_round,
            (f2_e_round == 5'h0) ? 10'h0 : f2_m_round // Perform FTZ. 
        };
    end
end
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// RoundTiesToEven details.
///////////////////////////////////////////////////////////////////////////////
reg f2_is_round_up;
always @(*) begin
    // RoundTiesToEven scheme.
    casez ({f2_guard_bit, f2_round_bit, f2_sticky_bit})
        3'b0??: begin
            f2_is_round_up = 1'b0;
        end
        3'b100: begin
            // Tie: round up if bit-before-guard is 1, round down otherwise.
            f2_is_round_up = f2_m_norm[0];
        end
        3'b101,
        3'b110,
        3'b111: begin
            f2_is_round_up = 1'b1;
        end
    endcase
end
///////////////////////////////////////////////////////////////////////////////

endmodule
